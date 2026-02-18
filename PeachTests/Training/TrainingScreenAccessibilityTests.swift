import Testing
import SwiftUI
@testable import Peach

/// Tests for TrainingScreen accessibility features (Story 7.2)
@Suite("TrainingScreen Accessibility Tests")
@MainActor
struct TrainingScreenAccessibilityTests {

    // MARK: - Reduce Motion (AC: #6)

    @Test("Feedback animation returns nil when reduce motion is enabled")
    func feedbackAnimationNilWhenReduceMotion() async throws {
        let animation = TrainingScreen.feedbackAnimation(reduceMotion: true)
        #expect(animation == nil)
    }

    @Test("Feedback animation returns easeInOut when reduce motion is disabled")
    func feedbackAnimationPresentWhenNoReduceMotion() async throws {
        let animation = TrainingScreen.feedbackAnimation(reduceMotion: false)
        #expect(animation == .easeInOut(duration: 0.2))
    }

    // MARK: - FeedbackIndicator Accessibility Labels (AC: #2)

    @Test("FeedbackIndicator correct state returns non-empty label")
    func feedbackIndicatorCorrectLabel() async throws {
        let label = FeedbackIndicator.accessibilityLabel(isCorrect: true)
        #expect(!label.isEmpty)
    }

    @Test("FeedbackIndicator incorrect state returns non-empty label")
    func feedbackIndicatorIncorrectLabel() async throws {
        let label = FeedbackIndicator.accessibilityLabel(isCorrect: false)
        #expect(!label.isEmpty)
    }

    @Test("FeedbackIndicator correct and incorrect labels are distinct")
    func feedbackIndicatorLabelsDistinct() async throws {
        let correctLabel = FeedbackIndicator.accessibilityLabel(isCorrect: true)
        let incorrectLabel = FeedbackIndicator.accessibilityLabel(isCorrect: false)
        #expect(correctLabel != incorrectLabel,
                "Correct and incorrect labels must be distinct for VoiceOver clarity")
    }

    // MARK: - Training Screen Button Accessibility Labels (AC: #1)

    @Test("Higher and Lower localization keys produce non-empty distinct strings")
    func higherLowerLocalizationKeysDistinct() async throws {
        // Note: TrainingScreen applies these as .accessibilityLabel("Higher") / .accessibilityLabel("Lower")
        // which use LocalizedStringKey — not directly testable in unit tests.
        // This verifies the underlying localization keys are valid and distinct.
        let higher = String(localized: "Higher")
        let lower = String(localized: "Lower")
        #expect(!higher.isEmpty)
        #expect(!lower.isEmpty)
        #expect(higher != lower,
                "Higher and Lower labels must be distinct for VoiceOver navigation")
    }
}
