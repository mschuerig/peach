import Foundation

struct CompletedPitchMatching {
    let referenceNote: Int
    let initialCentOffset: Double
    let userCentError: Double
    let timestamp: Date

    init(referenceNote: Int, initialCentOffset: Double, userCentError: Double, timestamp: Date = Date()) {
        self.referenceNote = referenceNote
        self.initialCentOffset = initialCentOffset
        self.userCentError = userCentError
        self.timestamp = timestamp
    }
}
