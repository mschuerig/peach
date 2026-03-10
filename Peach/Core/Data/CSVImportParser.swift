import Foundation

nonisolated enum CSVImportParser {

    struct ImportResult {
        var pitchComparisons: [PitchComparisonRecord]
        var pitchMatchings: [PitchMatchingRecord]
        var errors: [CSVImportError]
    }

    private static let parsers: [any CSVVersionedParser] = [CSVImportParserV1()]

    static func parse(_ csvContent: String) -> ImportResult {
        let versionResult = CSVFormatVersionReader.readVersion(from: csvContent)

        switch versionResult {
        case .error(let error):
            return ImportResult(pitchComparisons: [], pitchMatchings: [], errors: [error])

        case .success(let version, let remainingLines):
            guard let parser = parsers.first(where: { $0.supportedVersion == version }) else {
                return ImportResult(pitchComparisons: [], pitchMatchings: [], errors: [.unsupportedVersion(version: version)])
            }
            return parser.parse(lines: remainingLines)
        }
    }
}
