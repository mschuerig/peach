import Testing
import SwiftUI
@testable import Peach

/// Tests for ProfileScreen layout adaptation based on vertical size class (Story 7.3)
@Suite("ProfileScreen Layout Tests")
@MainActor
struct ProfileScreenLayoutTests {

    // MARK: - Confidence Band Min Height

    @Test("Confidence band min height is 120pt in compact mode")
    func confidenceBandMinHeightCompact() {
        #expect(ProfileScreen.confidenceBandMinHeight(isCompact: true) == 120)
    }

    @Test("Confidence band min height is 200pt in regular mode")
    func confidenceBandMinHeightRegular() {
        #expect(ProfileScreen.confidenceBandMinHeight(isCompact: false) == 200)
    }

    // MARK: - Keyboard Height

    @Test("Keyboard height is 40pt in compact mode")
    func keyboardHeightCompact() {
        #expect(ProfileScreen.keyboardHeight(isCompact: true) == 40)
    }

    @Test("Keyboard height is 60pt in regular mode")
    func keyboardHeightRegular() {
        #expect(ProfileScreen.keyboardHeight(isCompact: false) == 60)
    }

    // MARK: - Compact vs Regular Consistency

    @Test("All compact dimensions are smaller than regular dimensions")
    func compactDimensionsSmallerThanRegular() {
        #expect(ProfileScreen.confidenceBandMinHeight(isCompact: true) < ProfileScreen.confidenceBandMinHeight(isCompact: false))
        #expect(ProfileScreen.keyboardHeight(isCompact: true) < ProfileScreen.keyboardHeight(isCompact: false))
    }

    @Test("Compact confidence band min height exceeds 44pt minimum tap target")
    func compactConfidenceBandExceedsTapTarget() {
        #expect(ProfileScreen.confidenceBandMinHeight(isCompact: true) >= 44)
    }
}
