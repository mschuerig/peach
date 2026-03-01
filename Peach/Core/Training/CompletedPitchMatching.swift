import Foundation

struct CompletedPitchMatching {
    let referenceNote: MIDINote
    let targetNote: MIDINote
    let initialCentOffset: Double
    let userCentError: Double
    let tuningSystem: TuningSystem
    let timestamp: Date

    init(referenceNote: MIDINote, targetNote: MIDINote, initialCentOffset: Double, userCentError: Double, tuningSystem: TuningSystem, timestamp: Date = Date()) {
        self.referenceNote = referenceNote
        self.targetNote = targetNote
        self.initialCentOffset = initialCentOffset
        self.userCentError = userCentError
        self.tuningSystem = tuningSystem
        self.timestamp = timestamp
    }
}
