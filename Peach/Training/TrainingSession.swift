import Foundation
import Observation
import os
import AVFoundation

/// States in the training comparison loop
enum TrainingState {
    /// Training not started or stopped
    case idle

    /// First note playing, buttons disabled
    case playingNote1

    /// Second note playing, buttons enabled
    case playingNote2

    /// Both notes finished, buttons enabled, waiting for user tap
    case awaitingAnswer

    /// Answer recorded, feedback showing (Story 3.3 will add UI)
    case showingFeedback
}

/// Central orchestrator for the training loop state machine
///
/// # Responsibilities
///
/// TrainingSession coordinates the complete training loop:
/// 1. Generate next comparison (placeholder: random 100 cents until Epic 4)
/// 2. Play note 1 (transition to playingNote1)
/// 3. Play note 2 (transition to playingNote2)
/// 4. Await answer (transition to awaitingAnswer)
/// 5. Record result to TrainingDataStore
/// 6. Show feedback (transition to showingFeedback)
/// 7. Loop immediately to next comparison
///
/// # Error Handling Boundary
///
/// TrainingSession is the error boundary for training. It catches all service errors
/// (audio, data) and handles them gracefully:
/// - **Audio failure**: Stop training silently (transition to idle), log error
/// - **Data failure**: Log error but continue training (one lost record is acceptable)
/// - **The user never sees error states** during training
///
/// # State Transitions
///
/// ```
/// idle
///  ↓ startTraining()
/// playingNote1
///  ↓ note1 completes
/// playingNote2
///  ↓ note2 completes
/// awaitingAnswer
///  ↓ handleAnswer(isHigher:)
/// showingFeedback
///  ↓ feedback duration expires
/// playingNote1 (next comparison)
///  ↓ ...continues loop
/// ```
///
/// # Zero-Delay Looping (NFR2)
///
/// The round-trip between comparisons must be effectively instantaneous (< 100ms target).
/// Implementation strategy: pre-generate next comparison during feedback phase.
@MainActor
@Observable
final class TrainingSession {
    // MARK: - Logger

    private let logger = Logger(subsystem: "com.peach.app", category: "TrainingSession")

    // MARK: - Observable State

    /// Current state of the training loop
    private(set) var state: TrainingState = .idle

    /// Whether to show feedback indicator (Story 3.3)
    private(set) var showFeedback: Bool = false

    /// Result of last answer for feedback display (Story 3.3)
    /// - nil: No feedback to show
    /// - true: Correct answer
    /// - false: Incorrect answer
    private(set) var isLastAnswerCorrect: Bool? = nil

    // MARK: - Dependencies

    /// Audio playback service (protocol-based for testing)
    private let notePlayer: NotePlayer

    /// Observers notified when comparisons are completed (Story 4.1)
    /// Decouples TrainingSession from specific persistence and analytics implementations
    private let observers: [ComparisonObserver]

    // MARK: - Configuration

    /// Note duration in seconds (hardcoded for Story 3.2, configurable in Epic 6)
    private let noteDuration: TimeInterval = 1.0

    /// Amplitude for note playback (0.0-1.0)
    private let amplitude: Double = 0.5

    /// Feedback display duration in seconds (before looping to next comparison)
    private let feedbackDuration: TimeInterval = 0.4

    // MARK: - Training State

    /// Current comparison being trained
    private var currentComparison: Comparison?

    /// Task running the training loop (for cancellation)
    private var trainingTask: Task<Void, Never>?

    /// Task running the feedback delay (for cancellation)
    private var feedbackTask: Task<Void, Never>?

    // MARK: - Audio Interruption Observers (Story 3.4)

    /// Notification observer for audio interruptions (phone calls, etc.)
    private var audioInterruptionObserver: NSObjectProtocol?

    /// Notification observer for audio route changes (headphone disconnect, etc.)
    private var audioRouteChangeObserver: NSObjectProtocol?

    // MARK: - Initialization

    /// Creates a TrainingSession with injected dependencies
    ///
    /// - Parameters:
    ///   - notePlayer: Service for playing audio notes
    ///   - observers: Observers notified when comparisons complete (e.g., dataStore, profile, hapticManager)
    init(notePlayer: NotePlayer, observers: [ComparisonObserver] = []) {
        self.notePlayer = notePlayer
        self.observers = observers

        // Setup audio interruption observers (Story 3.4)
        setupAudioInterruptionObservers()
    }

