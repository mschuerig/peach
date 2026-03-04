import Testing
import SwiftData
import Foundation
@testable import Peach

@Suite("CSVRecordFormatter Tests")
struct CSVRecordFormatterTests {

    // MARK: - Test Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ComparisonRecord.self, PitchMatchingRecord.self,
            configurations: config
        )
    }

    private func fixedDate() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2026, month: 3, day: 3, hour: 14, minute: 30, second: 0)
        return calendar.date(from: components)!
    }

    // MARK: - ComparisonRecord Formatting (Task 3.2)

    @Test("ComparisonRecord formatting produces correct CSV row with empty pitch-matching fields")
    func formatComparisonRecord() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 60,
            targetNote: 64,
            centOffset: 15.5,
            isCorrect: true,
            interval: 4,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[0] == "comparison")
        #expect(fields[1] == "2026-03-03T14:30:00Z")
        #expect(fields[2] == "60")
        #expect(fields[3] == "C4")
        #expect(fields[4] == "64")
        #expect(fields[5] == "E4")
        #expect(fields[6] == "M3")
        #expect(fields[7] == "equalTemperament")
        #expect(fields[8] == "15.5")
        #expect(fields[9] == "true")
        #expect(fields[10] == "")
        #expect(fields[11] == "")
    }

    // MARK: - PitchMatchingRecord Formatting (Task 3.3)

    @Test("PitchMatchingRecord formatting produces correct CSV row with empty comparison fields")
    func formatPitchMatchingRecord() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = PitchMatchingRecord(
            referenceNote: 60,
            targetNote: 67,
            initialCentOffset: 25.0,
            userCentError: 3.2,
            interval: 7,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[0] == "pitchMatching")
        #expect(fields[1] == "2026-03-03T14:30:00Z")
        #expect(fields[2] == "60")
        #expect(fields[3] == "C4")
        #expect(fields[4] == "67")
        #expect(fields[5] == "G4")
        #expect(fields[6] == "P5")
        #expect(fields[7] == "equalTemperament")
        #expect(fields[8] == "")
        #expect(fields[9] == "")
        #expect(fields[10] == "25.0")
        #expect(fields[11] == "3.2")
    }

    // MARK: - Timestamp Formatting (Task 3.4)

    @Test("timestamp formatting is ISO 8601 UTC")
    func timestampFormatIsISO8601() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 60,
            targetNote: 60,
            centOffset: 0.0,
            isCorrect: true,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[1] == "2026-03-03T14:30:00Z")
    }

    // MARK: - Note Name Formatting (Task 3.5)

    @Test("note name formatting for MIDI 0 produces C-1")
    func noteNameMIDI0() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 0,
            targetNote: 0,
            centOffset: 5.0,
            isCorrect: true,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[3] == "C-1")
        #expect(fields[5] == "C-1")
    }

    @Test("note name formatting for MIDI 127 produces G9")
    func noteNameMIDI127() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 127,
            targetNote: 127,
            centOffset: 5.0,
            isCorrect: true,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[3] == "G9")
        #expect(fields[5] == "G9")
    }

    // MARK: - Interval Abbreviation Formatting (Task 3.6)

    @Test("interval abbreviation formatting for all intervals")
    func intervalAbbreviations() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let expectedAbbreviations: [(Int, String)] = [
            (0, "P1"), (1, "m2"), (2, "M2"), (3, "m3"), (4, "M3"),
            (5, "P4"), (6, "d5"), (7, "P5"), (8, "m6"), (9, "M6"),
            (10, "m7"), (11, "M7"), (12, "P8"),
        ]

        for (semitones, expectedAbbrev) in expectedAbbreviations {
            let record = ComparisonRecord(
                referenceNote: 60,
                targetNote: 60 + semitones,
                centOffset: 0.0,
                isCorrect: true,
                interval: semitones,
                tuningSystem: "equalTemperament",
                timestamp: fixedDate()
            )
            context.insert(record)
            try context.save()

            let row = CSVRecordFormatter.format(record)
            let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

            #expect(fields[6] == expectedAbbrev, "Expected \(expectedAbbrev) for semitones \(semitones), got \(fields[6])")
        }
    }

    @Test("invalid interval rawValue produces empty string")
    func invalidIntervalProducesEmpty() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 60,
            targetNote: 84,
            centOffset: 0.0,
            isCorrect: true,
            interval: 99,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[6] == "")
    }

    // MARK: - RFC 4180 Escaping (Task 3.7)

    @Test("fields containing commas are properly escaped")
    func fieldsWithCommasAreEscaped() async {
        let escaped = CSVRecordFormatter.escapeField("hello,world")
        #expect(escaped == "\"hello,world\"")
    }

    @Test("fields containing quotes are properly escaped")
    func fieldsWithQuotesAreEscaped() async {
        let escaped = CSVRecordFormatter.escapeField("say \"hello\"")
        #expect(escaped == "\"say \"\"hello\"\"\"")
    }

    @Test("fields containing newlines are properly escaped")
    func fieldsWithNewlinesAreEscaped() async {
        let escaped = CSVRecordFormatter.escapeField("line1\nline2")
        #expect(escaped == "\"line1\nline2\"")
    }

    @Test("fields without special characters are not escaped")
    func normalFieldsNotEscaped() async {
        let escaped = CSVRecordFormatter.escapeField("C#4")
        #expect(escaped == "C#4")
    }

    // MARK: - Edge Case Values

    @Test("negative cent offset formats correctly")
    func negativeCentOffset() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 69,
            targetNote: 62,
            centOffset: -8.3,
            isCorrect: false,
            interval: 7,
            tuningSystem: "justIntonation",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[0] == "comparison")
        #expect(fields[7] == "justIntonation")
        #expect(fields[8] == "-8.3")
        #expect(fields[9] == "false")
    }

    @Test("zero cent offset formats as 0.0")
    func zeroCentOffset() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record = ComparisonRecord(
            referenceNote: 60,
            targetNote: 60,
            centOffset: 0.0,
            isCorrect: true,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: fixedDate()
        )
        context.insert(record)
        try context.save()

        let row = CSVRecordFormatter.format(record)
        let fields = row.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        #expect(fields[8] == "0.0")
    }

    @Test("both tuning system identifiers format correctly")
    func tuningSystemIdentifiers() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let record1 = ComparisonRecord(
            referenceNote: 60, targetNote: 60, centOffset: 0.0, isCorrect: true,
            interval: 0, tuningSystem: "equalTemperament", timestamp: fixedDate()
        )
        let record2 = ComparisonRecord(
            referenceNote: 60, targetNote: 60, centOffset: 0.0, isCorrect: true,
            interval: 0, tuningSystem: "justIntonation", timestamp: fixedDate()
        )
        context.insert(record1)
        context.insert(record2)
        try context.save()

        let row1 = CSVRecordFormatter.format(record1)
        let row2 = CSVRecordFormatter.format(record2)

        #expect(row1.contains("equalTemperament"))
        #expect(row2.contains("justIntonation"))
    }
}
