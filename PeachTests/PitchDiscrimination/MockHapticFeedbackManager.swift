import Foundation
@testable import Peach

/// Mock haptic feedback manager for unit tests
final class MockHapticFeedbackManager: HapticFeedback, PitchDiscriminationObserver, RhythmComparisonObserver {

    // MARK: - HapticFeedback

    private(set) var incorrectFeedbackCount = 0

    func playIncorrectFeedback() {
        incorrectFeedbackCount += 1
        onPlayIncorrectFeedbackCalled?()
    }

    // MARK: - PitchDiscriminationObserver

    private(set) var pitchDiscriminationCompletedCallCount = 0
    var lastTrial: CompletedPitchDiscriminationTrial?

    func pitchDiscriminationCompleted(_ completed: CompletedPitchDiscriminationTrial) {
        pitchDiscriminationCompletedCallCount += 1
        lastTrial = completed
        onPitchDiscriminationCompletedCalled?()
    }

    // MARK: - RhythmComparisonObserver

    private(set) var rhythmComparisonCompletedCallCount = 0
    var lastRhythmComparison: CompletedRhythmComparison?

    func rhythmComparisonCompleted(_ result: CompletedRhythmComparison) {
        rhythmComparisonCompletedCallCount += 1
        lastRhythmComparison = result
        onRhythmComparisonCompletedCalled?()
    }

    // MARK: - Test Control

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockHapticFeedback", code: 1)
    var onPlayIncorrectFeedbackCalled: (() -> Void)?
    var onPitchDiscriminationCompletedCalled: (() -> Void)?
    var onRhythmComparisonCompletedCalled: (() -> Void)?

    // MARK: - Test Helpers

    func reset() {
        incorrectFeedbackCount = 0
        pitchDiscriminationCompletedCallCount = 0
        lastTrial = nil
        rhythmComparisonCompletedCallCount = 0
        lastRhythmComparison = nil
        shouldThrowError = false
        onPlayIncorrectFeedbackCalled = nil
        onPitchDiscriminationCompletedCalled = nil
        onRhythmComparisonCompletedCalled = nil
    }
}
