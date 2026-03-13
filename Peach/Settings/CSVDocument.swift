import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    let csvString: String

    init(csvString: String) {
        self.csvString = csvString
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        csvString = string
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = csvString.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    static func exportFileName() -> String {
        let dateString = Date().formatted(
            .iso8601.year().month().day().dateSeparator(.dash).timeSeparator(.omitted)
        )
        return "peach-training-data-\(dateString).csv"
    }
}
