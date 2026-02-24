import Testing
import SwiftUI
@testable import Peach

/// Tests for StartScreen layout adaptation based on vertical size class (Story 7.3)
@Suite("StartScreen Layout Tests")
struct StartScreenLayoutTests {

    // MARK: - VStack Spacing

    @Test("VStack spacing is 16pt in compact mode")
    func vstackSpacingCompact() {
        #expect(StartScreen.vstackSpacing(isCompact: true) == 16)
    }

    @Test("VStack spacing is 40pt in regular mode")
    func vstackSpacingRegular() {
        #expect(StartScreen.vstackSpacing(isCompact: false) == 40)
    }

    @Test("Compact spacing is smaller than regular spacing")
    func compactSpacingSmallerThanRegular() {
        #expect(StartScreen.vstackSpacing(isCompact: true) < StartScreen.vstackSpacing(isCompact: false))
    }
}
