import SwiftData
import Foundation

@Model
final class PitchMatchingRecord {
    var referenceNote: Int
    var targetNote: Int
    var initialCentOffset: Double
    var userCentError: Double
    var interval: Int
    var tuningSystem: String
    var timestamp: Date

    init(referenceNote: Int, targetNote: Int, initialCentOffset: Double, userCentError: Double, interval: Int, tuningSystem: String, timestamp: Date = Date()) {
        self.referenceNote = referenceNote
        self.targetNote = targetNote
        self.initialCentOffset = initialCentOffset
        self.userCentError = userCentError
        self.interval = interval
        self.tuningSystem = tuningSystem
        self.timestamp = timestamp
    }
}
