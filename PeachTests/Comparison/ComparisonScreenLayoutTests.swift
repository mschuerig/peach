import Testing
import SwiftUI
@testable import Peach

/// Tests for ComparisonScreen layout adaptation based on vertical size class (Story 7.3)
@Suite("ComparisonScreen Layout Tests")
struct ComparisonScreenLayoutTests {

    // MARK: - Button Icon Size

    @Test("Button icon size is 60pt in compact mode")
    func buttonIconSizeCompact() {
        #expect(ComparisonScreen.buttonIconSize(isCompact: true) == 60)
    }

    @Test("Button icon size is 80pt in regular mode")
    func buttonIconSizeRegular() {
        #expect(ComparisonScreen.buttonIconSize(isCompact: false) == 80)
    }

    // MARK: - Button Min Height

    @Test("Button min height is 120pt in compact mode")
    func buttonMinHeightCompact() {
        #expect(ComparisonScreen.buttonMinHeight(isCompact: true) == 120)
    }

    @Test("Button min height is 200pt in regular mode")
    func buttonMinHeightRegular() {
        #expect(ComparisonScreen.buttonMinHeight(isCompact: false) == 200)
    }

    // MARK: - Button Text Font

    @Test("Button text font is title2 in compact mode")
    func buttonTextFontCompact() {
        #expect(ComparisonScreen.buttonTextFont(isCompact: true) == .title2)
    }

    @Test("Button text font is title in regular mode")
    func buttonTextFontRegular() {
        #expect(ComparisonScreen.buttonTextFont(isCompact: false) == .title)
    }

    // MARK: - Feedback Icon Size

    @Test("Feedback icon size is 70pt in compact mode")
    func feedbackIconSizeCompact() {
        #expect(ComparisonScreen.feedbackIconSize(isCompact: true) == 70)
    }

    @Test("Feedback icon size is 100pt in regular mode")
    func feedbackIconSizeRegular() {
        #expect(ComparisonScreen.feedbackIconSize(isCompact: false) == 100)
    }

    // MARK: - Compact vs Regular Consistency

    @Test("All compact dimensions are smaller than regular dimensions")
    func compactDimensionsSmallerThanRegular() {
        #expect(ComparisonScreen.buttonIconSize(isCompact: true) < ComparisonScreen.buttonIconSize(isCompact: false))
        #expect(ComparisonScreen.buttonMinHeight(isCompact: true) < ComparisonScreen.buttonMinHeight(isCompact: false))
        #expect(ComparisonScreen.feedbackIconSize(isCompact: true) < ComparisonScreen.feedbackIconSize(isCompact: false))
    }

    @Test("Compact button min height exceeds 44pt minimum tap target")
    func compactButtonMinHeightExceedsTapTarget() {
        #expect(ComparisonScreen.buttonMinHeight(isCompact: true) >= 44)
    }
}
