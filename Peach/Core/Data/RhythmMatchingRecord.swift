import SwiftData
import Foundation

@Model
final class RhythmMatchingRecord {
    var tempoBPM: Int
    var userOffsetMs: Double
    var timestamp: Date

    // Future: inputMethod property for non-tap input methods

    init(tempoBPM: Int, userOffsetMs: Double, timestamp: Date = Date()) {
        self.tempoBPM = tempoBPM
        self.userOffsetMs = userOffsetMs
        self.timestamp = timestamp
    }
}
