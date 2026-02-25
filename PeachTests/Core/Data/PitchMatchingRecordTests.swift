import Testing
import SwiftData
import Foundation
@testable import Peach

@Suite("PitchMatchingRecord Tests")
struct PitchMatchingRecordTests {

    // MARK: - Test Helpers

    private func makeTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: PitchMatchingRecord.self, configurations: config)
    }

    // MARK: - Field Storage Tests

    @Test("Stores all fields correctly")
    func storesAllFields() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let timestamp = Date()
        let record = PitchMatchingRecord(
            referenceNote: 69,
            initialCentOffset: 42.5,
            userCentError: -12.3,
            timestamp: timestamp
        )

        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<PitchMatchingRecord>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched[0].referenceNote == 69)
        #expect(fetched[0].initialCentOffset == 42.5)
        #expect(fetched[0].userCentError == -12.3)
        #expect(abs(fetched[0].timestamp.timeIntervalSince(timestamp)) < 0.001)
    }

    @Test("Default timestamp is populated")
    func defaultTimestamp() async throws {
        let before = Date()
        let record = PitchMatchingRecord(
            referenceNote: 60,
            initialCentOffset: 10.0,
            userCentError: 5.0
        )
        let after = Date()

        #expect(record.timestamp >= before)
        #expect(record.timestamp <= after)
    }

    @Test("All fields intact after save and fetch")
    func allFieldsIntactAfterSaveAndFetch() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let timestamp = Date()
        let record = PitchMatchingRecord(
            referenceNote: 127,
            initialCentOffset: -99.9,
            userCentError: 88.7,
            timestamp: timestamp
        )

        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<PitchMatchingRecord>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        let retrieved = fetched[0]
        #expect(retrieved.referenceNote == 127)
        #expect(retrieved.initialCentOffset == -99.9)
        #expect(retrieved.userCentError == 88.7)
        #expect(abs(retrieved.timestamp.timeIntervalSince(timestamp)) < 0.001)
    }

    @Test("Stores positive and negative cent errors")
    func storesSignedValues() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let sharpRecord = PitchMatchingRecord(
            referenceNote: 60,
            initialCentOffset: 50.0,
            userCentError: 15.2
        )
        let flatRecord = PitchMatchingRecord(
            referenceNote: 60,
            initialCentOffset: -50.0,
            userCentError: -15.2
        )

        context.insert(sharpRecord)
        context.insert(flatRecord)
        try context.save()

        let descriptor = FetchDescriptor<PitchMatchingRecord>(
            sortBy: [SortDescriptor(\.userCentError, order: .forward)]
        )
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 2)
        #expect(fetched[0].userCentError == -15.2)
        #expect(fetched[1].userCentError == 15.2)
    }
}
