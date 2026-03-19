import Foundation
@testable import Peach

final class MockPitchComparisonProfile: PitchComparisonProfile {
    // MARK: - Test State Tracking

    var updateCallCount = 0
    var lastNote: MIDINote?
    var lastCentOffset: Cents?
    var lastIsCorrect: Bool?
    var comparisonMean: Cents? = nil
    var comparisonStdDev: Cents? = nil

    // MARK: - Test Control

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockPitchComparisonProfile", code: 1)
    var onUpdateCalled: (() -> Void)?

    // MARK: - PitchComparisonProfile Protocol

    func updateComparison(note: MIDINote, centOffset: Cents, isCorrect: Bool) {
        updateCallCount += 1
        lastNote = note
        lastCentOffset = centOffset
        lastIsCorrect = isCorrect
        onUpdateCalled?()
    }

    // MARK: - Test Helpers

    func resetMock() {
        updateCallCount = 0
        lastNote = nil
        lastCentOffset = nil
        lastIsCorrect = nil
        comparisonMean = nil
        comparisonStdDev = nil
        shouldThrowError = false
        onUpdateCalled = nil
    }
}
