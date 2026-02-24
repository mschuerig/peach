import Testing
import SwiftUI
@testable import Peach

/// Tests for DifficultyDisplayView formatting and accessibility logic
@Suite("DifficultyDisplayView Tests")
struct DifficultyDisplayViewTests {

    // MARK: - Formatting Tests

    @Test("formats current difficulty with one decimal place")
    func formatsCurrentDifficultyOneDecimal() {
        #expect(DifficultyDisplayView.formattedDifficulty(4.2) == "4.2")
    }

    @Test("formats whole number difficulty with one decimal place")
    func formatsWholeNumberWithDecimal() {
        #expect(DifficultyDisplayView.formattedDifficulty(100.0) == "100.0")
    }

    @Test("formats small difficulty with one decimal place")
    func formatsSmallDifficultyOneDecimal() {
        #expect(DifficultyDisplayView.formattedDifficulty(0.5) == "0.5")
    }

    @Test("rounds difficulty to one decimal place")
    func roundsDifficultyToOneDecimal() {
        #expect(DifficultyDisplayView.formattedDifficulty(4.27) == "4.3")
    }

    // MARK: - Accessibility Label Tests

    @Test("current difficulty accessibility label uses full word 'cents'")
    func currentDifficultyAccessibilityLabel() {
        let label = DifficultyDisplayView.currentDifficultyAccessibilityLabel(4.2)
        #expect(label == "Current difficulty: 4.2 cents")
    }

    @Test("session best accessibility label uses full word 'cents'")
    func sessionBestAccessibilityLabel() {
        let label = DifficultyDisplayView.sessionBestAccessibilityLabel(2.1)
        #expect(label == "Session best: 2.1 cents")
    }
}
