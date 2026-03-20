import SwiftData
import Foundation

@Model
final class RhythmComparisonRecord {
    var tempoBPM: Int

    /// Signed offset in milliseconds: negative = early, positive = late
    var offsetMs: Double

    var isCorrect: Bool
    var timestamp: Date

    init(tempoBPM: Int, offsetMs: Double, isCorrect: Bool, timestamp: Date = Date()) {
        self.tempoBPM = tempoBPM
        self.offsetMs = offsetMs
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}
