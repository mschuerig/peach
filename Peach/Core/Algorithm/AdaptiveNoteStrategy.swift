import Foundation
import OSLog

/// Adaptive comparison selection strategy for intelligent training
///
/// Implements NextNoteStrategy with stateless comparison selection:
/// - Reads user's PerceptualProfile for difficulty and weak spots
/// - Uses TrainingSettings for configuration
/// - Uses last completed comparison for nearby note selection
/// - Updates profile difficulty state externally (no internal state)
///
/// # Algorithm Design
///
/// **Note Selection:**
/// - Natural (0.0): Nearby notes (±12 semitones from last comparison)
/// - Mechanical (1.0): Weak spots from profile
/// - Blended: Weighted probability between the two
///
/// **Difficulty Determination:**
/// - Uses per-note currentDifficulty (defaults to 100 cents)
/// - Narrows on correct answer, widens on incorrect
/// - No special cases for jumps or cold start
///
/// # Performance
///
/// Must be fast (< 1ms) to meet NFR2 (no perceptible delay).
/// - In-memory only, no database queries
/// - Simple math: random selection, weighted probability, mean calculation
@MainActor
final class AdaptiveNoteStrategy: NextNoteStrategy {

    // MARK: - Difficulty Parameters

    /// Tunable parameters for adaptive difficulty adjustment
    private enum DifficultyParameters {
        /// Narrowing factor applied per correct answer (5% harder)
        static let narrowingFactor: Double = 0.95

        /// Widening factor applied per incorrect answer (30% easier)
        static let wideningFactor: Double = 1.3

        /// Regional range in semitones (±12 = one octave)
        /// Used for nearby note selection in Natural mode
        static let regionalRange: Int = 12

        /// Default difficulty for untrained regions (100 cents = 1 semitone)
        static let defaultDifficulty: Double = 100.0
    }

    // MARK: - Properties

    /// Logger for algorithm decisions
    private let logger = Logger(subsystem: "com.peach.app", category: "AdaptiveNoteStrategy")

    // MARK: - Initialization

    /// Creates an AdaptiveNoteStrategy
    init() {
        logger.info("AdaptiveNoteStrategy initialized (stateless)")
    }

    // MARK: - NextNoteStrategy Protocol

    /// Selects the next comparison based on perceptual profile and settings
    ///
    /// Stateless selection - updates profile difficulty via setDifficulty() for regional tracking.
    ///
    /// # Algorithm Flow
    ///
    /// 1. Select note using Natural/Mechanical balance
    /// 2. Determine cent difference from profile or default calculation
    /// 3. Return Comparison with note1, note2 (same), centDifference
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration
    ///   - lastComparison: Most recently completed comparison (nil on first)
    /// - Returns: Comparison ready for NotePlayer
    func nextComparison(
        profile: PerceptualProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Comparison {
        // Select note using Natural/Mechanical balance
        let selectedNote = selectNote(
            profile: profile,
            settings: settings,
            lastComparison: lastComparison
        )

        // Determine difficulty from profile (with regional adjustment)
        let centDifference = determineCentDifference(
            for: selectedNote,
            profile: profile,
            settings: settings,
            lastComparison: lastComparison
        )

        logger.info("Selected note=\(selectedNote), centDiff=\(centDifference)")

        return Comparison(
            note1: selectedNote,
            note2: selectedNote,  // Same MIDI note (frequency differs by cents)
            centDifference: centDifference,
            isSecondNoteHigher: Bool.random()  // Randomize direction
        )
    }

    // MARK: - Private Implementation

    /// Selects note using Natural/Mechanical balance
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration
    ///   - lastComparison: Last completed comparison (for nearby selection)
    /// - Returns: Selected MIDI note
    private func selectNote(
        profile: PerceptualProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Int {
        let mechanicalRatio = settings.naturalVsMechanical

        // Weighted random: % chance to pick weak spot vs. nearby
        if Double.random(in: 0...1) < mechanicalRatio {
            // Pick weak spot
            return selectWeakSpot(profile: profile, settings: settings)
        } else {
            // Pick nearby note (if we have a last comparison)
            if let lastNote = lastComparison?.comparison.note1 {
                return selectNearbyNote(around: lastNote, settings: settings)
            } else {
                // First comparison: pick from weak spots
                return selectWeakSpot(profile: profile, settings: settings)
            }
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
    /// - Parameters:
    ///   - note: Center note for nearby selection
    ///   - settings: Training configuration
    /// - Returns: MIDI note near the center note
    private func selectNearbyNote(around note: Int, settings: TrainingSettings) -> Int {
        // Calculate nearby range using regionalRange (±12 semitones = one octave)
        let minNearby = max(settings.noteRangeMin, note - DifficultyParameters.regionalRange)
        let maxNearby = min(settings.noteRangeMax, note + DifficultyParameters.regionalRange)

        // Ensure valid range
        let actualMin = min(minNearby, settings.noteRangeMax)
        let actualMax = max(maxNearby, settings.noteRangeMin)

        let selected = Int.random(in: actualMin...actualMax)
        logger.debug("Selected nearby note: \(selected) (near \(note))")
        return selected
    }

    /// Determines cent difference for a note using per-note difficulty tracking
    ///
    /// Strategy:
    /// - First comparison (nil lastComparison): use current difficulty as-is
    /// - Subsequent comparisons: adjust based on last answer's correctness
    ///   - Correct answer → narrow by narrowingFactor
    ///   - Incorrect answer → widen by wideningFactor
    ///
    /// No special cases for jumps or cold start — per-note currentDifficulty
    /// (defaulting to 100 cents) handles both implicitly.
    ///
    /// - Parameters:
    ///   - note: MIDI note
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration (for difficulty bounds)
    ///   - lastComparison: Most recently completed comparison (nil on first)
    /// - Returns: Cent difference (clamped to min/max)
    private func determineCentDifference(
        for note: Int,
        profile: PerceptualProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Double {
        let stats = profile.statsForNote(note)

        guard let last = lastComparison else {
            return clamp(stats.currentDifficulty,
                         min: settings.minCentDifference,
                         max: settings.maxCentDifference)
        }

        let adjustedDiff = last.isCorrect
            ? max(stats.currentDifficulty * DifficultyParameters.narrowingFactor,
                  settings.minCentDifference)
            : min(stats.currentDifficulty * DifficultyParameters.wideningFactor,
                  settings.maxCentDifference)

        profile.setDifficulty(note: note, difficulty: adjustedDiff)
        logger.debug("Difficulty for note \(note): \(last.isCorrect ? "correct" : "incorrect") → \(adjustedDiff) cents")
        return adjustedDiff
    }

    /// Clamps a value between min and max bounds
    ///
    /// - Parameters:
    ///   - value: Value to clamp
    ///   - min: Minimum bound
    ///   - max: Maximum bound
    /// - Returns: Clamped value
    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }
}
