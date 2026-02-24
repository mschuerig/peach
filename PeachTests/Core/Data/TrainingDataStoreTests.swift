import Testing
import SwiftData
import Foundation
@testable import Peach

/// Core CRUD and persistence tests for TrainingDataStore
@Suite("TrainingDataStore Tests")
struct TrainingDataStoreTests {

    // MARK: - Test Helpers

    private func makeTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ComparisonRecord.self, configurations: config)
    }

    private func makeFileBasedContainer() throws -> ModelContainer {
        let tempDir = FileManager.default.temporaryDirectory
        let config = ModelConfiguration(url: tempDir.appendingPathComponent("test-\(UUID().uuidString).store"))
        return try ModelContainer(for: ComparisonRecord.self, configurations: config)
    }

    // MARK: - Save and Fetch Tests

    @Test("Save and retrieve a single record")
    func saveAndRetrieveSingleRecord() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let record = ComparisonRecord(
            note1: 60,
            note2: 60,
            note2CentOffset: 50.0,
            isCorrect: true,
            timestamp: Date()
        )

        try store.save(record)

        let fetched = try store.fetchAll()

        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 60)
        #expect(fetched[0].note2 == 60)
        #expect(fetched[0].note2CentOffset == 50.0)
        #expect(fetched[0].isCorrect == true)
    }

    @Test("FetchAll returns multiple records in timestamp order")
    func fetchMultipleRecordsInOrder() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let now = Date()
        let record1 = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true, timestamp: now.addingTimeInterval(-60))
        let record2 = ComparisonRecord(note1: 62, note2: 62, note2CentOffset: 20.0, isCorrect: false, timestamp: now.addingTimeInterval(-30))
        let record3 = ComparisonRecord(note1: 64, note2: 64, note2CentOffset: 30.0, isCorrect: true, timestamp: now)

        try store.save(record1)
        try store.save(record2)
        try store.save(record3)

        let fetched = try store.fetchAll()

        #expect(fetched.count == 3)
        #expect(fetched[0].note1 == 60)
        #expect(fetched[1].note1 == 62)
        #expect(fetched[2].note1 == 64)
    }

    @Test("All fields remain intact after save and retrieval")
    func allFieldsIntact() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let timestamp = Date()
        let record = ComparisonRecord(
            note1: 72,
            note2: 72,
            note2CentOffset: 123.45,
            isCorrect: false,
            timestamp: timestamp
        )

        try store.save(record)

        let fetched = try store.fetchAll()

        #expect(fetched.count == 1)
        let retrieved = fetched[0]
        #expect(retrieved.note1 == 72)
        #expect(retrieved.note2 == 72)
        #expect(retrieved.note2CentOffset == 123.45)
        #expect(retrieved.isCorrect == false)
        #expect(abs(retrieved.timestamp.timeIntervalSince(timestamp)) < 0.001)
    }

    // MARK: - Delete Tests

    @Test("Delete removes record")
    func deleteRecord() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        try store.save(record)

        var fetched = try store.fetchAll()
        #expect(fetched.count == 1)

        try store.delete(record)

        fetched = try store.fetchAll()
        #expect(fetched.isEmpty)
    }

    @Test("Delete only removes specified record")
    func deleteSpecificRecord() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let record1 = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        let record2 = ComparisonRecord(note1: 62, note2: 62, note2CentOffset: 20.0, isCorrect: false)
        try store.save(record1)
        try store.save(record2)

        try store.delete(record1)

        let fetched = try store.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 62)
    }

    // MARK: - Persistence Tests

    @Test("Records persist across context recreation (simulated restart)")
    func persistenceAcrossRestart() async throws {
        let container = try makeFileBasedContainer()

        do {
            let context1 = ModelContext(container)
            let store1 = TrainingDataStore(modelContext: context1)

            let record = ComparisonRecord(
                note1: 69,
                note2: 69,
                note2CentOffset: 75.0,
                isCorrect: true
            )
            try store1.save(record)
        }

        let context2 = ModelContext(container)
        let store2 = TrainingDataStore(modelContext: context2)

        let fetched = try store2.fetchAll()

        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 69)
        #expect(fetched[0].note2CentOffset == 75.0)
    }

    // MARK: - Atomic Write Tests

    @Test("Atomic write behavior - successful save is complete")
    func atomicWriteSuccess() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        try store.save(record)

        let fetched = try store.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 60)
        #expect(fetched[0].note2 == 60)
        #expect(fetched[0].note2CentOffset == 10.0)
        #expect(fetched[0].isCorrect == true)
    }

    // MARK: - Empty Store Tests

    @Test("FetchAll returns empty array when no records exist")
    func fetchFromEmptyStore() async throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        let fetched = try store.fetchAll()

        #expect(fetched.isEmpty)
    }
}
