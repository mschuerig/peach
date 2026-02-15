import Testing
import AVFoundation
@testable import Peach

/// Tests for Story 3.4: Training Interruption and App Lifecycle Handling
@Suite("TrainingSession Lifecycle Tests")
struct TrainingSessionLifecycleTests {

    // MARK: - Test Fixtures

    @MainActor
    func makeTrainingSession() -> (TrainingSession, MockNotePlayer, MockTrainingDataStore) {
        let mockPlayer = MockNotePlayer()
        let mockDataStore = MockTrainingDataStore()
        let profile = PerceptualProfile()
        let mockStrategy = MockNextNoteStrategy()
        let observers: [ComparisonObserver] = [mockDataStore, profile]
        let session = TrainingSession(
            notePlayer: mockPlayer,
            strategy: mockStrategy,
            profile: profile,
            observers: observers
        )
        return (session, mockPlayer, mockDataStore)
    }

    // MARK: - Data Integrity Tests (AC#4)

    @MainActor
    @Test("stop() during playingNote1 discards incomplete comparison")
    func stopDuringNote1DiscardsComparison() async {
        let (session, mockPlayer, mockDataStore) = makeTrainingSession()

        var stateWhenPlayCalled: TrainingState?
        mockPlayer.onPlayCalled = {
            // Capture state and stop immediately when first note starts
            if stateWhenPlayCalled == nil {
                stateWhenPlayCalled = session.state
                session.stop()
            }
        }

        session.startTraining()
        await Task.yield()  // Let training task start

        // Verify we captured playingNote1 state
        #expect(stateWhenPlayCalled == .playingNote1)

        // Verify no data was saved
        #expect(mockDataStore.saveCallCount == 0)
        #expect(session.state == .idle)
    }

    @MainActor
    @Test("stop() during playingNote2 discards incomplete comparison")
    func stopDuringNote2DiscardsComparison() async {
        let (session, _, mockDataStore) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(60))  // Wait for playingNote2

        // Stop training before answer
        session.stop()

        // Verify no data was saved
        #expect(mockDataStore.saveCallCount == 0)
        #expect(session.state == .idle)
    }

    @MainActor
    @Test("stop() during awaitingAnswer discards incomplete comparison")
    func stopDuringAwaitingAnswerDiscardsComparison() async {
        let (session, _, mockDataStore) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))  // Wait for awaitingAnswer

        // Verify we're awaiting answer
        #expect(session.state == .awaitingAnswer)

        // Stop training before answer
        session.stop()

        // Verify no data was saved
        #expect(mockDataStore.saveCallCount == 0)
        #expect(session.state == .idle)
    }

    @MainActor
    @Test("stop() during showingFeedback preserves already-saved data")
    func stopDuringFeedbackPreservesData() async {
        let (session, _, mockDataStore) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))  // Wait for awaitingAnswer

        // Answer the comparison
        session.handleAnswer(isHigher: true)

        // Verify we're in feedback state and data was saved
        #expect(session.state == .showingFeedback)
        #expect(mockDataStore.saveCallCount == 1)

        // Stop during feedback
        session.stop()

        // Verify data was preserved (no additional save, no deletion)
        #expect(mockDataStore.saveCallCount == 1)
        #expect(mockDataStore.lastSavedRecord != nil)
        #expect(session.state == .idle)
    }

    // MARK: - stop() Behavior Tests

    @MainActor
    @Test("stop() clears feedback state")
    func stopClearsFeedbackState() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(100))

        session.handleAnswer(isHigher: false)
        #expect(session.showFeedback == true)

        session.stop()

        #expect(session.showFeedback == false)
        #expect(session.isLastAnswerCorrect == nil)
    }

    @MainActor
    @Test("stop() is safe to call multiple times")
    func stopIsSafeToCallMultipleTimes() {
        let (session, _, _) = makeTrainingSession()

        // Call stop when already idle
        session.stop()
        #expect(session.state == .idle)

        // Start training
        session.startTraining()

        // Stop multiple times
        session.stop()
        #expect(session.state == .idle)

        session.stop()
        #expect(session.state == .idle)

        // Should not crash or cause issues
    }

    @MainActor
    @Test("stop() calls notePlayer.stop()")
    func stopCallsNotePlayerStop() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(50))

        mockPlayer.stopCallCount = 0  // Reset counter

        session.stop()

        // Give async Task time to call notePlayer.stop()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(mockPlayer.stopCallCount >= 1)
    }

    // MARK: - Navigation-Based Stop Tests

    @MainActor
    @Test("Simulated onDisappear triggers stop")
    func simulatedOnDisappearTriggersStop() async {
        let (session, _, _) = makeTrainingSession()

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(session.state != .idle)

        // Simulate TrainingScreen.onDisappear calling stop()
        session.stop()

        #expect(session.state == .idle)
    }

    // MARK: - Edge Case Tests

    @MainActor
    @Test("Rapid stop and start sequence")
    func rapidStopAndStartSequence() async {
        let (session, mockPlayer, _) = makeTrainingSession()

        // Start, stop, start quickly
        session.startTraining()
        try? await Task.sleep(for: .milliseconds(10))

        session.stop()
        #expect(session.state == .idle)

        session.startTraining()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(session.state != .idle)
        #expect(mockPlayer.playCallCount >= 1)
    }

    @MainActor
    @Test("stop() during transition between states")
    func stopDuringStateTransition() async {
        let (session, _, mockDataStore) = makeTrainingSession()

        session.startTraining()

        // Rapidly call stop during early phases
        try? await Task.sleep(for: .milliseconds(5))
        session.stop()

        // Verify clean stop
        #expect(session.state == .idle)
        #expect(mockDataStore.saveCallCount == 0)
    }
}
