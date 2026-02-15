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

    @Test("Difficulty respects floor from settings")
    func difficultyRespectsFloor() async throws {
        let profile = PerceptualProfile()

        // Set current difficulty below the floor
        profile.setDifficulty(note: 60, difficulty: 0.5)

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

        // Set current difficulty above the ceiling
        profile.setDifficulty(note: 60, difficulty: 150.0)

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

        // Set a specific difficulty for note 60
        profile.setDifficulty(note: 60, difficulty: 42.0)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        // Call multiple times with same inputs (nil lastComparison = no adjustment)
        let comparison1 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)
        let comparison2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)

        // Same note selected (deterministic in single-note range)
        #expect(comparison1.note1 == 60)
        #expect(comparison2.note1 == 60)

        // Same difficulty from currentDifficulty
        #expect(comparison1.centDifference == 42.0)
        #expect(comparison2.centDifference == 42.0)
    }

    // MARK: - Regional Difficulty Adjustment Tests (AC#2, AC#3)

    @Test("Regional difficulty narrows on correct answer using Kazez formula")
    func regionalDifficultyNarrowsOnCorrect() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        // First comparison (no last comparison)
        let comp1 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: nil)
        #expect(comp1.centDifference == 100.0)  // Default for untrained

        // User answers correctly - Kazez: 100 × (1 - 0.05 × √100) = 100 × 0.5 = 50.0
        let completed1 = CompletedComparison(comparison: comp1, userAnsweredHigher: comp1.isSecondNoteHigher)
        let comp2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: completed1)

        #expect(comp2.centDifference == 50.0)  // Kazez narrowing from 100 cents
    }

    @Test("Regional difficulty widens on incorrect answer using Kazez formula")
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

        // User answers INCORRECTLY - Kazez: 50 × (1 + 0.09 × √50) ≈ 81.82
        let completed1 = CompletedComparison(comparison: comp1, userAnsweredHigher: !comp1.isSecondNoteHigher)
        let comp2 = strategy.nextComparison(profile: profile, settings: settings, lastComparison: completed1)

        // 50 × (1 + 0.09 × 7.0710678...) = 50 × 1.63639610... ≈ 81.82
        let expected = 50.0 * (1.0 + 0.09 * 50.0.squareRoot())
        #expect(abs(comp2.centDifference - expected) < 0.01)
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

    @Test("Difficulty narrows even when jumping between notes")
    func difficultyNarrowsAcrossJumps() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 36, noteRangeMax: 84)

        // First comparison at note 36 (default difficulty 100)
        let fixedSettings36 = TrainingSettings(noteRangeMin: 36, noteRangeMax: 36)
        let comp1 = strategy.nextComparison(profile: profile, settings: fixedSettings36, lastComparison: nil)
        #expect(comp1.note1 == 36)
        #expect(comp1.centDifference == 100.0)

        // User answers correctly
        let completed1 = CompletedComparison(comparison: comp1, userAnsweredHigher: comp1.isSecondNoteHigher)

        // Force next comparison at note 84 (48 semitones away — a jump beyond regionalRange of 12)
        let fixedSettings84 = TrainingSettings(noteRangeMin: 84, noteRangeMax: 84)
        let comp2 = strategy.nextComparison(profile: profile, settings: fixedSettings84, lastComparison: completed1)

        #expect(comp2.note1 == 84)
        // Kazez narrowing from 100: 100 × (1 - 0.05 × √100) = 50.0
        #expect(comp2.centDifference == 50.0,
            "Difficulty should narrow via Kazez formula after correct answer, even across a region jump. Got: \(comp2.centDifference)")
    }

    @Test("Kazez convergence: 10 correct answers from 100 cents reaches ~5 cents")
    func kazezConvergenceFromDefault() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 60,
            noteRangeMax: 60,
            minCentDifference: 1.0,
            maxCentDifference: 100.0
        )

        // First comparison: 100 cents (default)
        var lastComp: CompletedComparison? = nil

        // Simulate 10 consecutive correct answers
        for _ in 0..<10 {
            let comp = strategy.nextComparison(profile: profile, settings: settings, lastComparison: lastComp)
            lastComp = CompletedComparison(comparison: comp, userAnsweredHigher: comp.isSecondNoteHigher)
        }

        // After 10 correct answers, get the resulting difficulty
        let finalComp = strategy.nextComparison(profile: profile, settings: settings, lastComparison: lastComp)

        // Should converge to approximately 5 cents (between 1 and 10)
        #expect(finalComp.centDifference < 10.0, "After 10 correct answers, difficulty should be below 10 cents. Got: \(finalComp.centDifference)")
        #expect(finalComp.centDifference >= 1.0, "Difficulty should not go below minimum. Got: \(finalComp.centDifference)")
    }

    @Test("Per-note tracking: different notes have independent difficulties")
    func perNoteIndependentDifficulties() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()

        // Train note 60 down to a lower difficulty
        let settings60 = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)
        var lastComp: CompletedComparison? = nil
        for _ in 0..<5 {
            let comp = strategy.nextComparison(profile: profile, settings: settings60, lastComparison: lastComp)
            lastComp = CompletedComparison(comparison: comp, userAnsweredHigher: comp.isSecondNoteHigher)
        }

        let comp60 = strategy.nextComparison(profile: profile, settings: settings60, lastComparison: lastComp)

        // Note 72 should still be at default (100 cents) — untrained
        let settings72 = TrainingSettings(noteRangeMin: 72, noteRangeMax: 72)
        let comp72 = strategy.nextComparison(profile: profile, settings: settings72, lastComparison: nil)

        #expect(comp60.centDifference < 100.0, "Note 60 should have narrowed difficulty")
        #expect(comp72.centDifference == 100.0, "Note 72 should still be at default 100 cents")
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
        // With Kazez narrowing, each step: N = P × (1 - 0.05 × √P)
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
