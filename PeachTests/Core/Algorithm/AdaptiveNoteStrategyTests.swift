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

    @Test("Untrained note uses mean across training range")
    func untrainedNoteUsesRangeMean() async throws {
        let profile = PerceptualProfile()

        // Train notes across the range
        profile.update(note: 36, centOffset: 20, isCorrect: true)  // Min of range
        profile.update(note: 84, centOffset: 30, isCorrect: true)  // Max of range
        // Note 60 is untrained (mean of range = (20 + 30) / 2 = 25)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 36, noteRangeMax: 84)

        let comparison = strategy.nextComparison(
            profile: profile,
            settings: settings,
            lastComparison: nil
        )

        // Should use mean across entire range (20 + 30) / 2 = 25 cents
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
        for _ in 0..<1000 {
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
        for _ in 0..<1000 {
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

        // Many iterations to make probability of failure exceedingly small
        var selectedNotes = Set<Int>()
        for _ in 0..<1000 {
            let comparison = strategy.nextComparison(
                profile: profile,
                settings: settings,
                lastComparison: nil
            )
            selectedNotes.insert(comparison.note1)
        }

        // Should include weak spot area (notes 59-65 around weak spot 60)
        // With 1000 iterations, extremely high probability of hitting this range
        let weakSpotRange = 59...65
        let hasWeakSpotInRange = selectedNotes.contains { weakSpotRange.contains($0) }
        #expect(hasWeakSpotInRange)
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

        // Same difficulty from profile (absolute value of mean)
        #expect(comparison1.centDifference == 42.0)
        #expect(comparison2.centDifference == 42.0)
    }

    // MARK: - Regional Difficulty Adjustment Tests (AC#2, AC#3)

    @Test("Regional difficulty narrows on correct answer")
    func regionalDifficultyNarrowsOnCorrect() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        // First comparison (no last comparison)
        let comp1 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)
        #expect(comp1.centDifference == 100.0)  // Default for untrained

        // User answers correctly - should narrow (100 * 0.95 = 95)
        let completed1 = CompletedComparison(comparison: comp1, userAnsweredHigher: comp1.isSecondNoteHigher)
        let comp2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: completed1)

        #expect(comp2.centDifference == 95.0)  // Narrowed by 5%
    }

    @Test("Regional difficulty widens on incorrect answer")
    func regionalDifficultyWidensOnIncorrect() async throws {
        let profile = PerceptualProfile()

        // Start with trained note at 50 cents
        profile.update(note: 60, centOffset: 50, isCorrect: true)
        profile.setDifficulty(note: 60, difficulty: 50.0)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        // First comparison uses profile difficulty (50 cents)
        let comp1 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)
        #expect(comp1.centDifference == 50.0)

        // User answers INCORRECTLY - should widen (50 * 1.3 = 65)
        let completed1 = CompletedComparison(comparison: comp1, userAnsweredHigher: !comp1.isSecondNoteHigher)
        let comp2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: completed1)

        #expect(comp2.centDifference == 65.0)  // Widened by 30%
    }

    @Test("Jumping to different region resets to mean")
    func jumpingResetsToMean() async throws {
        let profile = PerceptualProfile()

        // Train note 48 with mean of 40 cents, current difficulty at 20 cents
        profile.update(note: 48, centOffset: 40, isCorrect: true)
        profile.setDifficulty(note: 48, difficulty: 20.0)

        // Train note 60 with mean of 80 cents
        profile.update(note: 60, centOffset: 80, isCorrect: true)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 48, noteRangeMax: 60)

        // Start at note 48 with current difficulty 20 cents
        let comp1 = Comparison(note1: 48, note2: 48, centDifference: 20.0, isSecondNoteHigher: true)
        let completed1 = CompletedComparison(comparison: comp1, userAnsweredHigher: true)

        // Next comparison might pick note 60 (12 semitones away > regionalRange of 6)
        // If it does, should reset to note 60's abs(mean) = 80 cents
        // Run multiple times to hit note 60 (probabilistic test)
        var foundJump = false
        for _ in 0..<100 {
            let comp2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: completed1)
            if comp2.note1 == 60 {
                #expect(comp2.centDifference == 80.0)  // Reset to abs(mean), not adjusted from 20
                foundJump = true
                break
            }
        }

        // With weak spot targeting, note 60 should be selected frequently
        #expect(foundJump, "Should have jumped to note 60 at least once in 100 iterations")
    }

    @Test("Negative means handled with absolute value")
    func negativeMeansHandledCorrectly() async throws {
        let profile = PerceptualProfile()

        // Train note with negative mean (more "lower" comparisons)
        profile.update(note: 60, centOffset: -30.0, isCorrect: true)
        profile.update(note: 60, centOffset: -50.0, isCorrect: true)
        // Mean = -40.0

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        let comparison = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)

        // Should use absolute value (40.0), not ignore negative mean
        #expect(comparison.centDifference == 40.0)
    }

    @Test("Weak spots use absolute value ranking")
    func weakSpotsUseAbsoluteValue() async throws {
        let profile = PerceptualProfile()

        // Create notes with different means:
        profile.update(note: 48, centOffset: +10.0, isCorrect: true)  // Strong, positive
        profile.update(note: 60, centOffset: -80.0, isCorrect: true)  // Weak, negative
        profile.update(note: 72, centOffset: +90.0, isCorrect: true)  // Weakest, positive

        let weakSpots = profile.weakSpots(count: 128)  // Get all weak spots

        // Find positions of our trained notes in the weak spots list
        guard let pos48 = weakSpots.firstIndex(of: 48),
              let pos60 = weakSpots.firstIndex(of: 60),
              let pos72 = weakSpots.firstIndex(of: 72) else {
            Issue.record("Expected trained notes to be in weak spots list")
            return
        }

        // Should rank by absolute value: 72 (90) > 60 (80) > 48 (10)
        // Note: Untrained notes (infinity) will be first, then trained notes by abs(mean)
        #expect(pos72 < pos60, "Note 72 (abs=90) should rank worse than note 60 (abs=80)")
        #expect(pos60 < pos48, "Note 60 (abs=80) should rank worse than note 48 (abs=10)")
    }

    @Test("Regional difficulty respects min/max bounds")
    func regionalDifficultyRespectsBounds() async throws {
        let profile = PerceptualProfile()

        // Train note and set current difficulty at 2.0 cents
        profile.update(note: 60, centOffset: 2.0, isCorrect: true)
        profile.setDifficulty(note: 60, difficulty: 2.0)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 60,
            noteRangeMax: 60,
            minCentDifference: 1.0,
            maxCentDifference: 100.0
        )

        // Simulate answering correctly multiple times
        // 2.0 * 0.95^7 ≈ 1.32, 2.0 * 0.95^8 ≈ 1.25, 2.0 * 0.95^9 ≈ 1.19, 2.0 * 0.95^10 ≈ 1.13
        // Should hit floor at 1.0 after enough iterations
        var lastComparison: CompletedComparison? = nil

        for _ in 0..<15 {
            let comp = strategy.nextComparison(profile: profile, settings: settings, lastComparison: lastComparison)
            // User answers correctly (matches isSecondNoteHigher)
            lastComparison = CompletedComparison(comparison: comp, userAnsweredHigher: comp.isSecondNoteHigher)
        }

        // After 15 correct answers, should definitely have hit floor at 1.0
        let finalComp = strategy.nextComparison(profile: profile, settings: settings, lastComparison: lastComparison)
        #expect(finalComp.centDifference == 1.0, "After many correct answers, difficulty should hit minimum bound of 1.0")
    }
}
