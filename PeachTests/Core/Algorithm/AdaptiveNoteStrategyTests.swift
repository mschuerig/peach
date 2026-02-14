import Testing
import Foundation
@testable import Peach

/// Comprehensive test suite for AdaptiveNoteStrategy
/// Tests stateless comparison selection with smart difficulty fallback
@Suite("AdaptiveNoteStrategy Tests")
@MainActor
struct AdaptiveNoteStrategyTests {

    // MARK: - Task 1 Tests: NextNoteStrategy Protocol

    @Test("NextNoteStrategy protocol returns Comparison")
    func protocolReturnsComparison() async throws {
        let profile = PerceptualProfile()
        let settings = TrainingSettings()
        let strategy = AdaptiveNoteStrategy()

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Verify comparison structure
        #expect(comparison.note1 >= 0 && comparison.note1 <= 127)
        #expect(comparison.note2 >= 0 && comparison.note2 <= 127)
        #expect(comparison.centDifference > 0)
    }

    // MARK: - Difficulty Determination Tests

    @Test("Untrained note with no nearby data uses 100 cent default")
    func untrainedNoteUsesDefault() async throws {
        let profile = PerceptualProfile()  // Empty profile
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // All nearby notes untrained → use 100 cents
        #expect(comparison.note1 == 60)
        #expect(comparison.centDifference == 100.0)
    }

    @Test("Trained note uses profile mean threshold")
    func trainedNoteUsesProfileMean() async throws {
        let profile = PerceptualProfile()

        // Train note 60 with 25 cent threshold
        profile.update(note: 60, centOffset: 25, isCorrect: true)
        profile.update(note: 60, centOffset: 25, isCorrect: true)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Should use profile's mean (25 cents)
        #expect(comparison.note1 == 60)
        #expect(comparison.centDifference == 25.0)
    }

    @Test("Untrained note uses mean of nearby trained notes")
    func untrainedNoteUsesNearbyMean() async throws {
        let profile = PerceptualProfile()

        // Train notes around 60 (within ±6 semitones: 54-66)
        profile.update(note: 54, centOffset: 20, isCorrect: true)  // 6 semitones below
        profile.update(note: 66, centOffset: 30, isCorrect: true)  // 6 semitones above
        // Note 60 is untrained

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Should use mean of nearby (20 + 30) / 2 = 25 cents
        #expect(comparison.note1 == 60)
        #expect(comparison.centDifference == 25.0)
    }

