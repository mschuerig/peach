import Foundation

nonisolated struct CSVImportParserV1: CSVVersionedParser {

    let supportedVersion = 1

    // MARK: - Interval Reverse Lookup

    private static let abbreviationToRawValue: [String: Int] = {
        var map: [String: Int] = [:]
        for interval in Interval.allCases {
            map[interval.abbreviation] = interval.rawValue
        }
        return map
    }()

    private static func intervalRawValue(from abbreviation: String) -> Int? {
        abbreviationToRawValue[abbreviation]
    }

    // MARK: - Parse

    func parse(lines: [String]) -> CSVImportParser.ImportResult {
        var pitchComparisons: [PitchComparisonRecord] = []
        var pitchMatchings: [PitchMatchingRecord] = []
        var errors: [CSVImportError] = []

        guard let headerLine = lines.first, !headerLine.isEmpty else {
            errors.append(.invalidHeader(expected: CSVExportSchema.headerRow, actual: "(empty)"))
            return CSVImportParser.ImportResult(pitchComparisons: pitchComparisons, pitchMatchings: pitchMatchings, errors: errors)
        }

        if let headerError = validateHeader(headerLine) {
            errors.append(headerError)
            return CSVImportParser.ImportResult(pitchComparisons: pitchComparisons, pitchMatchings: pitchMatchings, errors: errors)
        }

        let dataLines = lines.dropFirst()
        for (index, line) in dataLines.enumerated() {
            if line.isEmpty { continue }
            let rowNumber = index + 1
            switch parseRow(line, rowNumber: rowNumber) {
            case .pitchComparison(let record):
                pitchComparisons.append(record)
            case .pitchMatching(let record):
                pitchMatchings.append(record)
            case .error(let error):
                errors.append(error)
            }
        }

        return CSVImportParser.ImportResult(pitchComparisons: pitchComparisons, pitchMatchings: pitchMatchings, errors: errors)
    }

    // MARK: - Header Validation

    private func validateHeader(_ headerLine: String) -> CSVImportError? {
        let columns = Self.parseCSVLine(headerLine)
        let expected = CSVExportSchema.allColumns

        guard columns.count == expected.count else {
            return .invalidHeader(
                expected: "\(expected.count) columns",
                actual: "\(columns.count) columns"
            )
        }

        for (index, expectedColumn) in expected.enumerated() {
            if columns[index] != expectedColumn {
                return .invalidHeader(expected: expectedColumn, actual: columns[index])
            }
        }

        return nil
    }

    // MARK: - RFC 4180 CSV Line Parsing

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let char = iterator.next() {
            if inQuotes {
                if char == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else {
                            inQuotes = false
                            if next == "," {
                                fields.append(current)
                                current = ""
                            } else {
                                current.append(next)
                            }
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }

        fields.append(current)
        return fields
    }

    // MARK: - Row Parsing

    private enum RowResult {
        case pitchComparison(PitchComparisonRecord)
        case pitchMatching(PitchMatchingRecord)
        case error(CSVImportError)
    }

    private func parseRow(_ line: String, rowNumber: Int) -> RowResult {
        let fields = Self.parseCSVLine(line)
        let expectedCount = CSVExportSchema.allColumns.count

        guard fields.count == expectedCount else {
            return .error(.invalidRowData(
                row: rowNumber,
                column: "row",
                value: "\(fields.count) fields",
                reason: "expected \(expectedCount) fields"
            ))
        }

        let trainingType = fields[0]
        let timestampStr = fields[1]
        let refNoteStr = fields[2]
        let targetNoteStr = fields[4]
        let intervalStr = fields[6]
        let tuningSystemStr = fields[7]
        let centOffsetStr = fields[8]
        let isCorrectStr = fields[9]
        let initialCentOffsetStr = fields[10]
        let userCentErrorStr = fields[11]

        guard let timestamp = Self.parseISO8601(timestampStr) else {
            return .error(.invalidRowData(row: rowNumber, column: "timestamp", value: timestampStr, reason: "not a valid ISO 8601 date"))
        }

        guard let referenceNote = Int(refNoteStr), (0...127).contains(referenceNote) else {
            return .error(.invalidRowData(row: rowNumber, column: "referenceNote", value: refNoteStr, reason: "must be an integer 0-127"))
        }

        guard let targetNote = Int(targetNoteStr), (0...127).contains(targetNote) else {
            return .error(.invalidRowData(row: rowNumber, column: "targetNote", value: targetNoteStr, reason: "must be an integer 0-127"))
        }

        guard let intervalRaw = Self.intervalRawValue(from: intervalStr) else {
            return .error(.invalidRowData(row: rowNumber, column: "interval", value: intervalStr, reason: "not a valid interval abbreviation"))
        }

        guard TuningSystem(identifier: tuningSystemStr) != nil else {
            return .error(.invalidRowData(row: rowNumber, column: "tuningSystem", value: tuningSystemStr, reason: "not a valid tuning system"))
        }

        switch trainingType {
        case CSVExportSchema.TrainingType.pitchComparison.csvValue:
            guard initialCentOffsetStr.isEmpty && userCentErrorStr.isEmpty else {
                return .error(.invalidRowData(row: rowNumber, column: "initialCentOffset/userCentError", value: "\(initialCentOffsetStr),\(userCentErrorStr)", reason: "must be empty for pitchComparison rows"))
            }

            guard let centOffset = Double(centOffsetStr) else {
                return .error(.invalidRowData(row: rowNumber, column: "centOffset", value: centOffsetStr, reason: "not a valid number"))
            }

            guard isCorrectStr == "true" || isCorrectStr == "false" else {
                return .error(.invalidRowData(row: rowNumber, column: "isCorrect", value: isCorrectStr, reason: "must be 'true' or 'false'"))
            }

            let isCorrect = isCorrectStr == "true"

            let record = PitchComparisonRecord(
                referenceNote: referenceNote,
                targetNote: targetNote,
                centOffset: centOffset,
                isCorrect: isCorrect,
                interval: intervalRaw,
                tuningSystem: tuningSystemStr,
                timestamp: timestamp
            )
            return .pitchComparison(record)

        case CSVExportSchema.TrainingType.pitchMatching.csvValue:
            guard centOffsetStr.isEmpty && isCorrectStr.isEmpty else {
                return .error(.invalidRowData(row: rowNumber, column: "centOffset/isCorrect", value: "\(centOffsetStr),\(isCorrectStr)", reason: "must be empty for pitchMatching rows"))
            }

            guard let initialCentOffset = Double(initialCentOffsetStr) else {
                return .error(.invalidRowData(row: rowNumber, column: "initialCentOffset", value: initialCentOffsetStr, reason: "not a valid number"))
            }

            guard let userCentError = Double(userCentErrorStr) else {
                return .error(.invalidRowData(row: rowNumber, column: "userCentError", value: userCentErrorStr, reason: "not a valid number"))
            }

            let record = PitchMatchingRecord(
                referenceNote: referenceNote,
                targetNote: targetNote,
                initialCentOffset: initialCentOffset,
                userCentError: userCentError,
                interval: intervalRaw,
                tuningSystem: tuningSystemStr,
                timestamp: timestamp
            )
            return .pitchMatching(record)

        default:
            return .error(.invalidRowData(row: rowNumber, column: "trainingType", value: trainingType, reason: "must be 'pitchComparison' or 'pitchMatching'"))
        }
    }

    // MARK: - ISO 8601 Parsing

    private static func parseISO8601(_ string: String) -> Date? {
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(string) {
            return date
        }
        return try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string)
    }
}
