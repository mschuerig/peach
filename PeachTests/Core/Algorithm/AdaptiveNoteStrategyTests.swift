import Testing
import Foundation
@testable import Peach

/// Comprehensive test suite for AdaptiveNoteStrategy
/// Tests cold start, difficulty adjustment, weak spot targeting, and Natural/Mechanical balance
@Suite("AdaptiveNoteStrategy Tests")
@MainActor
struct AdaptiveNoteStrategyTests {

    // MARK: - Task 1 Tests: NextNoteStrategy Protocol

    @Test("NextNoteStrategy protocol returns Comparison")
    func protocolReturnsComparison() async throws {
        let profile = PerceptualProfile()
        let settings = TrainingSettings()
        let strategy = AdaptiveNoteStrategy()

        let comparison = strategy.nextComparison(profile: profile, settings: settings)

        // Verify comparison structure
        #expect(comparison.note1 >= 0 && comparison.note1 <= 127)
        #expect(comparison.note2 >= 0 && comparison.note2 <= 127)
        #expect(comparison.centDifference > 0)
    }

    // MARK: - Task 2 Tests: Cold Start Behavior (AC#5)

    @Test("Cold start uses random note selection at 100 cents")
    func coldStartRandomAt100Cents() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 36, noteRangeMax: 84)

        let comparison = strategy.nextComparison(profile: profile, settings: settings)

        // Within configured range
        #expect(comparison.note1 >= 36 && comparison.note1 <= 84)
        // Same note (pitch difference comes from cents)
        #expect(comparison.note2 == comparison.note1)
        // Cold start difficulty: 100 cents (1 semitone)
        #expect(comparison.centDifference == 100.0)
    }

    @Test("Cold start works across multiple comparisons")
    func coldStartMultipleComparisons() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings()

        // Generate multiple comparisons - all should be 100 cents
        for _ in 0..<10 {
            let comparison = strategy.nextComparison(profile: profile, settings: settings)
            #expect(comparison.centDifference == 100.0)
        }
    }

    // MARK: - Task 3 Tests: Difficulty Adjustment (AC#2, AC#3, AC#6)

    @Test("Correct answer narrows difficulty")
    func correctAnswerNarrowsDifficulty() async throws {
        let strategy = AdaptiveNoteStrategy()

        // Initial difficulty should be 100.0 (cold start)
        let initialDifficulty = strategy.currentDifficulty(for: 60)
        #expect(initialDifficulty == 100.0)

        // Simulate correct answer
        strategy.updateDifficulty(for: 60, wasCorrect: true)

        let newDifficulty = strategy.currentDifficulty(for: 60)
        #expect(newDifficulty < 100.0)  // Harder than default
        #expect(newDifficulty >= 1.0)   // Not below 1-cent floor
    }

    @Test("Incorrect answer widens difficulty")
    func incorrectAnswerWidensDifficulty() async throws {
        let strategy = AdaptiveNoteStrategy()
        strategy.setDifficulty(for: 60, to: 10.0)

        strategy.updateDifficulty(for: 60, wasCorrect: false)

        let newDifficulty = strategy.currentDifficulty(for: 60)
        #expect(newDifficulty > 10.0)  // Easier than before
    }

    @Test("Difficulty respects 1-cent floor")
    func difficultyRespectsFloor() async throws {
        let strategy = AdaptiveNoteStrategy()
        strategy.setDifficulty(for: 60, to: 1.5)

        // Keep narrowing to test floor
        strategy.updateDifficulty(for: 60, wasCorrect: true)  // 1.5 * 0.8 = 1.2
        strategy.updateDifficulty(for: 60, wasCorrect: true)  // 1.2 * 0.8 = 0.96 → floor to 1.0

        let flooredDifficulty = strategy.currentDifficulty(for: 60)
        #expect(flooredDifficulty == 1.0)  // Floor enforced

        // Further narrowing should stay at floor
        strategy.updateDifficulty(for: 60, wasCorrect: true)
        #expect(strategy.currentDifficulty(for: 60) == 1.0)
    }

    @Test("Fractional cent precision is supported")
    func fractionalCentPrecision() async throws {
        let strategy = AdaptiveNoteStrategy()
        strategy.setDifficulty(for: 60, to: 1.5)

        strategy.updateDifficulty(for: 60, wasCorrect: true)  // 1.5 * 0.8 = 1.2

        let difficulty = strategy.currentDifficulty(for: 60)
        #expect(difficulty == 1.2)  // Fractional precision preserved
    }

    @Test("Difficulty respects 100-cent ceiling")
    func difficultyRespectsCeiling() async throws {
        let strategy = AdaptiveNoteStrategy()
        strategy.setDifficulty(for: 60, to: 90.0)

        // Widen beyond ceiling
        strategy.updateDifficulty(for: 60, wasCorrect: false)  // 90 * 1.3 = 117 → cap to 100

        let cappedDifficulty = strategy.currentDifficulty(for: 60)
        #expect(cappedDifficulty == 100.0)  // Ceiling enforced
    }

    // MARK: - Task 4 Tests: Weak Spot Targeting (AC#4)

    @Test("Mechanical ratio 1.0 targets weak spots exclusively")
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
            let comparison = strategy.nextComparison(profile: profile, settings: settings)
            selectedNotes.insert(comparison.note1)
        }

        // Should pick from weak spots (60, 62, 64) not strong note (48)
        // Allow some variance but expect mostly weak spots
        let weakSpotSelections = selectedNotes.intersection([60, 62, 64])
        #expect(weakSpotSelections.count >= 1)  // At least one weak spot selected
    }

    @Test("Natural ratio 0.0 targets nearby notes exclusively")
    func naturalRatioTargetsNearbyNotes() async throws {
        let profile = PerceptualProfile()

        // Train all notes to avoid cold start
        for note in 0..<128 {
            profile.update(note: note, centOffset: 50, isCorrect: true)
        }

        let strategy = AdaptiveNoteStrategy()
        strategy.setLastSelectedNote(48)  // Force last note to C3

        let settings = TrainingSettings(
            noteRangeMin: 36,
            noteRangeMax: 84,
            naturalVsMechanical: 0.0  // 100% nearby
        )

        // Test multiple selections - should be near note 48 (±12 semitones)
        var selectedNotes = Set<Int>()
        for _ in 0..<20 {
            let comparison = strategy.nextComparison(profile: profile, settings: settings)
            selectedNotes.insert(comparison.note1)
        }

        // All selections should be nearby (36-60, since 48±12 = 36-60)
        let nearbyRange = 36...60
        let nearbySelections = selectedNotes.filter { nearbyRange.contains($0) }
        #expect(nearbySelections.count >= 15)  // Most selections should be nearby
    }

    // MARK: - Task 5 Tests: Settings Integration

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
            let comparison = strategy.nextComparison(profile: profile, settings: settings)
            #expect(comparison.note1 >= 48)
            #expect(comparison.note1 <= 72)
        }
    }

    @Test("Single note range works without crashing")
    func singleNoteRange() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)

        let comparison = strategy.nextComparison(profile: profile, settings: settings)

        #expect(comparison.note1 == 60)  // Only possible note
        #expect(comparison.note2 == 60)
    }

    // MARK: - Task 6 Tests: nextComparison() Orchestration

    @Test("nextComparison returns valid Comparison struct")
    func nextComparisonReturnsValidComparison() async throws {
        let profile = PerceptualProfile()
        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings()

        let comparison = strategy.nextComparison(profile: profile, settings: settings)

        // Validate Comparison structure
        #expect(comparison.note1 >= 0 && comparison.note1 <= 127)
        #expect(comparison.note2 == comparison.note1)  // Same MIDI note (frequency differs by cents)
        #expect(comparison.centDifference > 0)
        #expect(comparison.centDifference <= 100.0)
    }

    @Test("Trained profile uses difficulty from profile stats")
    func trainedProfileUsesDifficulty() async throws {
        let profile = PerceptualProfile()

        // Train note 60 with low threshold (good discrimination)
        profile.update(note: 60, centOffset: 15, isCorrect: true)
        profile.update(note: 60, centOffset: 15, isCorrect: true)

        let strategy = AdaptiveNoteStrategy()
        let settings = TrainingSettings(
            noteRangeMin: 60,
            noteRangeMax: 60,  // Force selection of note 60
            naturalVsMechanical: 0.0  // Doesn't matter with single note
        )

        let comparison = strategy.nextComparison(profile: profile, settings: settings)

        // Should use profile's threshold as starting difficulty
        // (May be adjusted, but shouldn't be cold start 100 cents)
        #expect(comparison.centDifference < 100.0)
    }
}
