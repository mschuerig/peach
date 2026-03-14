import Foundation
@testable import Peach

final class MockPitchComparisonProfile: PitchComparisonProfile {
    // MARK: - Test State Tracking

    var updateCallCount = 0
    var lastNote: MIDINote?
    var lastCentOffset: Cents?
    var lastIsCorrect: Bool?
    var overallMean: Cents? = nil
    var overallStdDev: Cents? = nil
    var resetCallCount = 0

    private var noteStats: [Int: PerceptualNote] = [:]

    // MARK: - Test Control

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockPitchComparisonProfile", code: 1)
    var onUpdateCalled: (() -> Void)?
    var onResetCalled: (() -> Void)?

    // MARK: - PitchComparisonProfile Protocol

    func update(note: MIDINote, centOffset: Cents, isCorrect: Bool) {
        updateCallCount += 1
        lastNote = note
        lastCentOffset = centOffset
        lastIsCorrect = isCorrect
        onUpdateCalled?()
    }

    func weakSpots(count: Int) -> [MIDINote] {
        []
    }

    func statsForNote(_ note: MIDINote) -> PerceptualNote {
        noteStats[note.rawValue] ?? PerceptualNote()
    }

    func averageThreshold(noteRange: NoteRange) -> Cents? {
        nil
    }

    func setDifficulty(note: MIDINote, difficulty: Cents) {}

    func reset() {
        resetCallCount += 1
        noteStats = [:]
        overallMean = nil
        overallStdDev = nil
        onResetCalled?()
    }

    // MARK: - Test Helpers

    func resetMock() {
        updateCallCount = 0
        lastNote = nil
        lastCentOffset = nil
        lastIsCorrect = nil
        overallMean = nil
        overallStdDev = nil
        resetCallCount = 0
        noteStats = [:]
        shouldThrowError = false
        onUpdateCalled = nil
        onResetCalled = nil
    }

    func setStats(for note: MIDINote, mean: Double, sampleCount: Int = 1) {
        noteStats[note.rawValue] = PerceptualNote(mean: mean, sampleCount: sampleCount)
    }
}
