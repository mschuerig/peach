@testable import Peach

/// Mock haptic feedback manager for unit tests
final class MockHapticFeedbackManager: HapticFeedback, PitchComparisonObserver {

    // MARK: - HapticFeedback

    private(set) var incorrectFeedbackCount = 0
    var onPlayIncorrectFeedbackCalled: (() -> Void)?

    func playIncorrectFeedback() {
        incorrectFeedbackCount += 1
        onPlayIncorrectFeedbackCalled?()
    }

    // MARK: - PitchComparisonObserver

    private(set) var pitchComparisonCompletedCallCount = 0
    var lastPitchComparison: CompletedPitchComparison?

    func pitchComparisonCompleted(_ completed: CompletedPitchComparison) {
        pitchComparisonCompletedCallCount += 1
        lastPitchComparison = completed
    }

    // MARK: - Test Helpers

    func reset() {
        incorrectFeedbackCount = 0
        onPlayIncorrectFeedbackCalled = nil
        pitchComparisonCompletedCallCount = 0
        lastPitchComparison = nil
    }
}
