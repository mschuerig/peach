import Foundation
import OSLog

/// Adaptive comparison selection strategy for intelligent training
///
/// Implements NextNoteStrategy with:
/// - Cold start handling (random selection at 100 cents for new users)
/// - Difficulty adjustment (narrower on correct, wider on incorrect)
/// - Weak spot targeting (prioritizes notes with poor discrimination)
/// - Natural/Mechanical balance (nearby notes vs. weak spots)
/// - Fractional cent precision with 1-cent floor
///
/// # Algorithm Design
///
/// **Cold Start:** All untrained → random note at 100 cents
/// **Trained:** Balances between:
/// - Natural (0.0): Nearby notes (±12 semitones from last)
/// - Mechanical (1.0): Weak spots from profile
///
/// **Difficulty Adjustment:**
/// - Correct: multiply by 0.8 (harder, minimum 1.0 cent)
/// - Incorrect: multiply by 1.3 (easier, maximum 100.0 cents)
///
/// # Performance
///
/// Must be fast (< 1ms) to meet NFR2 (no perceptible delay).
/// - In-memory only, no database queries
/// - Simple math: random selection, weighted probability, multiplication
@MainActor
final class AdaptiveNoteStrategy: NextNoteStrategy {

    // MARK: - Properties

    /// Logger for algorithm decisions
    private let logger = Logger(subsystem: "com.peach.app", category: "AdaptiveNoteStrategy")

    /// Per-note difficulty state (MIDI note -> current cent threshold)
    /// Tracks ephemeral session difficulty separate from profile's long-term statistics
    private var difficultyState: [Int: Double] = [:]

    /// Last selected note for nearby note selection
    private var lastSelectedNote: Int = 60  // Default: Middle C

    // MARK: - Algorithm Parameters

    /// Difficulty narrowing factor on correct answer (multiply by this)
    private let narrowingFactor: Double = 0.8

    /// Difficulty widening factor on incorrect answer (multiply by this)
    private let wideningFactor: Double = 1.3

    /// Minimum cent difficulty (practical floor for human pitch discrimination)
    private let minCentDifference: Double = 1.0

    /// Maximum cent difficulty (ceiling to prevent excessive widening)
    private let maxCentDifference: Double = 100.0

    /// Nearby note range in semitones (±12 = one octave)
    private let nearbyRange: Int = 12

    // MARK: - Initialization

    /// Creates an AdaptiveNoteStrategy with default algorithm parameters
    init() {
        logger.info("AdaptiveNoteStrategy initialized")
    }

    // MARK: - NextNoteStrategy Protocol

    /// Selects the next comparison based on perceptual profile and settings
    ///
    /// # Algorithm Flow
    ///
    /// 1. Check cold start (all notes untrained) → random at 100 cents
    /// 2. If trained → apply Natural/Mechanical balance
    /// 3. Select note (weak spot or nearby based on ratio)
    /// 4. Determine cent difference (from difficulty state or profile)
    /// 5. Return Comparison with note1, note2 (same), centDifference
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration
    /// - Returns: Comparison ready for NotePlayer
    func nextComparison(profile: PerceptualProfile, settings: TrainingSettings) -> Comparison {
        // Cold start detection: all notes untrained
        if isColdStart(profile: profile) {
            return coldStartComparison(settings: settings)
        }

        // Trained: apply Natural/Mechanical selection
        let selectedNote = selectNote(profile: profile, settings: settings)
        let centDifference = determineCentDifference(for: selectedNote, profile: profile)

        logger.info("Selected note=\(selectedNote), centDiff=\(centDifference)")

        // Update tracking state
        lastSelectedNote = selectedNote

        return Comparison(
            note1: selectedNote,
            note2: selectedNote,  // Same MIDI note (frequency differs by cents)
            centDifference: centDifference,
            isSecondNoteHigher: Bool.random()  // Randomize direction
        )
    }

    // MARK: - Difficulty Management

    /// Returns current difficulty for a note
    ///
    /// - Parameter note: MIDI note (0-127)
    /// - Returns: Current cent threshold (defaults to 100.0 if untrained)
    func currentDifficulty(for note: Int) -> Double {
        return difficultyState[note] ?? maxCentDifference
    }

    /// Updates difficulty based on answer correctness
    ///
    /// - Parameters:
    ///   - note: MIDI note (0-127)
    ///   - wasCorrect: Whether user answered correctly
    func updateDifficulty(for note: Int, wasCorrect: Bool) {
        let current = currentDifficulty(for: note)

        let newDifficulty: Double
        if wasCorrect {
            // Make harder: narrow the difference
            newDifficulty = max(current * narrowingFactor, minCentDifference)
            logger.debug("Narrowing difficulty for note \(note): \(current) → \(newDifficulty)")
        } else {
            // Make easier: widen the difference
            newDifficulty = min(current * wideningFactor, maxCentDifference)
            logger.debug("Widening difficulty for note \(note): \(current) → \(newDifficulty)")
        }

        difficultyState[note] = newDifficulty
    }