    isolated deinit {
        // Clean up notification observers
        // Using isolated deinit (Swift 6.1+ SE-0371) to properly handle MainActor cleanup
        if let observer = audioInterruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = audioRouteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public API

    /// Starts the training loop from idle state
    ///
    /// Begins the first comparison immediately with no countdown or loading state.
    /// Training continues in a loop until stopped or an error occurs.
    func startTraining() {
        guard state == .idle else {
            logger.warning("startTraining() called but state is \(String(describing: self.state)), not idle")
            return
        }

        logger.info("Starting training loop")
        trainingTask = Task {
            await runTrainingLoop()
        }
    }

    /// Handles user answer and advances to next comparison
    ///
    /// - Parameter isHigher: True if user answered "higher", false if "lower"
    func handleAnswer(isHigher: Bool) {
        guard state == .awaitingAnswer || state == .playingNote2 else {
            logger.warning("handleAnswer() called but state is \(String(describing: self.state))")
            return
        }
        guard let comparison = currentComparison else {
            logger.error("handleAnswer() called but currentComparison is nil")
            return
        }

        logger.info("User answered: \(isHigher ? "HIGHER" : "LOWER")")

        // If user answered during note2, stop it immediately
        let wasPlayingNote2 = (state == .playingNote2)
        if wasPlayingNote2 {
            logger.info("Stopping note 2 immediately")
            Task {
                try? await notePlayer.stop()
            }
        }

        // Create completed comparison with user's answer
        let completed = CompletedComparison(comparison: comparison, userAnsweredHigher: isHigher)
        logger.info("Answer was \(completed.isCorrect ? "✓ CORRECT" : "✗ WRONG") (second note was \(comparison.isSecondNoteHigher ? "higher" : "lower"))")

        // Notify observers (includes data store, profile, and haptic feedback)
        recordComparison(completed)

        // Set feedback state (Story 3.3)
        isLastAnswerCorrect = completed.isCorrect
        showFeedback = true

        // Transition to feedback state
        state = .showingFeedback
        logger.info("Entering feedback state (duration: \(self.feedbackDuration)s)")

        // After feedback duration, continue loop
        feedbackTask = Task {
            try? await Task.sleep(for: .milliseconds(Int(feedbackDuration * 1000)))
            if state == .showingFeedback && !Task.isCancelled {
                // Clear feedback state before next comparison (Story 3.3)
                showFeedback = false
                logger.info("Feedback complete, starting next comparison")
                await playNextComparison()
            }
        }
    }

    /// Stops the training loop gracefully
    ///
    /// Safe to call multiple times or when training is not active.
    func stop() {
        guard state != .idle else {
            logger.debug("stop() called but already idle")
            return
        }

        logger.info("Training stopped (state was: \(String(describing: self.state)))")

        // Stop audio playback immediately
        Task {
            try? await notePlayer.stop()
            logger.info("NotePlayer stopped")
        }

        // Cancel all running tasks
        trainingTask?.cancel()
        trainingTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil

        // Reset state
        state = .idle
        currentComparison = nil

        // Clear feedback state (Story 3.3)
        showFeedback = false
        isLastAnswerCorrect = nil
    }

    // MARK: - Private Implementation

    /// Main training loop - runs continuously until stopped or error
    private func runTrainingLoop() async {
        logger.info("runTrainingLoop() started")

        // Start first comparison immediately
        await playNextComparison()

        // The loop continues through handleAnswer() -> feedbackTask -> playNextComparison()
        // This Task just needs to stay alive while training is active
        while state != .idle && !Task.isCancelled {
            // Wait for state to change (user answers, error occurs, or stop() is called)
            try? await Task.sleep(for: .milliseconds(100))
        }

        logger.info("runTrainingLoop() ended, state: \(String(describing: self.state))")
    }

    /// Plays a single comparison: note1 → note2 → await answer
    private func playNextComparison() async {
        logger.info("playNextComparison() started")

        // Generate next comparison
        let comparison = Comparison.random()
        currentComparison = comparison
        logger.info("Generated comparison: note1=\(comparison.note1), centDiff=\(comparison.centDifference), higher=\(comparison.isSecondNoteHigher)")

        do {
            // Calculate frequencies
            let freq1 = try comparison.note1Frequency()
            let freq2 = try comparison.note2Frequency()
            logger.info("Frequencies: note1=\(freq1)Hz, note2=\(freq2)Hz")

            // Play note 1
            state = .playingNote1
            logger.info("Playing note 1...")
            try await notePlayer.play(frequency: freq1, duration: noteDuration, amplitude: amplitude)

            // Check if training was stopped during note 1
            guard state != .idle && !Task.isCancelled else {
                logger.info("Training stopped during note 1, aborting comparison")
                return
            }

            // Play note 2
            state = .playingNote2
            logger.info("Playing note 2...")
            try await notePlayer.play(frequency: freq2, duration: noteDuration, amplitude: amplitude)

            // Check if training was stopped during note 2
            guard state != .idle && !Task.isCancelled else {
                logger.info("Training stopped during note 2, aborting comparison")
                return
            }

            // Only transition to awaitingAnswer if user hasn't answered yet
            // (handleAnswer() may have already set state to .showingFeedback)
            if state == .playingNote2 {
                state = .awaitingAnswer
                logger.info("Note 2 finished, awaiting answer")
            } else {
                logger.info("Note 2 finished, but user already answered (state: \(String(describing: self.state)))")
            }
            // User will call handleAnswer() when they tap Higher/Lower (if they haven't already)
        } catch let error as AudioError {
            // Audio error - stop training silently
            logger.error("Audio error, stopping training: \(error.localizedDescription)")
            stop()
        } catch {
            // Unexpected error - stop training
            logger.error("Unexpected error, stopping training: \(error.localizedDescription)")
            stop()
        }
    }

    /// Notifies observers that a comparison was completed
    ///
    /// Observers handle their own error management and don't block training.
    ///
    /// - Parameter completed: The completed comparison with user's answer and result
    private func recordComparison(_ completed: CompletedComparison) {
        // Notify all observers (dataStore, profile, hapticFeedback, etc.)
        // Each observer is responsible for its own error handling
        observers.forEach { observer in
            observer.comparisonCompleted(completed)
        }
    }

    // MARK: - Audio Interruption Handling (Story 3.4)

    /// Sets up observers for audio interruptions and route changes
    private func setupAudioInterruptionObservers() {
        // Observe audio session interruptions (phone calls, Siri, alarms, etc.)
        audioInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            // Extract notification data synchronously before crossing actor boundary
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleAudioInterruption(typeValue: typeValue)
            }
        }

