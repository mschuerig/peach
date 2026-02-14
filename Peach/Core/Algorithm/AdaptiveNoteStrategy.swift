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

    // MARK: - Properties

    /// Logger for algorithm decisions
    private let logger = Logger(subsystem: "com.peach.app", category: "AdaptiveNoteStrategy")

    /// Nearby note range in semitones for Natural selection (±12 = one octave)
    private let nearbyRange: Int = 12

    /// Half octave range for calculating default difficulty (±6 semitones)
    private let halfOctaveRange: Int = 6

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

        // Determine difficulty from profile
        let centDifference = determineCentDifference(
            for: selectedNote,
            profile: profile,
            settings: settings
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
        // Calculate nearby range (±12 semitones)
        let minNearby = max(settings.noteRangeMin, note - nearbyRange)
        let maxNearby = min(settings.noteRangeMax, note + nearbyRange)

        // Ensure valid range
        let actualMin = min(minNearby, settings.noteRangeMax)
        let actualMax = max(maxNearby, settings.noteRangeMin)

        let selected = Int.random(in: actualMin...actualMax)
        logger.debug("Selected nearby note: \(selected) (near \(note))")
        return selected
    }

    /// Determines cent difference for a note
    ///
    /// Uses smart fallback strategy:
    /// 1. If trained: use profile's mean threshold
    /// 2. If untrained: use mean of nearby notes (±6 semitones)
    /// 3. If all nearby untrained: use default 100 cents
    ///
    /// - Parameters:
    ///   - note: MIDI note
    ///   - profile: User's perceptual profile
    ///   - settings: Training configuration (for difficulty bounds)
    /// - Returns: Cent difference (clamped to min/max)
    private func determineCentDifference(
        for note: Int,
        profile: PerceptualProfile,
        settings: TrainingSettings
    ) -> Double {
        let stats = profile.statsForNote(note)

        // If trained, use the profile's mean threshold
        if stats.isTrained && stats.mean > 0.0 {
            let difficulty = clamp(
                stats.mean,
                min: settings.minCentDifference,
                max: settings.maxCentDifference
            )
            logger.debug("Using profile difficulty for note \(note): \(difficulty)")
            return difficulty
        }

        // Untrained: calculate mean from nearby notes (±6 semitones)
        let nearbyMean = calculateNearbyMean(around: note, profile: profile)
        if nearbyMean > 0.0 {
            let difficulty = clamp(
                nearbyMean,
                min: settings.minCentDifference,
                max: settings.maxCentDifference
            )
            logger.debug("Using nearby mean for note \(note): \(difficulty)")
            return difficulty
        }

        // All nearby notes untrained: use default 100 cents
        logger.debug("All nearby notes untrained for note \(note), using default 100 cents")
        return 100.0
    }

    /// Calculates mean detection threshold from nearby notes
    ///
    /// - Parameters:
    ///   - note: Center note
    ///   - profile: User's perceptual profile
    /// - Returns: Mean threshold of nearby trained notes, or 0.0 if none trained
    private func calculateNearbyMean(around note: Int, profile: PerceptualProfile) -> Double {
        let minNote = max(0, note - halfOctaveRange)
        let maxNote = min(127, note + halfOctaveRange)

        var sum = 0.0
        var count = 0

        for n in minNote...maxNote {
            let stats = profile.statsForNote(n)
            if stats.isTrained && stats.mean > 0.0 {
                sum += stats.mean
                count += 1
            }
        }

        return count > 0 ? sum / Double(count) : 0.0
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
