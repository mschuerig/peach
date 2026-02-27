import SwiftUI

// MARK: - Core Environment Keys

extension EnvironmentValues {
    @Entry var soundFontLibrary = SoundFontLibrary()
    @Entry var trendAnalyzer = TrendAnalyzer()
    @Entry var thresholdTimeline = ThresholdTimeline()
    @Entry var activeSession: (any TrainingSession)? = nil
    @Entry var perceptualProfile = PerceptualProfile()
}

// MARK: - Session Environment Keys

extension EnvironmentValues {
    @Entry var comparisonSession: ComparisonSession = {
        let dataStore = PreviewDataStore()
        let profile = PerceptualProfile()
        let strategy = PreviewComparisonStrategy()
        let observers: [ComparisonObserver] = [dataStore, profile]
        return ComparisonSession(
            notePlayer: PreviewNotePlayer(),
            strategy: strategy,
            profile: profile,
            userSettings: PreviewUserSettings(),
            observers: observers
        )
    }()

    @Entry var pitchMatchingSession: PitchMatchingSession = {
        return PitchMatchingSession(
            notePlayer: PreviewNotePlayer(),
            profile: PerceptualProfile(),
            observers: [],
            userSettings: PreviewUserSettings()
        )
    }()
}

// MARK: - Preview Stubs

private final class PreviewNotePlayer: NotePlayer {
    func play(frequency: Frequency, velocity: MIDIVelocity, amplitudeDB: AmplitudeDB) async throws -> PlaybackHandle {
        PreviewPlaybackHandle()
    }

    func stopAll() async throws {}
}

private final class PreviewPlaybackHandle: PlaybackHandle {
    func stop() async throws {}
    func adjustFrequency(_ frequency: Frequency) async throws {}
}

private final class PreviewDataStore: ComparisonRecordStoring, ComparisonObserver {
    func save(_ record: ComparisonRecord) throws {}
    func fetchAllComparisons() throws -> [ComparisonRecord] { [] }
    func comparisonCompleted(_ completed: CompletedComparison) {}
}

private final class PreviewComparisonStrategy: NextComparisonStrategy {
    func nextComparison(
        profile: PitchDiscriminationProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Comparison {
        Comparison(note1: MIDINote(60), note2: MIDINote(60), centDifference: Cents(50.0))
    }
}

private final class PreviewUserSettings: UserSettings {
    var noteRangeMin: MIDINote { MIDINote(36) }
    var noteRangeMax: MIDINote { MIDINote(84) }
    var noteDuration: NoteDuration { NoteDuration(0.75) }
    var referencePitch: Frequency { Frequency(440.0) }
    var soundSource: SoundSourceID { SoundSourceID("sf2:8:80") }
    var varyLoudness: UnitInterval { UnitInterval(0.0) }
}
