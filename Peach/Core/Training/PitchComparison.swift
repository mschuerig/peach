import Foundation

struct PitchComparison {
    let referenceNote: MIDINote
    let targetNote: DetunedMIDINote

    var isTargetHigher: Bool {
        targetNote.offset.rawValue > 0
    }

    func referenceFrequency(tuningSystem: TuningSystem, referencePitch: Frequency) -> Frequency {
        tuningSystem.frequency(for: referenceNote, referencePitch: referencePitch)
    }

    func targetFrequency(tuningSystem: TuningSystem, referencePitch: Frequency) -> Frequency {
        tuningSystem.frequency(for: targetNote, referencePitch: referencePitch)
    }

    func isCorrect(userAnswerHigher: Bool) -> Bool {
        return userAnswerHigher == isTargetHigher
    }
}

struct CompletedPitchComparison {
    let pitchComparison: PitchComparison
    let userAnsweredHigher: Bool
    let tuningSystem: TuningSystem

    var isCorrect: Bool {
        pitchComparison.isCorrect(userAnswerHigher: userAnsweredHigher)
    }

    let timestamp: Date

    init(pitchComparison: PitchComparison, userAnsweredHigher: Bool, tuningSystem: TuningSystem, timestamp: Date = Date()) {
        self.pitchComparison = pitchComparison
        self.userAnsweredHigher = userAnsweredHigher
        self.tuningSystem = tuningSystem
        self.timestamp = timestamp
    }
}
