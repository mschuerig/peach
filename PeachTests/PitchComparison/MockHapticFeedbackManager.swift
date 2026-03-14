import Foundation
@testable import Peach

/// Mock haptic feedback manager for unit tests
final class MockHapticFeedbackManager: HapticFeedback, PitchComparisonObserver {

    // MARK: - HapticFeedback

    private(set) var incorrectFeedbackCount = 0

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
        onPitchComparisonCompletedCalled?()
    }

    // MARK: - Test Control

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockHapticFeedback", code: 1)
    var onPlayIncorrectFeedbackCalled: (() -> Void)?
    var onPitchComparisonCompletedCalled: (() -> Void)?

    // MARK: - Test Helpers

    func reset() {
        incorrectFeedbackCount = 0
        pitchComparisonCompletedCallCount = 0
        lastPitchComparison = nil
        shouldThrowError = false
        onPlayIncorrectFeedbackCalled = nil
        onPitchComparisonCompletedCalled = nil
    }
}
