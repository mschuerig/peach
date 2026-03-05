import Testing
import SwiftUI
@testable import Peach

/// Tests for PitchComparisonScreen accessibility features (Story 7.2)
@Suite("PitchComparisonScreen Accessibility Tests")
struct PitchComparisonScreenAccessibilityTests {

    // MARK: - Reduce Motion (AC: #6)

    @Test("Feedback animation returns nil when reduce motion is enabled")
    func feedbackAnimationNilWhenReduceMotion() async throws {
        let animation = PitchComparisonScreen.feedbackAnimation(reduceMotion: true)
        #expect(animation == nil)
    }

    @Test("Feedback animation returns easeInOut when reduce motion is disabled")
    func feedbackAnimationPresentWhenNoReduceMotion() async throws {
        let animation = PitchComparisonScreen.feedbackAnimation(reduceMotion: false)
        #expect(animation == .easeInOut(duration: 0.2))
    }

    // MARK: - PitchComparisonFeedbackIndicator Accessibility Labels (AC: #2)

    @Test("PitchComparisonFeedbackIndicator correct state returns non-empty label")
    func feedbackIndicatorCorrectLabel() async throws {
        let label = PitchComparisonFeedbackIndicator.accessibilityLabel(isCorrect: true)
        #expect(!label.isEmpty)
    }

    @Test("PitchComparisonFeedbackIndicator incorrect state returns non-empty label")
    func feedbackIndicatorIncorrectLabel() async throws {
        let label = PitchComparisonFeedbackIndicator.accessibilityLabel(isCorrect: false)
        #expect(!label.isEmpty)
    }

    @Test("PitchComparisonFeedbackIndicator correct and incorrect labels are distinct")
    func feedbackIndicatorLabelsDistinct() async throws {
        let correctLabel = PitchComparisonFeedbackIndicator.accessibilityLabel(isCorrect: true)
        let incorrectLabel = PitchComparisonFeedbackIndicator.accessibilityLabel(isCorrect: false)
        #expect(correctLabel != incorrectLabel,
                "Correct and incorrect labels must be distinct for VoiceOver clarity")
    }

    // MARK: - Training Screen Button Accessibility Labels (AC: #1)

    @Test("Higher and Lower localization keys produce non-empty distinct strings")
    func higherLowerLocalizationKeysDistinct() async throws {
        // Note: PitchComparisonScreen applies these as .accessibilityLabel("Higher") / .accessibilityLabel("Lower")
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
