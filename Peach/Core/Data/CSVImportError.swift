import Foundation

nonisolated enum CSVImportError: Error, LocalizedError, Sendable {
    case invalidHeader(expected: String, actual: String)
    case invalidRowData(row: Int, column: String, value: String, reason: String)
    case missingVersion
    case unsupportedVersion(version: Int)
    case invalidFormatMetadata(line: String)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidHeader(let expected, let actual):
            "Invalid header: expected column '\(expected)' but found '\(actual)'"
        case .invalidRowData(let row, let column, let value, let reason):
            "Row \(row), column '\(column)': invalid value '\(value)' — \(reason)"
        case .missingVersion:
            String(
                localized: "This file does not contain format version metadata. It may have been created by an older version of Peach. Please re-export your data with the current version.",
                comment: "Error when importing a CSV file that lacks the format version metadata line"
            )
        case .unsupportedVersion(let version):
            String(
                localized: "This file uses export format version \(version), which is not supported by this version of Peach. Please update the app to import this file.",
                comment: "Error when importing a CSV file with an unrecognized format version"
            )
        case .invalidFormatMetadata(let line):
            String(
                localized: "The file contains an unreadable format metadata line: '\(line)'.",
                comment: "Error when the format metadata line in a CSV file cannot be parsed"
            )
        }
    }
}
