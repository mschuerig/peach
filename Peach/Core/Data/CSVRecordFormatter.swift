import Foundation

enum CSVRecordFormatter {

    // MARK: - Comparison Record Formatting (Task 2.1)

    static func format(_ record: ComparisonRecord) -> String {
        let fields: [String] = [
            CSVExportSchema.TrainingType.comparison.csvValue,
            formatTimestamp(record.timestamp),
            "\(record.referenceNote)",
            formatNoteName(record.referenceNote),
            "\(record.targetNote)",
            formatNoteName(record.targetNote),
            formatInterval(record.interval),
            record.tuningSystem,
            formatDouble(record.centOffset),
            record.isCorrect ? "true" : "false",
            "",
            "",
        ]
        return fields.map { escapeField($0) }.joined(separator: ",")
    }

    // MARK: - PitchMatching Record Formatting (Task 2.2)

    static func format(_ record: PitchMatchingRecord) -> String {
        let fields: [String] = [
            CSVExportSchema.TrainingType.pitchMatching.csvValue,
            formatTimestamp(record.timestamp),
            "\(record.referenceNote)",
            formatNoteName(record.referenceNote),
            "\(record.targetNote)",
            formatNoteName(record.targetNote),
            formatInterval(record.interval),
            record.tuningSystem,
            "",
            "",
            formatDouble(record.initialCentOffset),
            formatDouble(record.userCentError),
        ]
        return fields.map { escapeField($0) }.joined(separator: ",")
    }

    // MARK: - Field Formatters

    private static func formatTimestamp(_ date: Date) -> String {
        date.formatted(.iso8601)
    }

    private static func formatNoteName(_ midiNote: Int) -> String {
        MIDINote(midiNote).name
    }

    private static func formatInterval(_ rawValue: Int) -> String {
        Interval(rawValue: rawValue)?.abbreviation ?? ""
    }

    private static func formatDouble(_ value: Double) -> String {
        let formatted = String(value)
        if formatted.contains(".") {
            return formatted
        }
        return formatted + ".0"
    }

    // MARK: - RFC 4180 Escaping (Task 2.7)

    static func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
