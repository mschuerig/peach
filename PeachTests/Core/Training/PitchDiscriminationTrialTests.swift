import Foundation
import Testing
@testable import Peach

@Suite("PitchDiscriminationTrial Tests")
struct PitchDiscriminationTrialTests {

    @Test("referenceFrequency calculates valid frequency for middle C")
    func referenceFrequencyCalculatesCorrectly() async {
        let trial = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(100.0)))

        let freq = trial.referenceFrequency(tuningSystem: .equalTemperament, referencePitch: .concert440)

        #expect(freq.rawValue >= 260 && freq.rawValue <= 263)
    }

    @Test("targetFrequency applies positive cent offset (higher)")
    func targetFrequencyAppliesCentOffsetHigher() async {
        let trial = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(100.0)))

        let freq1 = trial.referenceFrequency(tuningSystem: .equalTemperament, referencePitch: .concert440)
        let freq2 = trial.targetFrequency(tuningSystem: .equalTemperament, referencePitch: .concert440)

        #expect(freq2 > freq1)

        let ratio = freq2.rawValue / freq1.rawValue
        #expect(ratio >= 1.05 && ratio <= 1.07)
    }

    @Test("targetFrequency applies negative cent offset (lower)")
    func targetFrequencyAppliesCentOffsetLower() async {
        let trial = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(-100.0)))

        let freq1 = trial.referenceFrequency(tuningSystem: .equalTemperament, referencePitch: .concert440)
        let freq2 = trial.targetFrequency(tuningSystem: .equalTemperament, referencePitch: .concert440)

        #expect(freq2 < freq1)
    }

    @Test("isTargetHigher reflects positive cent difference")
    func isTargetHigherPositiveCents() async {
        let trial = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(50.0)))
        #expect(trial.isTargetHigher == true)
    }

    @Test("isTargetHigher reflects negative cent difference")
    func isTargetHigherNegativeCents() async {
        let trial = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(-50.0)))
        #expect(trial.isTargetHigher == false)
    }

    @Test("isCorrect validates user answer against cent direction")
    func isCorrectValidatesAnswer() async {
        let higher = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(100.0)))
        let lower = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(-100.0)))

        #expect(higher.isCorrect(userAnswerHigher: true) == true)
        #expect(higher.isCorrect(userAnswerHigher: false) == false)
        #expect(lower.isCorrect(userAnswerHigher: false) == true)
        #expect(lower.isCorrect(userAnswerHigher: true) == false)
    }
}

@Suite("CompletedPitchDiscriminationTrial Tests")
struct CompletedPitchDiscriminationTrialTests {

    @Test("isCorrect delegates to discrimination logic")
    func isCorrectDelegatesToPitchDiscriminationTrial() async {
        let trial = PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(100.0)))

        let correct = CompletedPitchDiscriminationTrial(trial: trial, userAnsweredHigher: true, tuningSystem: .equalTemperament)
        let incorrect = CompletedPitchDiscriminationTrial(trial: trial, userAnsweredHigher: false, tuningSystem: .equalTemperament)

        #expect(correct.isCorrect == true)
        #expect(incorrect.isCorrect == false)
    }

    @Test("timestamp defaults to now")
    func timestampDefaultsToNow() async {
        let before = Date()
        let completed = CompletedPitchDiscriminationTrial(
            trial: PitchDiscriminationTrial(referenceNote: 60, targetNote: DetunedMIDINote(note: 60, offset: Cents(50.0))),
            userAnsweredHigher: true,
            tuningSystem: .equalTemperament
        )
        let after = Date()

        #expect(completed.timestamp >= before)
        #expect(completed.timestamp <= after)
    }
}
