@testable import Peach

/// Mock haptic feedback manager for unit tests
final class MockHapticFeedbackManager: HapticFeedback, ComparisonObserver {
    /// Number of times playIncorrectFeedback() was called
    private(set) var incorrectFeedbackCount = 0

    func playIncorrectFeedback() {
        incorrectFeedbackCount += 1
    }

    // MARK: - ComparisonObserver

    /// Called when a comparison is completed - tracks haptic feedback for incorrect answers
    func comparisonCompleted(_ completed: CompletedComparison) {
        if !completed.isCorrect {
            playIncorrectFeedback()
        }
    }

    /// Resets the mock state (for test cleanup)
    func reset() {
        incorrectFeedbackCount = 0
    }
}
