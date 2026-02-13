import UIKit

/// Protocol for haptic feedback service (enables testing with mocks)
@MainActor
protocol HapticFeedback {
    /// Plays haptic feedback for incorrect answer
    func playIncorrectFeedback()
}

/// Manages haptic feedback for training interactions
///
/// Provides tactile feedback for incorrect answers, enabling eyes-closed training.
/// Follows the sensory hierarchy principle: ears > fingers > eyes.
///
/// # Haptic Pattern
/// - **Incorrect answer**: Single medium-intensity haptic tick
/// - **Correct answer**: NO haptic (silence = confirmation)
///
/// # Testing Note
/// Haptics don't work in iOS Simulator - must test on real device.
@MainActor
final class HapticFeedbackManager: HapticFeedback {
    /// UIKit haptic generator
    private let generator: UIImpactFeedbackGenerator

    /// Creates a haptic feedback manager
    ///
    /// Prepares the generator during initialization to minimize latency when feedback is triggered.
    init() {
        self.generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
    }

    /// Plays haptic feedback for incorrect answer
    ///
    /// Triggers a noticeable haptic pattern for eyes-closed training.
    /// Uses heavy-intensity impact for better tactile feedback.
    func playIncorrectFeedback() {
        generator.impactOccurred()
        // Brief second impact for more noticeable feedback
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            generator.impactOccurred()
        }
        // Prepare for next potential haptic to reduce latency
        generator.prepare()
    }
}

// MARK: - Mock for Testing

/// Mock haptic feedback manager for unit tests
@MainActor
final class MockHapticFeedbackManager: HapticFeedback {
    /// Number of times playIncorrectFeedback() was called
    private(set) var incorrectFeedbackCount = 0

    func playIncorrectFeedback() {
        incorrectFeedbackCount += 1
    }

    /// Resets the mock state (for test cleanup)
    func reset() {
        incorrectFeedbackCount = 0
    }
}
