import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import Peach

@Suite("CSVDocument")
struct CSVDocumentTests {

    @Test("stores csvString property")
    func storesProperties() async {
        let doc = CSVDocument(csvString: "header\nrow")

        #expect(doc.csvString == "header\nrow")
    }

    @Test("filename follows peach-training-data-YYYY-MM-DD.csv pattern")
    func filenamePattern() async {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let expectedDate = formatter.string(from: Date())
        let expectedName = "peach-training-data-\(expectedDate).csv"

        let name = CSVDocument.exportFileName()
        #expect(name == expectedName)
    }

    @Test("readableContentTypes contains commaSeparatedText")
    func readableContentTypes() async {
        #expect(CSVDocument.readableContentTypes.contains(.commaSeparatedText))
    }

    @Test("conforms to FileDocument protocol")
    func conformsToFileDocument() async {
        let doc = CSVDocument(csvString: "test")
        let _: any FileDocument = doc
    }

    @Test("CSV data round-trips through UTF-8 encoding")
    func csvDataRoundTrips() async {
        let csvString = "col1,col2\nval1,val2\nval3,val4"
        let doc = CSVDocument(csvString: csvString)

        let data = doc.csvString.data(using: .utf8)!
        let restored = String(data: data, encoding: .utf8)

        #expect(restored == csvString)
    }
}