    /// Sets difficulty for a note (used by tests)
    ///
    /// - Parameters:
    ///   - note: MIDI note (0-127)
    ///   - difficulty: Cent threshold
    func setDifficulty(for note: Int, to difficulty: Double) {
        difficultyState[note] = difficulty
    }

    /// Sets last selected note (used by tests)
    ///
    /// - Parameter note: MIDI note (0-127)
    func setLastSelectedNote(_ note: Int) {
        lastSelectedNote = note
    }

    // MARK: - Private Implementation

    /// Checks if profile is in cold start state (all notes untrained)
    ///
    /// - Parameter profile: User's perceptual profile
    /// - Returns: True if no notes have been trained
    private func isColdStart(profile: PerceptualProfile) -> Bool {
        // Check if any note has training data
        for midiNote in 0..<128 {
            let stats = profile.statsForNote(midiNote)
            if stats.isTrained {
                return false  // At least one trained note exists
            }
        }
        return true  // All notes untrained
    }

    /// Generates cold start comparison (random note at 100 cents)
    ///
    /// - Parameter settings: Training configuration
    /// - Returns: Random comparison within range at 100 cents
    private func coldStartComparison(settings: TrainingSettings) -> Comparison {
        let randomNote = Int.random(in: settings.noteRangeMin...settings.noteRangeMax)

        logger.info("Cold start: random note=\(randomNote), centDiff=100.0")

        return Comparison(
            note1: randomNote,
            note2: randomNote,
            centDifference: maxCentDifference,  // 100 cents
            isSecondNoteHigher: Bool.random()
        )
    }

    /// Selects note using Natural/Mechanical balance
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration
    /// - Returns: Selected MIDI note
    private func selectNote(profile: PerceptualProfile, settings: TrainingSettings) -> Int {
        let mechanicalRatio = settings.naturalVsMechanical

        // Weighted random: % chance to pick weak spot vs. nearby
        if Double.random(in: 0...1) < mechanicalRatio {
            // Pick weak spot
            return selectWeakSpot(profile: profile, settings: settings)
        } else {
            // Pick nearby note
            return selectNearbyNote(settings: settings)
        }
    }

    /// Selects a weak spot from profile within range
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration
    /// - Returns: MIDI note from weak spots, or random note if no weak spots in range
    private func selectWeakSpot(profile: PerceptualProfile, settings: TrainingSettings) -> Int {
        let weakSpots = profile.weakSpots(count: 10)
        let filtered = weakSpots.filter { settings.isInRange($0) }

        if let selected = filtered.randomElement() {
            logger.debug("Selected weak spot: \(selected)")
            return selected
        } else {
            // No weak spots in range, fall back to random within range
            logger.debug("No weak spots in range, using random selection")
            return Int.random(in: settings.noteRangeMin...settings.noteRangeMax)
        }
    }

    /// Selects a nearby note within range
    ///
    /// - Parameter settings: Training configuration
    /// - Returns: MIDI note near lastSelectedNote
    private func selectNearbyNote(settings: TrainingSettings) -> Int {
        // Calculate nearby range (±12 semitones)
        let minNearby = max(settings.noteRangeMin, self.lastSelectedNote - nearbyRange)
        let maxNearby = min(settings.noteRangeMax, self.lastSelectedNote + nearbyRange)

        // Ensure valid range
        let actualMin = min(minNearby, settings.noteRangeMax)
        let actualMax = max(maxNearby, settings.noteRangeMin)

        let selected = Int.random(in: actualMin...actualMax)
        logger.debug("Selected nearby note: \(selected) (near \(self.lastSelectedNote))")
        return selected
    }

    /// Determines cent difference for a note
    ///
    /// Uses difficulty state if available, otherwise falls back to profile statistics
    ///
    /// - Parameters:
    ///   - note: MIDI note
    ///   - profile: User's perceptual profile
    /// - Returns: Cent difference (clamped to min/max)
    private func determineCentDifference(for note: Int, profile: PerceptualProfile) -> Double {
        // Check if we have session difficulty state
        if let sessionDifficulty = difficultyState[note] {
            return sessionDifficulty
        }

        // Fall back to profile statistics
        let stats = profile.statsForNote(note)
        if stats.isTrained {
            // Use profile's mean threshold as starting difficulty
            let profileDifficulty = max(minCentDifference, min(stats.mean, maxCentDifference))
            logger.debug("Using profile difficulty for note \(note): \(profileDifficulty)")
            return profileDifficulty
        } else {
            // Untrained note: use maximum difficulty
            return maxCentDifference
        }
    }
}