    @Test("Difficulty respects floor from settings")
    func difficultyRespectsFloor() async throws {
        let profile = PerceptualProfile()

        // Train note with very low threshold (below default floor)
        profile.update(note: 60, centOffset: 0.5, isCorrect: true)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 60,
            noteRangeMax: 60,
            minCentDifference: 1.0
        )

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Should clamp to floor (1.0)
        #expect(comparison.centDifference == 1.0)
    }

    @Test("Difficulty respects ceiling from settings")
    func difficultyRespectsCeiling() async throws {
        let profile = PerceptualProfile()

        // Train note with very high threshold (above default ceiling)
        profile.update(note: 60, centOffset: 150, isCorrect: true)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 60,
            noteRangeMax: 60,
            maxCentDifference: 100.0
        )

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Should clamp to ceiling (100.0)
        #expect(comparison.centDifference == 100.0)
    }

    // MARK: - Weak Spot Targeting Tests

    @Test("Mechanical ratio 1.0 targets weak spots")
    func mechanicalRatioTargetsWeakSpots() async throws {
        let profile = PerceptualProfile()

        // Train some notes to create weak spots
        profile.update(note: 48, centOffset: 10, isCorrect: true)  // Strong (low threshold)
        profile.update(note: 60, centOffset: 80, isCorrect: true)  // Weak (high threshold)
        profile.update(note: 62, centOffset: 85, isCorrect: true)  // Weak (high threshold)
        profile.update(note: 64, centOffset: 90, isCorrect: true)  // Weak (highest threshold)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 36,
            noteRangeMax: 84,
            naturalVsMechanical: 1.0  // 100% weak spots
        )

        // Test multiple selections - should all be from weak spots
        var selectedNotes = Set<Int>()
        for _ in 0..<20 {
            let comparison = strategy.nextComparison(
                profile: profile,
                settings: settings,
                lastComparison: nil
            )
            selectedNotes.insert(comparison.note1)
        }

        // Should pick from weak spots (60, 62, 64) not strong note (48)
        let weakSpotSelections = selectedNotes.intersection([60, 62, 64])
        #expect(weakSpotSelections.count >= 1)  // At least one weak spot selected
    }

    @Test("Natural ratio 0.0 targets nearby notes when last comparison provided")
    func naturalRatioTargetsNearbyNotes() async throws {
        let profile = PerceptualProfile()

        // Train all notes to avoid default behavior
        for note in 0..<128 {
            profile.update(note: note, centOffset: 50, isCorrect: true)
        }

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 36,
            noteRangeMax: 84,
            naturalVsMechanical: 0.0  // 100% nearby
        )

        // Create a last comparison centered at note 48
        let lastComparison = CompletedComparison(
            comparison: Comparison(note1: 48, note2: 48, centDifference: 50, isSecondNoteHigher: true),
            userAnsweredHigher: true
        )

        // Test multiple selections - should be near note 48 (±12 semitones = 36-60)
        var selectedNotes = Set<Int>()
        for _ in 0..<20 {
            let comparison = strategy.nextComparison(
                profile: profile,
                settings: settings,
                lastComparison: lastComparison
            )
            selectedNotes.insert(comparison.note1)
        }

        // Most selections should be nearby (36-60, since 48±12 = 36-60)
        let nearbyRange = 36...60
        let nearbySelections = selectedNotes.filter { nearbyRange.contains($0) }
        #expect(nearbySelections.count >= 1)  // At least some nearby selections
    }

    @Test("First comparison (nil lastComparison) picks from weak spots")
    func firstComparisonPicksWeakSpots() async throws {
        let profile = PerceptualProfile()

        // Train some notes to create distinct weak spots
        profile.update(note: 48, centOffset: 10, isCorrect: true)  // Strong
        profile.update(note: 60, centOffset: 90, isCorrect: true)  // Weak

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 36,
            noteRangeMax: 84,
            naturalVsMechanical: 0.0  // Even with Natural, first comparison picks weak spots
        )

        // Multiple calls with nil lastComparison
        var selectedNotes = Set<Int>()
        for _ in 0..<10 {
            let comparison = strategy.nextComparison(
                profile: profile,
                settings: settings,
                lastComparison: nil
            )
            selectedNotes.insert(comparison.note1)
        }

        // Should include weak spot more than strong note
        #expect(selectedNotes.contains(60))  // Weak spot should appear
    }

    // MARK: - Note Range Filtering Tests

    @Test("Note range filtering works correctly")
    func noteRangeFiltering() async throws {
        let profile = PerceptualProfile()

        // Create weak spots across full range
        for note in [30, 60, 90] {
            profile.update(note: note, centOffset: 80, isCorrect: true)
        }

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 48,
            noteRangeMax: 72,
            naturalVsMechanical: 1.0  // Target weak spots
        )

        // All comparisons should be within range
        for _ in 0..<20 {
            let comparison = strategy.nextComparison(
                profile: profile,
                settings: settings,
                lastComparison: nil
            )
            #expect(comparison.note1 >= 48)
            #expect(comparison.note1 <= 72)
        }
    }

    @Test("Single note range works without crashing")
    func singleNoteRange() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        #expect(comparison.note1 == 60)  // Only possible note
        #expect(comparison.note2 == 60)
    }

    // MARK: - Comparison Structure Tests

    @Test("nextComparison returns valid Comparison struct")
    func nextComparisonReturnsValidComparison() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings()

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Validate Comparison structure
        #expect(comparison.note1 >= 0 && comparison.note1 <= 127)
        #expect(comparison.note2 == comparison.note1)  // Same MIDI note (frequency differs by cents)
        #expect(comparison.centDifference > 0)
        #expect(comparison.centDifference <= 100.0)
    }

    @Test("Stateless strategy produces consistent results with same inputs")
    func statelessStrategyConsistency() async throws {
        let profile = PerceptualProfile()

        // Train a specific note
        profile.update(note: 60, centOffset: 42, isCorrect: true)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        // Call multiple times with same inputs
        let comparison1 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)
        let comparison2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)

        // Same note selected (deterministic in single-note range)
        #expect(comparison1.note1 == 60)
        #expect(comparison2.note1 == 60)

        // Same difficulty from profile
        #expect(comparison1.centDifference == 42.0)
        #expect(comparison2.centDifference == 42.0)
    }
}
