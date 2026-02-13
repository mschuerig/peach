import Foundation
import Observation
import os

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

    // MARK: - Dependencies

    /// Audio playback service (protocol-based for testing)
    private let notePlayer: NotePlayer

    /// Data persistence service (protocol-based for testing)
    private let dataStore: ComparisonRecordStoring

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

    // MARK: - Initialization

    /// Creates a TrainingSession with injected dependencies
    ///
    /// - Parameters:
    ///   - notePlayer: Service for playing audio notes
    ///   - dataStore: Service for persisting comparison records
    init(notePlayer: NotePlayer, dataStore: ComparisonRecordStoring) {
        self.notePlayer = notePlayer
        self.dataStore = dataStore
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

        // Record the result
        let isCorrect = comparison.isCorrect(userAnswerHigher: isHigher)
        logger.info("Answer was \(isCorrect ? "✓ CORRECT" : "✗ WRONG") (second note was \(comparison.isSecondNoteHigher ? "higher" : "lower"))")

        recordComparison(comparison, isCorrect: isCorrect)

        // Transition to feedback state
        state = .showingFeedback
        logger.info("Entering feedback state (duration: \(self.feedbackDuration)s)")

        // After feedback duration, continue loop
        feedbackTask = Task {
            try? await Task.sleep(for: .milliseconds(Int(feedbackDuration * 1000)))
            if state == .showingFeedback && !Task.isCancelled {
                logger.info("Feedback complete, starting next comparison")
                await playNextComparison()
            }
        }
    }

    /// Stops the training loop gracefully
    ///
    /// Safe to call multiple times or when training is not active.
    func stop() {
        guard state != .idle else { return }

        trainingTask?.cancel()
        trainingTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil
        state = .idle
        currentComparison = nil
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

            // Play note 2
            state = .playingNote2
            logger.info("Playing note 2...")
            try await notePlayer.play(frequency: freq2, duration: noteDuration, amplitude: amplitude)

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

    /// Records a comparison result to persistent storage
    ///
    /// Data errors are logged but don't stop training (one lost record is acceptable).
    ///
    /// - Parameters:
    ///   - comparison: The comparison that was answered
    ///   - isCorrect: Whether the user answered correctly
    private func recordComparison(_ comparison: Comparison, isCorrect: Bool) {
        let record = ComparisonRecord(
            note1: comparison.note1,
            note2: comparison.note2,
            note2CentOffset: comparison.isSecondNoteHigher ? comparison.centDifference : -comparison.centDifference,
            isCorrect: isCorrect
        )

        do {
            try dataStore.save(record)
        } catch let error as DataStoreError {
            // Data error - log but continue training
            logger.warning("Data save error (continuing): \(error.localizedDescription)")
        } catch {
            // Unexpected error - log but continue
            logger.warning("Unexpected save error (continuing): \(error.localizedDescription)")
        }
    }
}
