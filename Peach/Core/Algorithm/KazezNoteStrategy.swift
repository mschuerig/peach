import Foundation
import OSLog

final class KazezNoteStrategy: NextComparisonStrategy {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.peach.app", category: "KazezNoteStrategy")

    // MARK: - Initialization

    init() {
        logger.info("KazezNoteStrategy initialized")
    }

    // MARK: - NextComparisonStrategy Protocol

    func nextComparison(
        profile: PitchDiscriminationProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?,
        interval: DirectedInterval
    ) -> Comparison {
        let magnitude: Double

        let difficultyRange = settings.minCentDifference.rawValue...settings.maxCentDifference.rawValue

        if let last = lastComparison {
            let p = last.comparison.targetNote.offset.magnitude
            magnitude = last.isCorrect
                ? kazezNarrow(p: p).clamped(to: difficultyRange)
                : kazezWiden(p: p).clamped(to: difficultyRange)
        } else if let profileMean = profile.overallMean {
            magnitude = profileMean.clamped(to: difficultyRange)
        } else {
            magnitude = settings.maxCentDifference.rawValue
        }

        let signed = Bool.random() ? magnitude : -magnitude

        let minNote: MIDINote
        let maxNote: MIDINote
        if interval.direction == .up {
            minNote = settings.noteRange.lowerBound
            maxNote = MIDINote(min(settings.noteRange.upperBound.rawValue, 127 - interval.interval.semitones))
        } else {
            minNote = MIDINote(max(settings.noteRange.lowerBound.rawValue, interval.interval.semitones))
            maxNote = settings.noteRange.upperBound
        }
        let note = MIDINote.random(in: minNote...maxNote)
        let targetBaseNote = note.transposed(by: interval)

        logger.info("note=\(note.rawValue), interval=\(interval.interval.semitones), target=\(targetBaseNote.rawValue), offset=\(magnitude, format: .fixed(precision: 1))")

        return Comparison(
            referenceNote: note,
            targetNote: DetunedMIDINote(note: targetBaseNote, offset: Cents(signed))
        )
    }

    // MARK: - Kazez Formulas

    private func kazezNarrow(p: Double) -> Double {
        p * (1.0 - 0.05 * p.squareRoot())
    }

    private func kazezWiden(p: Double) -> Double {
        p * (1.0 + 0.09 * p.squareRoot())
    }
}