        // Observe audio route changes (headphone disconnect, etc.)
        audioRouteChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            // Extract notification data synchronously before crossing actor boundary
            let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleAudioRouteChange(reasonValue: reasonValue)
            }
        }

        logger.info("Audio interruption observers setup complete")
    }

    /// Handles audio session interruption notifications (phone calls, Siri, etc.)
    private func handleAudioInterruption(typeValue: UInt?) {
        guard let typeValue = typeValue,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            logger.warning("Audio interruption notification received but could not parse type")
            return
        }

        switch type {
        case .began:
            // Interruption began (phone call started, Siri activated, etc.)
            logger.info("Audio interruption began - stopping training")
            stop()

        case .ended:
            // Interruption ended (phone call ended, Siri dismissed, etc.)
            logger.info("Audio interruption ended - training remains stopped")
            // Note: We do NOT auto-restart training - user must explicitly start again
            // This follows the "instant stop, no auto-resume" UX principle

        @unknown default:
            logger.warning("Unknown audio interruption type: \(typeValue)")
        }
    }

    /// Handles audio route change notifications (headphone disconnect, Bluetooth changes, etc.)
    private func handleAudioRouteChange(reasonValue: UInt?) {
        guard let reasonValue = reasonValue,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            logger.warning("Audio route change notification received but could not parse reason")
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // Audio route removed (headphones unplugged, Bluetooth disconnected)
            logger.info("Audio device disconnected (headphones/Bluetooth) - stopping training")
            stop()

        case .newDeviceAvailable, .categoryChange, .override, .wakeFromSleep, .noSuitableRouteForCategory, .routeConfigurationChange, .unknown:
            // Other route changes - log but don't stop training
            logger.info("Audio route changed (reason: \(reason.rawValue)) - continuing training")

        @unknown default:
            logger.warning("Unknown audio route change reason: \(reasonValue)")
        }
    }
}
