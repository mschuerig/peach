import Testing
import SwiftUI
@testable import Peach

/// Tests for StartScreen layout adaptation based on vertical size class (Story 7.3)
@Suite("StartScreen Layout Tests")
struct StartScreenLayoutTests {

    // MARK: - VStack Spacing

    @Test("VStack spacing is 8pt in compact mode")
    func vstackSpacingCompact() {
        #expect(StartScreen.vstackSpacing(isCompact: true) == 8)
    }

    @Test("VStack spacing is 16pt in regular mode")
    func vstackSpacingRegular() {
        #expect(StartScreen.vstackSpacing(isCompact: false) == 16)
    }

    @Test("Compact spacing is smaller than regular spacing")
    func compactSpacingSmallerThanRegular() {
        #expect(StartScreen.vstackSpacing(isCompact: true) < StartScreen.vstackSpacing(isCompact: false))
    }
}
