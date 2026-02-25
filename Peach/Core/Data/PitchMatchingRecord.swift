import SwiftData
import Foundation

@Model
final class PitchMatchingRecord {
    var referenceNote: Int
    var initialCentOffset: Double
    var userCentError: Double
    var timestamp: Date

    init(referenceNote: Int, initialCentOffset: Double, userCentError: Double, timestamp: Date = Date()) {
        self.referenceNote = referenceNote
        self.initialCentOffset = initialCentOffset
        self.userCentError = userCentError
        self.timestamp = timestamp
    }
}
