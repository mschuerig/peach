import Testing
@testable import Peach

/// Tests for PitchComparisonSession settings propagation via UserSettings (Stories 4.3, 6.2, 19.3)
@Suite("PitchComparisonSession Settings Tests")
struct PitchComparisonSessionSettingsTests {

    // MARK: - Settings Propagation Tests (Story 4.3)

    @Test("Strategy receives correct settings")
    func strategyReceivesCorrectSettings() async throws {
        let mockSettings = MockUserSettings()
        mockSettings.noteRange = NoteRange(lowerBound: MIDINote(48), upperBound: MIDINote(72))

        let mockPlayer = MockNotePlayer()
        let mockDataStore = MockTrainingDataStore()
        let profile = PerceptualProfile()
        let mockStrategy = MockNextPitchComparisonStrategy()

        let session = PitchComparisonSession(
            notePlayer: mockPlayer,
            strategy: mockStrategy,
            profile: profile,
            userSettings: mockSettings,
            observers: [mockDataStore, profile]
        )

        session.start(intervals: [.prime])
        try await waitForState(session, .awaitingAnswer)

        #expect(mockStrategy.lastReceivedSettings?.noteRange.lowerBound == MIDINote(48))
        #expect(mockStrategy.lastReceivedSettings?.noteRange.upperBound == MIDINote(72))
    }

    @Test("Strategy receives updated profile after answer")
    func strategyReceivesUpdatedProfileAfterAnswer() async throws {
        let f = makePitchComparisonSession()

        f.session.start(intervals: [.prime])
        try await waitForState(f.session, .awaitingAnswer)

        #expect(f.mockStrategy.callCount == 1)

        f.session.handleAnswer(isHigher: true)
        try await waitForPlayCallCount(f.mockPlayer, 3)

        #expect(f.mockStrategy.callCount == 2)
        #expect(f.mockStrategy.lastReceivedProfile === f.profile)

        let stats = f.profile.statsForNote(60)
        #expect(stats.sampleCount == 1)
    }

    // MARK: - Settings Override Tests (Story 19.3)

    @Test("PitchComparisonSession with custom UserSettings uses those values")
    func customUserSettingsUsesValues() async throws {
        let mockSettings = MockUserSettings()
        mockSettings.noteRange = NoteRange(lowerBound: MIDINote(48), upperBound: MIDINote(72))
        mockSettings.referencePitch = 432.0

        let mockPlayer = MockNotePlayer()
        let mockDataStore = MockTrainingDataStore()
        let profile = PerceptualProfile()
        let mockStrategy = MockNextPitchComparisonStrategy()

        let session = PitchComparisonSession(
            notePlayer: mockPlayer,
            strategy: mockStrategy,
            profile: profile,
            userSettings: mockSettings,
            observers: [mockDataStore, profile]
        )

        session.start(intervals: [.prime])
        try await waitForState(session, .awaitingAnswer)

        #expect(mockStrategy.lastReceivedSettings?.noteRange.lowerBound == MIDINote(48))
        #expect(mockStrategy.lastReceivedSettings?.noteRange.upperBound == MIDINote(72))
        #expect(mockStrategy.lastReceivedSettings?.referencePitch == 432.0)
    }

    @Test("noteDuration from UserSettings takes effect")
    func noteDurationFromUserSettingsTakesEffect() async throws {
        let mockSettings = MockUserSettings()
        mockSettings.noteDuration = 0.5

        let mockPlayer = MockNotePlayer()
        let mockDataStore = MockTrainingDataStore()
        let profile = PerceptualProfile()
        let mockStrategy = MockNextPitchComparisonStrategy()

        let session = PitchComparisonSession(
            notePlayer: mockPlayer,
            strategy: mockStrategy,
            profile: profile,
            userSettings: mockSettings,
            observers: [mockDataStore, profile]
        )

        session.start(intervals: [.prime])
        try await waitForState(session, .awaitingAnswer)

        #expect(mockPlayer.lastDuration == 0.5)
    }
}
