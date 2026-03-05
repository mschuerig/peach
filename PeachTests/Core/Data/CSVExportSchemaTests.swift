import Testing
import Foundation
@testable import Peach

@Suite("CSVExportSchema Tests")
struct CSVExportSchemaTests {

    // MARK: - Header Row Tests (Task 3.1)

    @Test("headerRow contains all 12 column names in correct order")
    func headerRowContainsAllColumns() async {
        let header = CSVExportSchema.headerRow
        let columns = header.split(separator: ",").map(String.init)

        #expect(columns.count == 12)
        #expect(columns[0] == "trainingType")
        #expect(columns[1] == "timestamp")
        #expect(columns[2] == "referenceNote")
        #expect(columns[3] == "referenceNoteName")
        #expect(columns[4] == "targetNote")
        #expect(columns[5] == "targetNoteName")
        #expect(columns[6] == "interval")
        #expect(columns[7] == "tuningSystem")
        #expect(columns[8] == "centOffset")
        #expect(columns[9] == "isCorrect")
        #expect(columns[10] == "initialCentOffset")
        #expect(columns[11] == "userCentError")
    }

    // MARK: - TrainingType Tests (Task 1.2)

    @Test("TrainingType comparison has csvValue 'comparison'")
    func comparisonCsvValue() async {
        #expect(CSVExportSchema.TrainingType.pitchComparison.csvValue == "pitchComparison")
    }

    @Test("TrainingType pitchMatching has csvValue 'pitchMatching'")
    func pitchMatchingCsvValue() async {
        #expect(CSVExportSchema.TrainingType.pitchMatching.csvValue == "pitchMatching")
    }

    // MARK: - Column Grouping Tests (Task 1.4)

    @Test("commonColumns lists all 8 common columns")
    func commonColumnsCount() async {
        let common = CSVExportSchema.commonColumns
        #expect(common.count == 8)
        #expect(common.contains("trainingType"))
        #expect(common.contains("timestamp"))
        #expect(common.contains("referenceNote"))
        #expect(common.contains("referenceNoteName"))
        #expect(common.contains("targetNote"))
        #expect(common.contains("targetNoteName"))
        #expect(common.contains("interval"))
        #expect(common.contains("tuningSystem"))
    }

    @Test("pitchComparisonColumns lists comparison-specific columns")
    func pitchComparisonColumns() async {
        let columns = CSVExportSchema.pitchComparisonColumns
        #expect(columns.count == 2)
        #expect(columns.contains("centOffset"))
        #expect(columns.contains("isCorrect"))
    }

    @Test("pitchMatchingColumns lists pitch-matching-specific columns")
    func pitchMatchingColumns() async {
        let columns = CSVExportSchema.pitchMatchingColumns
        #expect(columns.count == 2)
        #expect(columns.contains("initialCentOffset"))
        #expect(columns.contains("userCentError"))
    }

    // MARK: - Extensibility Tests (Task 3.8)

    @Test("adding a column after existing ones doesn't break header order")
    func extensibilityDesign() async {
        let header = CSVExportSchema.headerRow
        let columns = header.split(separator: ",").map(String.init)

        // First 8 are always common columns in fixed order
        #expect(columns[0] == "trainingType")
        #expect(columns[7] == "tuningSystem")

        // Comparison-specific are at indices 8-9
        #expect(columns[8] == "centOffset")
        #expect(columns[9] == "isCorrect")

        // Pitch-matching-specific are at indices 10-11
        #expect(columns[10] == "initialCentOffset")
        #expect(columns[11] == "userCentError")

        // New type-specific columns would go at 12+
    }
}
