import SwiftData
import Foundation

@Model
final class ComparisonRecord {
    /// First note (reference) - always an exact MIDI note (0-127)
    var note1: Int

    /// Second note - same MIDI note as note1
    var note2: Int

    /// Signed cent offset applied to note2 (positive = higher, negative = lower)
    /// Fractional precision with 0.1 cent resolution
    var note2CentOffset: Double

    /// Did the user answer correctly?
    var isCorrect: Bool

    /// When the comparison was answered
    var timestamp: Date

    /// Creates a new comparison record
    /// - Parameters:
    ///   - note1: First MIDI note (0-127)
    ///   - note2: Second MIDI note (0-127)
    ///   - note2CentOffset: Cent difference between notes (fractional precision)
    ///   - isCorrect: Whether the user's answer was correct
    ///   - timestamp: When the comparison occurred (defaults to now)
    init(note1: Int, note2: Int, note2CentOffset: Double, isCorrect: Bool, timestamp: Date = Date()) {
        self.note1 = note1
        self.note2 = note2
        self.note2CentOffset = note2CentOffset
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}
