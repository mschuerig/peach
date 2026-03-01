import SwiftData
import Foundation

@Model
final class ComparisonRecord {
    /// Reference note - always an exact MIDI note (0-127)
    var referenceNote: Int

    /// Target note - same MIDI note as referenceNote
    var targetNote: Int

    /// Signed cent offset applied to target note (positive = higher, negative = lower)
    /// Fractional precision with 0.1 cent resolution
    var centOffset: Double

    /// Did the user answer correctly?
    var isCorrect: Bool

    /// When the comparison was answered
    var timestamp: Date

    /// Interval between reference and target notes (stored as semitone count)
    var interval: Int

    /// Tuning system used for the comparison (stored as string identifier)
    var tuningSystem: String

    init(referenceNote: Int, targetNote: Int, centOffset: Double, isCorrect: Bool, interval: Int, tuningSystem: String, timestamp: Date = Date()) {
        self.referenceNote = referenceNote
        self.targetNote = targetNote
        self.centOffset = centOffset
        self.isCorrect = isCorrect
        self.interval = interval
        self.tuningSystem = tuningSystem
        self.timestamp = timestamp
    }
}
