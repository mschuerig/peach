import Foundation

nonisolated enum CSVExportSchema {

    // MARK: - Column Names (Task 1.1)

    static let columnTrainingType = "trainingType"
    static let columnTimestamp = "timestamp"
    static let columnReferenceNote = "referenceNote"
    static let columnReferenceNoteName = "referenceNoteName"
    static let columnTargetNote = "targetNote"
    static let columnTargetNoteName = "targetNoteName"
    static let columnInterval = "interval"
    static let columnTuningSystem = "tuningSystem"
    static let columnCentOffset = "centOffset"
    static let columnIsCorrect = "isCorrect"
    static let columnInitialCentOffset = "initialCentOffset"
    static let columnUserCentError = "userCentError"

    // MARK: - Training Type (Task 1.2)

    enum TrainingType: Sendable {
        case comparison
        case pitchMatching

        var csvValue: String {
            switch self {
            case .comparison: "comparison"
            case .pitchMatching: "pitchMatching"
            }
        }
    }

    // MARK: - Header Row (Task 1.3)

    static let allColumns: [String] = [
        columnTrainingType,
        columnTimestamp,
        columnReferenceNote,
        columnReferenceNoteName,
        columnTargetNote,
        columnTargetNoteName,
        columnInterval,
        columnTuningSystem,
        columnCentOffset,
        columnIsCorrect,
        columnInitialCentOffset,
        columnUserCentError,
    ]

    static let headerRow: String = allColumns.joined(separator: ",")

    // MARK: - Column Groupings (Task 1.4)

    static let commonColumns: [String] = [
        columnTrainingType,
        columnTimestamp,
        columnReferenceNote,
        columnReferenceNoteName,
        columnTargetNote,
        columnTargetNoteName,
        columnInterval,
        columnTuningSystem,
    ]

    static let comparisonColumns: [String] = [
        columnCentOffset,
        columnIsCorrect,
    ]

    static let pitchMatchingColumns: [String] = [
        columnInitialCentOffset,
        columnUserCentError,
    ]
}
