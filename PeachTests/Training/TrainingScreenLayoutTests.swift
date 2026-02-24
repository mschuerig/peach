import Testing
import SwiftUI
@testable import Peach

/// Tests for TrainingScreen layout adaptation based on vertical size class (Story 7.3)
@Suite("TrainingScreen Layout Tests")
struct TrainingScreenLayoutTests {

    // MARK: - Button Icon Size

    @Test("Button icon size is 60pt in compact mode")
    func buttonIconSizeCompact() {
        #expect(TrainingScreen.buttonIconSize(isCompact: true) == 60)
    }

    @Test("Button icon size is 80pt in regular mode")
    func buttonIconSizeRegular() {
        #expect(TrainingScreen.buttonIconSize(isCompact: false) == 80)
    }

    // MARK: - Button Min Height

    @Test("Button min height is 120pt in compact mode")
    func buttonMinHeightCompact() {
        #expect(TrainingScreen.buttonMinHeight(isCompact: true) == 120)
    }

    @Test("Button min height is 200pt in regular mode")
    func buttonMinHeightRegular() {
        #expect(TrainingScreen.buttonMinHeight(isCompact: false) == 200)
    }

    // MARK: - Button Text Font

    @Test("Button text font is title2 in compact mode")
    func buttonTextFontCompact() {
        #expect(TrainingScreen.buttonTextFont(isCompact: true) == .title2)
    }

    @Test("Button text font is title in regular mode")
    func buttonTextFontRegular() {
        #expect(TrainingScreen.buttonTextFont(isCompact: false) == .title)
    }

    // MARK: - Feedback Icon Size

    @Test("Feedback icon size is 70pt in compact mode")
    func feedbackIconSizeCompact() {
        #expect(TrainingScreen.feedbackIconSize(isCompact: true) == 70)
    }

    @Test("Feedback icon size is 100pt in regular mode")
    func feedbackIconSizeRegular() {
        #expect(TrainingScreen.feedbackIconSize(isCompact: false) == 100)
    }

    // MARK: - Compact vs Regular Consistency

    @Test("All compact dimensions are smaller than regular dimensions")
    func compactDimensionsSmallerThanRegular() {
        #expect(TrainingScreen.buttonIconSize(isCompact: true) < TrainingScreen.buttonIconSize(isCompact: false))
        #expect(TrainingScreen.buttonMinHeight(isCompact: true) < TrainingScreen.buttonMinHeight(isCompact: false))
        #expect(TrainingScreen.feedbackIconSize(isCompact: true) < TrainingScreen.feedbackIconSize(isCompact: false))
    }

    @Test("Compact button min height exceeds 44pt minimum tap target")
    func compactButtonMinHeightExceedsTapTarget() {
        #expect(TrainingScreen.buttonMinHeight(isCompact: true) >= 44)
    }
}
