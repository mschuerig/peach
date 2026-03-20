import Testing
import SwiftData
import Foundation
@testable import Peach

@Suite("RhythmMatchingRecord Tests")
struct RhythmMatchingRecordTests {

    // MARK: - Test Helpers

    private func makeTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: RhythmMatchingRecord.self, configurations: config)
    }

    // MARK: - Field Storage Tests

    @Test("Stores all fields correctly")
    func storesAllFields() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let timestamp = Date()
        let record = RhythmMatchingRecord(
            tempoBPM: 120,
            expectedOffsetMs: 0.0,
            userOffsetMs: -12.5,
            timestamp: timestamp
        )

        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<RhythmMatchingRecord>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched[0].tempoBPM == 120)
        #expect(fetched[0].expectedOffsetMs == 0.0)
        #expect(fetched[0].userOffsetMs == -12.5)
        #expect(abs(fetched[0].timestamp.timeIntervalSince(timestamp)) < 0.001)
    }

    @Test("Default timestamp is populated")
    func defaultTimestamp() async throws {
        let before = Date()
        let record = RhythmMatchingRecord(
            tempoBPM: 90,
            expectedOffsetMs: 0.0,
            userOffsetMs: 3.2
        )
        let after = Date()

        #expect(record.timestamp >= before)
        #expect(record.timestamp <= after)
    }

    @Test("Stores positive and negative user offsets")
    func storesSignedValues() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let earlyRecord = RhythmMatchingRecord(
            tempoBPM: 100,
            expectedOffsetMs: 0.0,
            userOffsetMs: -18.9
        )
        let lateRecord = RhythmMatchingRecord(
            tempoBPM: 100,
            expectedOffsetMs: 0.0,
            userOffsetMs: 22.1
        )

        context.insert(earlyRecord)
        context.insert(lateRecord)
        try context.save()

        let descriptor = FetchDescriptor<RhythmMatchingRecord>(
            sortBy: [SortDescriptor(\.userOffsetMs, order: .forward)]
        )
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 2)
        #expect(fetched[0].userOffsetMs == -18.9)
        #expect(fetched[1].userOffsetMs == 22.1)
    }

    @Test("All fields intact after save and fetch")
    func allFieldsIntactAfterSaveAndFetch() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let timestamp = Date()
        let record = RhythmMatchingRecord(
            tempoBPM: 60,
            expectedOffsetMs: 0.0,
            userOffsetMs: -0.1,
            timestamp: timestamp
        )

        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<RhythmMatchingRecord>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        let retrieved = fetched[0]
        #expect(retrieved.tempoBPM == 60)
        #expect(retrieved.expectedOffsetMs == 0.0)
        #expect(retrieved.userOffsetMs == -0.1)
        #expect(abs(retrieved.timestamp.timeIntervalSince(timestamp)) < 0.001)
    }
}
