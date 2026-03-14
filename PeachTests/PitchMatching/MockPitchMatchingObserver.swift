@testable import Peach

final class MockPitchMatchingObserver: PitchMatchingObserver {
    // MARK: - Test State Tracking

    var pitchMatchingCompletedCallCount = 0
    var lastResult: CompletedPitchMatching?
    var resultHistory: [CompletedPitchMatching] = []

    // MARK: - Test Control

    var onPitchMatchingCompletedCalled: (() -> Void)?

    // MARK: - PitchMatchingObserver Protocol

    func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
        pitchMatchingCompletedCallCount += 1
        lastResult = result
        resultHistory.append(result)
        onPitchMatchingCompletedCalled?()
    }

    // MARK: - Test Helpers

    func reset() {
        pitchMatchingCompletedCallCount = 0
        lastResult = nil
        resultHistory = []
        onPitchMatchingCompletedCalled = nil
    }
}
