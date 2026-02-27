import Testing
@testable import Peach

/// Tests for ComparisonSession state machine transitions and core training loop
@Suite("ComparisonSession Tests")
struct ComparisonSessionTests {

    // MARK: - State Transition Tests

    @Test("ComparisonSession starts in idle state")
    func startsInIdleState() {
        let f = makeComparisonSession()
        #expect(f.session.state == .idle)
    }

    @Test("startTraining transitions from idle to playingNote1")
    func startTrainingTransitionsToPlayingNote1() async {
        let f = makeComparisonSession()

        var capturedState: ComparisonSessionState?
        f.mockPlayer.onPlayCalled = {
            if capturedState == nil {
                capturedState = f.session.state
            }
        }

        f.session.startTraining()
        await Task.yield()

        #expect(capturedState == .playingNote1)
        #expect(f.mockPlayer.playCallCount >= 1)
    }

    @Test("ComparisonSession transitions from playingNote1 to playingNote2")
    func transitionsFromNote1ToNote2() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForPlayCallCount(f.mockPlayer, 2)

        #expect(f.mockPlayer.playCallCount >= 2)
        #expect(f.session.state == .playingNote2 || f.session.state == .awaitingAnswer)
    }

    @Test("ComparisonSession transitions from playingNote2 to awaitingAnswer")
    func transitionsFromNote2ToAwaitingAnswer() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForState(f.session, .awaitingAnswer)

        #expect(f.session.state == .awaitingAnswer)
    }

    @Test("handleAnswer transitions to showingFeedback")
    func handleAnswerTransitionsToShowingFeedback() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForState(f.session, .awaitingAnswer)

        f.session.handleAnswer(isHigher: true)

        #expect(f.session.state == .showingFeedback)
    }

    @Test("ComparisonSession loops back to playingNote1 after feedback")
    func loopsBackAfterFeedback() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForState(f.session, .awaitingAnswer)

        f.session.handleAnswer(isHigher: true)
        #expect(f.session.state == .showingFeedback)

        try await waitForPlayCallCount(f.mockPlayer, 3)

        #expect(f.mockPlayer.playCallCount >= 3)
    }

    @Test("stop() transitions to idle from any state")
    func stopTransitionsToIdle() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForPlayCallCount(f.mockPlayer, 1)

        f.session.stop()

        #expect(f.session.state == .idle)
    }

    @Test("Audio error transitions to idle")
    func audioErrorTransitionsToIdle() async throws {
        let f = makeComparisonSession()
        f.mockPlayer.shouldThrowError = true
        f.mockPlayer.errorToThrow = .engineStartFailed("Test error")

        f.session.startTraining()
        try await waitForState(f.session, .idle)

        #expect(f.session.state == .idle)
    }

    // MARK: - Timing and Coordination Tests

    @Test("Buttons disabled during playingNote1")
    func buttonsDisabledDuringNote1() async {
        let f = makeComparisonSession()

        var capturedState: ComparisonSessionState?
        f.mockPlayer.onPlayCalled = {
            if capturedState == nil {
                capturedState = f.session.state
            }
        }

        f.session.startTraining()
        await Task.yield()

        #expect(capturedState == .playingNote1)
    }

    @Test("Buttons enabled during awaitingAnswer")
    func buttonsEnabledDuringAwaitingAnswer() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForState(f.session, .awaitingAnswer)

        #expect(f.session.state == .awaitingAnswer)
    }

    @Test("ComparisonSession completes full comparison loop")
    func completesFullLoop() async throws {
        let f = makeComparisonSession()

        f.session.startTraining()
        try await waitForState(f.session, .awaitingAnswer)

        f.session.handleAnswer(isHigher: true)
        try await waitForPlayCallCount(f.mockPlayer, 3)

        #expect(f.mockPlayer.playCallCount >= 3)
        #expect(f.mockDataStore.saveCallCount == 1)
    }

}
