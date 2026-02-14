import Foundation
import OSLog

/// Adaptive comparison selection strategy for intelligent training
///
/// Implements NextNoteStrategy as a pure, stateless function:
/// - Reads user's PerceptualProfile for difficulty and weak spots
/// - Uses TrainingSettings for configuration
/// - Uses last completed comparison for nearby note selection
/// - No internal state tracking
///
/// # Algorithm Design
///
/// **Note Selection:**
/// - Natural (0.0): Nearby notes (±12 semitones from last comparison)
/// - Mechanical (1.0): Weak spots from profile
/// - Blended: Weighted probability between the two
///
/// **Difficulty Determination:**
/// - Trained note: Use profile's mean detection threshold
/// - Untrained note: Use mean of nearby notes (±6 semitones)
/// - All nearby untrained: Default to 100 cents
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

        /// Regional range in semitones - difficulty persists within this range (±6 = half octave)
        static let regionalRange: Int = 6

        /// Nearby note selection range for Natural mode (±12 = one octave)
        static let nearbySelectionRange: Int = 12

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
    /// This is a pure function with no side effects or internal state.
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
        // Calculate nearby range using nearbySelectionRange (±12 semitones)
        let minNearby = max(settings.noteRangeMin, note - DifficultyParameters.nearbySelectionRange)
        let maxNearby = min(settings.noteRangeMax, note + DifficultyParameters.nearbySelectionRange)

        // Ensure valid range
        let actualMin = min(minNearby, settings.noteRangeMax)
        let actualMax = max(maxNearby, settings.noteRangeMin)

        let selected = Int.random(in: actualMin...actualMax)
        logger.debug("Selected nearby note: \(selected) (near \(note))")
        return selected
    }

    /// Determines cent difference for a note using regional difficulty logic
    ///
    /// Strategy:
    /// 1. If jumping to different region: reset to mean (absolute value)
    /// 2. If staying in same region: adjust based on last result
    ///    - Correct answer → narrow by narrowingFactor
    ///    - Incorrect answer → widen by wideningFactor
    /// 3. For untrained notes: use range mean or default
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

        // Check if we're jumping to a different region
        let isJump = lastComparison == nil ||
                     abs(note - lastComparison!.comparison.note1) > DifficultyParameters.regionalRange

        if isJump {
            // Reset to mean (use absolute value to ignore direction)
            let difficulty: Double
            if stats.isTrained {
                difficulty = abs(stats.mean)
            } else {
                // For untrained notes, calculate mean across entire training range
                difficulty = calculateRangeMean(profile: profile, settings: settings)
            }

            profile.setDifficulty(note: note, difficulty: difficulty)
            let clamped = clamp(difficulty, min: settings.minCentDifference, max: settings.maxCentDifference)
            logger.debug("Jump to note \(note): reset difficulty to \(clamped) cents")
            return clamped
        }

        // Staying in same region - adjust based on last result
        let wasCorrect = lastComparison!.isCorrect
        let currentDiff = stats.currentDifficulty

        let adjustedDiff = wasCorrect
            ? max(currentDiff * DifficultyParameters.narrowingFactor, settings.minCentDifference)
            : min(currentDiff * DifficultyParameters.wideningFactor, settings.maxCentDifference)

        profile.setDifficulty(note: note, difficulty: adjustedDiff)
        logger.debug("Regional adjustment for note \(note): \(wasCorrect ? "correct" : "incorrect") → \(adjustedDiff) cents")
        return adjustedDiff
    }

    /// Calculates mean detection threshold across entire training range
    ///
    /// Used for cold start when a note has no training history.
    /// Scans entire range (not just nearby notes) to get best estimate.
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration (defines range to scan)
    /// - Returns: Mean threshold of trained notes, or default if none trained
    private func calculateRangeMean(profile: PerceptualProfile, settings: TrainingSettings) -> Double {
        var sum = 0.0
        var count = 0

        for note in settings.noteRangeMin...settings.noteRangeMax {
            let stats = profile.statsForNote(note)
            if stats.isTrained {
                sum += abs(stats.mean)  // Use absolute value to ignore direction
                count += 1
            }
        }

        return count > 0 ? sum / Double(count) : DifficultyParameters.defaultDifficulty
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
