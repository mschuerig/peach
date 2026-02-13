import Testing
@testable import Peach

/// Comprehensive tests for TrainingSession state machine and training loop
@Suite("TrainingSession Tests")
struct TrainingSessionTests {

    // MARK: - Test Fixtures

    @MainActor
    func makeTrainingSession() -> (TrainingSession, MockNotePlayer, MockTrainingDataStore) {
        let mockPlayer = MockNotePlayer()
        let mockDataStore = MockTrainingDataStore()
        let session = TrainingSession(notePlayer: mockPlayer, dataStore: mockDataStore)
        return (session, mockPlayer, mockDataStore)
    }

    // MARK: - State Transition Tests

    @MainActor
    @Test("TrainingSession starts in idle state")
    func startsInIdleState() {
        let (session, _, _) = makeTrainingSession()
        #expect(session.state == .idle)
    }

    @MainActor
    @Test("startTraining transitions from idle to playingNote1")
    func startTrainingTransitionsToPlayingNote1() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()

        // Wait for first note to start playing
        try? await Task.sleep(for: .milliseconds(20))

        #expect(session.state == .playingNote1 || session.state == .playingNote2)
        #expect(mockPlayer.playCallCount >= 1)
    }

    @MainActor
    @Test("TrainingSession transitions from playingNote1 to playingNote2")
    func transitionsFromNote1ToNote2() async {
        let (session, mockPlayer, _) = makeTrainingSession()
        mockPlayer.simulatedPlaybackDuration = 0.02  // 20ms

        session.startTraining()

        // Wait for first note to complete
        try? await Task.sleep(for: .milliseconds(50))

        // Should have played note 1 and started note 2
        #expect(mockPlayer.playCallCount >= 1)
        #expect(session.state == .playingNote2 || session.state == .awaitingAnswer)
    }

    @MainActor
    @Test("TrainingSession transitions from playingNote2 to awaitingAnswer")
    func transitionsFromNote2ToAwaitingAnswer() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()

        // Wait for both notes to complete
        try? await Task.sleep(for: .milliseconds(100))

        #expect(session.state == .awaitingAnswer || session.state == .showingFeedback)
    }

    @MainActor
    @Test("handleAnswer transitions to showingFeedback")
    func handleAnswerTransitionsToShowingFeedback() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))  // Wait for awaitingAnswer state

        session.handleAnswer(isHigher: true)

        #expect(session.state == .showingFeedback)
    }

    @MainActor
    @Test("TrainingSession loops back to playingNote1 after feedback")
    func loopsBackAfterFeedback() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))  // Wait for awaitingAnswer

        session.handleAnswer(isHigher: true)
        #expect(session.state == .showingFeedback)

        // Wait for feedback duration + next comparison to start
        try? await Task.sleep(for: .milliseconds(500))

        // Should have looped back and started next comparison
        #expect(mockPlayer.playCallCount >= 3)  // At least note1, note2, next note1
    }

    @MainActor
    @Test("stop() transitions to idle from any state")
    func stopTransitionsToIdle() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(50))

        session.stop()

        #expect(session.state == .idle)
    }

    @MainActor
    @Test("Audio error transitions to idle")
    func audioErrorTransitionsToIdle() async {
        let (session, mockPlayer, _) = makeTrainingSession()
        mockPlayer.shouldThrowError = true
        mockPlayer.errorToThrow = .renderFailed("Test error")

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(session.state == .idle)
    }

    // MARK: - Comparison Generation Tests

    @Test("Comparison.random generates note1 in valid MIDI range")
    func comparisonGeneratesValidMidiNote() {
        for _ in 0..<100 {
            let comparison = Comparison.random()
            #expect(comparison.note1 >= 48 && comparison.note1 <= 72)
        }
    }

    @Test("Comparison uses 100 cent difference")
    func comparisonUses100Cents() {
        let comparison = Comparison.random()
        #expect(comparison.centDifference == 100.0)
    }

    @Test("Comparison randomly chooses higher or lower")
    func comparisonRandomizesDirection() {
        var hasHigher = false
        var hasLower = false

        // Generate many comparisons to ensure randomness
        for _ in 0..<50 {
            let comparison = Comparison.random()
            if comparison.isSecondNoteHigher {
                hasHigher = true
            } else {
                hasLower = true
            }
        }

        #expect(hasHigher && hasLower, "Should generate both higher and lower comparisons")
    }

    // MARK: - NotePlayer Integration Tests

    @MainActor
    @Test("TrainingSession calls play twice per comparison")
    func callsPlayTwicePerComparison() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(mockPlayer.playCallCount == 2)  // note1 and note2
    }

    @MainActor
    @Test("TrainingSession uses correct frequency calculation")
    func usesCorrectFrequencyCalculation() async throws {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        // Verify frequencies were calculated and passed to player
        #expect(mockPlayer.lastFrequency != nil)
        #expect(mockPlayer.lastFrequency! > 0)

        // Frequency should be in audible range for MIDI 48-72 (roughly 130-1047 Hz)
        #expect(mockPlayer.lastFrequency! >= 100 && mockPlayer.lastFrequency! <= 1200)
    }

    @MainActor
    @Test("TrainingSession passes correct duration to NotePlayer")
    func passesCorrectDuration() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(mockPlayer.lastDuration == 1.0)  // Default 1 second duration
    }

    @MainActor
    @Test("TrainingSession passes correct amplitude to NotePlayer")
    func passesCorrectAmplitude() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(mockPlayer.lastAmplitude == 0.5)  // Default amplitude
    }

    // MARK: - TrainingDataStore Integration Tests

    @MainActor
    @Test("TrainingSession records comparison on answer")
    func recordsComparisonOnAnswer() async {
        let (session, _, mockDataStore) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        session.handleAnswer(isHigher: true)

        #expect(mockDataStore.saveCallCount == 1)
        #expect(mockDataStore.lastSavedRecord != nil)
    }

    @MainActor
    @Test("ComparisonRecord contains correct note data")
    func comparisonRecordContainsCorrectData() async {
        let (session, _, mockDataStore) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        session.handleAnswer(isHigher: false)

        let record = mockDataStore.lastSavedRecord!
        #expect(record.note1 >= 48 && record.note1 <= 72)
        #expect(record.note2 >= 48 && record.note2 <= 72)
        #expect(abs(record.note2CentOffset) == 100.0)  // +100 or -100
    }

    @MainActor
    @Test("Data error does not stop training")
    func dataErrorDoesNotStopTraining() async {
        let (session, mockPlayer, mockDataStore) = makeTrainingSession()
        mockDataStore.shouldThrowError = true

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        session.handleAnswer(isHigher: true)

        // Should continue to feedback state despite save error
        #expect(session.state == .showingFeedback)

        // Wait for next comparison to start
        try? await Task.sleep(for: .milliseconds(500))

        // Training should have continued with next comparison
        #expect(mockPlayer.playCallCount >= 3)
    }

    // MARK: - Timing and Coordination Tests

    @MainActor
    @Test("Buttons disabled during playingNote1")
    func buttonsDisabledDuringNote1() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(20))

        let state = session.state
        #expect(state == .playingNote1 || state == .playingNote2)
    }

    @MainActor
    @Test("Buttons enabled during playingNote2 and awaitingAnswer")
    func buttonsEnabledDuringNote2AndWaiting() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        let state = session.state
        // Buttons should be enabled when state is playingNote2 or awaitingAnswer
        #expect(state == .playingNote2 || state == .awaitingAnswer)
    }

    @MainActor
    @Test("TrainingSession completes full comparison loop")
    func completesFullLoop() async {
        let (session, mockPlayer, mockDataStore) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        // Answer first comparison
        session.handleAnswer(isHigher: true)

        // Wait for feedback and next comparison
        try? await Task.sleep(for: .milliseconds(600))

        // Should have completed loop and started next comparison
        #expect(mockPlayer.playCallCount >= 3)  // note1, note2, next note1
        #expect(mockDataStore.saveCallCount == 1)
    }

    // MARK: - Comparison Value Type Tests

    @Test("Comparison.note1Frequency calculates valid frequency")
    func note1FrequencyCalculatesCorrectly() throws {
        let comparison = Comparison(note1: 60, note2: 60, centDifference: 100.0, isSecondNoteHigher: true)

        let freq = try comparison.note1Frequency()

        // Middle C (MIDI 60) should be ~261.63 Hz at A440
        #expect(freq >= 260 && freq <= 263)
    }

    @Test("Comparison.note2Frequency applies cent offset higher")
    func note2FrequencyAppliesCentOffsetHigher() throws {
        let comparison = Comparison(note1: 60, note2: 60, centDifference: 100.0, isSecondNoteHigher: true)

        let freq1 = try comparison.note1Frequency()
        let freq2 = try comparison.note2Frequency()

        // Second note should be higher
        #expect(freq2 > freq1)

        // Difference should be approximately 1 semitone (about 6% higher)
        let ratio = freq2 / freq1
        #expect(ratio >= 1.05 && ratio <= 1.07)
    }

    @Test("Comparison.note2Frequency applies cent offset lower")
    func note2FrequencyAppliesCentOffsetLower() throws {
        let comparison = Comparison(note1: 60, note2: 60, centDifference: 100.0, isSecondNoteHigher: false)

        let freq1 = try comparison.note1Frequency()
        let freq2 = try comparison.note2Frequency()

        // Second note should be lower
        #expect(freq2 < freq1)
    }

    @Test("Comparison.isCorrect validates user answer correctly")
    func isCorrectValidatesAnswer() {
        let comparisonHigher = Comparison(note1: 60, note2: 60, centDifference: 100.0, isSecondNoteHigher: true)
        let comparisonLower = Comparison(note1: 60, note2: 60, centDifference: 100.0, isSecondNoteHigher: false)

        #expect(comparisonHigher.isCorrect(userAnswerHigher: true) == true)
        #expect(comparisonHigher.isCorrect(userAnswerHigher: false) == false)
        #expect(comparisonLower.isCorrect(userAnswerHigher: false) == true)
        #expect(comparisonLower.isCorrect(userAnswerHigher: true) == false)
    }
}
