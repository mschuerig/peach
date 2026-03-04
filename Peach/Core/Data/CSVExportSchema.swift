nonisolated enum CSVExportSchema {

    // MARK: - Column Names

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

    // MARK: - Training Type

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

    // MARK: - Header Row

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

    // MARK: - Column Groupings

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
