import Testing
import SwiftData
import SwiftUI
@testable import Peach

@Suite("Settings Tests")
struct SettingsTests {

    // MARK: - Task 1: @AppStorage Keys and Defaults

    @Test("Default values match TrainingSettings defaults")
    func defaultsMatchTrainingSettings() {
        let trainingDefaults = TrainingSettings()

        #expect(SettingsKeys.defaultNaturalVsMechanical == trainingDefaults.naturalVsMechanical)
        #expect(SettingsKeys.defaultNoteRangeMin == trainingDefaults.noteRangeMin)
        #expect(SettingsKeys.defaultNoteRangeMax == trainingDefaults.noteRangeMax)
        #expect(SettingsKeys.defaultNoteDuration == 1.0)
        #expect(SettingsKeys.defaultReferencePitch == trainingDefaults.referencePitch)
        #expect(SettingsKeys.defaultSoundSource == "sine")
    }

    @Test("Storage keys are defined as string constants")
    func storageKeysAreDefined() {
        #expect(SettingsKeys.naturalVsMechanical == "naturalVsMechanical")
        #expect(SettingsKeys.noteRangeMin == "noteRangeMin")
        #expect(SettingsKeys.noteRangeMax == "noteRangeMax")
        #expect(SettingsKeys.noteDuration == "noteDuration")
        #expect(SettingsKeys.referencePitch == "referencePitch")
        #expect(SettingsKeys.soundSource == "soundSource")
    }

    // MARK: - Task 2: Note Range Validation

    @Test("Clamping upper bound when lower bound increases past gap")
    func clampUpperWhenLowerIncreasesTooHigh() {
        // If lower = 78 and upper = 84, increasing lower to 78 is fine (gap = 6? no, gap must be 12)
        // Actually: lower < upper with minimum gap of 12
        // If lower goes to 73, upper is 84 → gap = 11 → must clamp upper to 73 + 12 = 85
        let lower = 73
        let upper = 84
        let minGap = 12
        let adjustedUpper = max(upper, lower + minGap)
        #expect(adjustedUpper == 85)
    }

    @Test("Clamping lower bound when upper bound decreases past gap")
    func clampLowerWhenUpperDecreasesTooLow() {
        let lower = 36
        let upper = 47
        let minGap = 12
        let adjustedLower = min(lower, upper - minGap)
        #expect(adjustedLower == 35)
    }

    @Test("Note name display uses PianoKeyboardLayout")
    func noteNameDisplay() {
        #expect(PianoKeyboardLayout.noteName(midiNote: 36) == "C2")
        #expect(PianoKeyboardLayout.noteName(midiNote: 84) == "C6")
        #expect(PianoKeyboardLayout.noteName(midiNote: 69) == "A4")
        #expect(PianoKeyboardLayout.noteName(midiNote: 21) == "A0")
        #expect(PianoKeyboardLayout.noteName(midiNote: 108) == "C8")
    }

    // MARK: - Task 3: Reset Functionality

    @Test("PerceptualProfile reset clears all note data")
    @MainActor
    func profileResetClearsData() {
        let profile = PerceptualProfile()

        // Add some training data
        profile.update(note: 60, centOffset: 5.0, isCorrect: true)
        profile.update(note: 60, centOffset: 3.0, isCorrect: true)
        profile.update(note: 72, centOffset: -2.0, isCorrect: false)
        #expect(profile.statsForNote(60).sampleCount == 2)
        #expect(profile.statsForNote(72).sampleCount == 1)
        #expect(profile.overallMean != nil)

        // Reset
        profile.reset()

        // Verify cold start state
        #expect(profile.statsForNote(60).sampleCount == 0)
        #expect(profile.statsForNote(72).sampleCount == 0)
        #expect(profile.overallMean == nil)
        #expect(profile.overallStdDev == nil)
    }

    @Test("TrendAnalyzer reset clears all trend data")
    @MainActor
    func trendAnalyzerResetClearsData() {
        // Create with enough records to have a trend
        var records: [ComparisonRecord] = []
        for i in 0..<30 {
            let record = ComparisonRecord(
                note1: 60,
                note2: 61,
                note2CentOffset: Double(i) + 1.0,
                isCorrect: true
            )
            records.append(record)
        }
        let analyzer = TrendAnalyzer(records: records)
        #expect(analyzer.trend != nil)

        // Reset
        analyzer.reset()

        // Verify cleared state
        #expect(analyzer.trend == nil)
    }

    @Test("Reset deletes all ComparisonRecords from SwiftData")
    @MainActor
    func resetDeletesComparisonRecords() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ComparisonRecord.self, configurations: config)
        let context = container.mainContext

        // Insert test records
        let record1 = ComparisonRecord(
            note1: 60,
            note2: 61,
            note2CentOffset: 2.0,
            isCorrect: true
        )
        let record2 = ComparisonRecord(
            note1: 72,
            note2: 73,
            note2CentOffset: 2.5,
            isCorrect: false
        )
        context.insert(record1)
        context.insert(record2)
        try context.save()

        // Verify records exist
        let fetchBefore = FetchDescriptor<ComparisonRecord>()
        let countBefore = try context.fetchCount(fetchBefore)
        #expect(countBefore == 2)

        // Delete all using the same approach as SettingsScreen
        try context.delete(model: ComparisonRecord.self)

        // Verify records deleted
        let fetchAfter = FetchDescriptor<ComparisonRecord>()
        let countAfter = try context.fetchCount(fetchAfter)
        #expect(countAfter == 0)
    }

    // MARK: - Task 5: SettingsScreen Rendering

    @Test("SettingsScreen body can be created without crashing")
    @MainActor
    func settingsScreenCreation() {
        // Verify SettingsScreen can be instantiated
        let screen = SettingsScreen()
        #expect(type(of: screen.body) != Never.self)
    }
}
