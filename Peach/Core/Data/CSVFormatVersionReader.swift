nonisolated enum CSVFormatVersionReader {

    enum VersionResult {
        case success(version: Int, remainingLines: [String])
        case failure(CSVImportError)
    }

    static func readVersion(from csvContent: String) -> VersionResult {
        let lines = splitIntoLines(csvContent)

        guard let firstLine = lines.first, !firstLine.isEmpty else {
            return .failure(.missingVersion)
        }

        guard firstLine.hasPrefix(CSVExportSchema.metadataPrefix) else {
            return .failure(.missingVersion)
        }

        let versionString = String(firstLine.dropFirst(CSVExportSchema.metadataPrefix.count))

        guard let version = Int(versionString) else {
            return .failure(.invalidFormatMetadata(line: firstLine))
        }

        let remainingLines = Array(lines.dropFirst())
        return .success(version: version, remainingLines: remainingLines)
    }

    // MARK: - Line Splitting (Handles Quoted Newlines)

    private static func splitIntoLines(_ content: String) -> [String] {
        var lines: [String] = []
        var current = ""
        var inQuotes = false
        var previousWasCR = false

        for scalar in content.unicodeScalars {
            if previousWasCR && scalar == "\n" && !inQuotes {
                previousWasCR = false
                continue
            }
            previousWasCR = false

            if scalar == "\"" {
                inQuotes.toggle()
                current.unicodeScalars.append(scalar)
            } else if scalar == "\r" && !inQuotes {
                lines.append(current)
                current = ""
                previousWasCR = true
            } else if scalar == "\n" && !inQuotes {
                lines.append(current)
                current = ""
            } else {
                current.unicodeScalars.append(scalar)
            }
        }

        if !current.isEmpty {
            lines.append(current)
        }

        return lines
    }
}
