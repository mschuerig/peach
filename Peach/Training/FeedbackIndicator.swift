import SwiftUI

/// Visual feedback indicator showing correct/incorrect answer result
///
/// Displays a thumbs up (green) for correct answers or thumbs down (red) for incorrect answers.
/// Designed to be visible in peripheral vision without obstructing the training buttons.
///
/// # Accessibility
/// - Provides VoiceOver labels ("Correct" or "Incorrect")
/// - Respects Reduce Motion (uses simple opacity transition)
/// - Large icon size (100pt) for visibility
///
/// # Usage
/// ```swift
/// FeedbackIndicator(isCorrect: trainingSession.isLastAnswerCorrect)
///     .opacity(trainingSession.showFeedback ? 1 : 0)
/// ```
struct FeedbackIndicator: View {
    /// Whether the answer was correct (nil = no feedback to show)
    let isCorrect: Bool?

    var body: some View {
        if let isCorrect {
            Image(systemName: isCorrect ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.system(size: 100))
                .foregroundStyle(isCorrect ? .green : .red)
                .accessibilityLabel(isCorrect ? String(localized: "Correct") : String(localized: "Incorrect"))
        }
    }
}

// MARK: - Previews

#Preview("Correct") {
    FeedbackIndicator(isCorrect: true)
        .padding()
}

#Preview("Incorrect") {
    FeedbackIndicator(isCorrect: false)
        .padding()
}

#Preview("No Feedback") {
    FeedbackIndicator(isCorrect: nil)
        .padding()
}
