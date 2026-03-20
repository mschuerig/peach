import SwiftData
import Foundation

@Model
final class RhythmMatchingRecord {
    var tempoBPM: Int
    var expectedOffsetMs: Double
    var userOffsetMs: Double
    var timestamp: Date

    // Future: inputMethod property for non-tap input methods

    init(tempoBPM: Int, expectedOffsetMs: Double, userOffsetMs: Double, timestamp: Date = Date()) {
        self.tempoBPM = tempoBPM
        self.expectedOffsetMs = expectedOffsetMs
        self.userOffsetMs = userOffsetMs
        self.timestamp = timestamp
    }
}
