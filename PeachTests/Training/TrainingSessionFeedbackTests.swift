import Testing
@testable import Peach

/// Tests for TrainingSession feedback state management (Story 3.3)
@Suite("TrainingSession Feedback Tests")
struct TrainingSessionFeedbackTests {

    // MARK: - Test Fixtures

    @MainActor
    func makeTrainingSession() -> (TrainingSession, MockNotePlayer, MockTrainingDataStore, MockHapticFeedbackManager) {
        let mockPlayer = MockNotePlayer()
        let mockDataStore = MockTrainingDataStore()
        let mockHaptic = MockHapticFeedbackManager()
        let session = TrainingSession(
            notePlayer: mockPlayer,
            dataStore: mockDataStore,
            hapticManager: mockHaptic
        )
        return (session, mockPlayer, mockDataStore, mockHaptic)
    }

    // MARK: - Feedback State Tests

    @MainActor
    @Test("Initial feedback state is hidden")
    func initialFeedbackState() async {
        let (session, _, _, _) = makeTrainingSession()

        #expect(session.showFeedback == false)
        #expect(session.isLastAnswerCorrect == nil)
    }

    @MainActor
    @Test("Feedback shows after correct answer")
    func feedbackShowsAfterCorrectAnswer() async throws {
        let (session, mockPlayer, _, _) = makeTrainingSession()

        // Start training
        session.startTraining()

        // Wait for notes to play
        try await Task.sleep(for: .milliseconds(100))

        // Answer correctly (second note is higher if centDifference > 0)
        // Since Comparison.random() might give us either, we need to check and answer correctly
        // For this test, we'll check the current comparison and answer correctly
        let comparison = try #require(mockPlayer.playHistory.count >= 2)

        // The second frequency is higher if it's greater than the first
        let isSecondHigher = mockPlayer.playHistory[1].frequency > mockPlayer.playHistory[0].frequency
        session.handleAnswer(isHigher: isSecondHigher)

        // Verify feedback state is set correctly
        #expect(session.showFeedback == true)
        #expect(session.isLastAnswerCorrect == true)
    }

    @MainActor
    @Test("Feedback shows after incorrect answer")
    func feedbackShowsAfterIncorrectAnswer() async throws {
        let (session, mockPlayer, _, _) = makeTrainingSession()

        // Start training
        session.startTraining()

        // Wait for notes to play
        try await Task.sleep(for: .milliseconds(100))

        // Answer incorrectly (opposite of what the comparison says)
        let comparison = try #require(mockPlayer.playHistory.count >= 2)

        // The second frequency is higher if it's greater than the first
        let isSecondHigher = mockPlayer.playHistory[1].frequency > mockPlayer.playHistory[0].frequency
        // Answer incorrectly by saying the opposite
        session.handleAnswer(isHigher: !isSecondHigher)

        // Verify feedback state is set correctly
        #expect(session.showFeedback == true)
        #expect(session.isLastAnswerCorrect == false)
    }

    @MainActor
    @Test("Feedback clears before next comparison")
    func feedbackClearsBeforeNextComparison() async throws {
        let (session, mockPlayer, _, _) = makeTrainingSession()

        // Start training
        session.startTraining()

        // Wait for first notes to play
        try await Task.sleep(for: .milliseconds(100))

        // Answer (correct or incorrect doesn't matter)
        let isSecondHigher = mockPlayer.playHistory[1].frequency > mockPlayer.playHistory[0].frequency
        session.handleAnswer(isHigher: isSecondHigher)

        // Verify feedback is showing
        #expect(session.showFeedback == true)

        // Wait for feedback duration to expire (400ms)
        try await Task.sleep(for: .milliseconds(500))

        // Verify feedback has cleared
        #expect(session.showFeedback == false)
    }

    // MARK: - Haptic Feedback Tests

    @MainActor
    @Test("Haptic fires on incorrect answer")
    func hapticFiresOnIncorrectAnswer() async throws {
        let (session, mockPlayer, _, mockHaptic) = makeTrainingSession()

        // Start training
        session.startTraining()

        // Wait for notes to play
        try await Task.sleep(for: .milliseconds(100))

        // Answer incorrectly
        let isSecondHigher = mockPlayer.playHistory[1].frequency > mockPlayer.playHistory[0].frequency
        session.handleAnswer(isHigher: !isSecondHigher)

        // Verify haptic was triggered
        #expect(mockHaptic.incorrectFeedbackCount == 1)
    }

    @MainActor
    @Test("Haptic does NOT fire on correct answer")
    func hapticDoesNotFireOnCorrectAnswer() async throws {
        let (session, mockPlayer, _, mockHaptic) = makeTrainingSession()

        // Start training
        session.startTraining()

        // Wait for notes to play
        try await Task.sleep(for: .milliseconds(100))

        // Answer correctly
        let isSecondHigher = mockPlayer.playHistory[1].frequency > mockPlayer.playHistory[0].frequency
        session.handleAnswer(isHigher: isSecondHigher)

        // Verify haptic was NOT triggered
        #expect(mockHaptic.incorrectFeedbackCount == 0)
    }

    @MainActor
    @Test("Feedback state clears when training stops")
    func feedbackClearsWhenTrainingStops() async throws {
        let (session, mockPlayer, _, _) = makeTrainingSession()

        // Start training
        session.startTraining()

        // Wait for notes to play
        try await Task.sleep(for: .milliseconds(100))

        // Answer to trigger feedback
        let isSecondHigher = mockPlayer.playHistory[1].frequency > mockPlayer.playHistory[0].frequency
        session.handleAnswer(isHigher: isSecondHigher)

        // Verify feedback is showing
        #expect(session.showFeedback == true)
        #expect(session.isLastAnswerCorrect != nil)

        // Stop training
        session.stop()

        // Verify feedback state is cleared
        #expect(session.showFeedback == false)
        #expect(session.isLastAnswerCorrect == nil)
    }
}
