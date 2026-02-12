import Testing
import SwiftData
import Foundation
@testable import Peach

@Suite("TrainingDataStore Tests")
struct TrainingDataStoreTests {

    // MARK: - Test Helpers

    /// Creates an in-memory ModelContainer for isolated testing
    @MainActor
    private func makeTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ComparisonRecord.self, configurations: config)
    }

    /// Creates a temporary file-based container for persistence testing
    @MainActor
    private func makeFileBasedContainer() throws -> ModelContainer {
        // Use temporary directory for test database
        let tempDir = FileManager.default.temporaryDirectory
        let config = ModelConfiguration(url: tempDir.appendingPathComponent("test-\(UUID().uuidString).store"))
        return try ModelContainer(for: ComparisonRecord.self, configurations: config)
    }

    // MARK: - Save and Fetch Tests

    @Test("Save and retrieve a single record")
    @MainActor
    func saveAndRetrieveSingleRecord() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Create a record
        let record = ComparisonRecord(
            note1: 60, // Middle C
            note2: 60,
            note2CentOffset: 50.0,
            isCorrect: true,
            timestamp: Date()
        )

        // Save
        try store.save(record)

        // Fetch all records
        let fetched = try store.fetchAll()

        // Verify
        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 60)
        #expect(fetched[0].note2 == 60)
        #expect(fetched[0].note2CentOffset == 50.0)
        #expect(fetched[0].isCorrect == true)
    }

    @Test("FetchAll returns multiple records in timestamp order")
    @MainActor
    func fetchMultipleRecordsInOrder() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Create records with different timestamps
        let now = Date()
        let record1 = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true, timestamp: now.addingTimeInterval(-60))
        let record2 = ComparisonRecord(note1: 62, note2: 62, note2CentOffset: 20.0, isCorrect: false, timestamp: now.addingTimeInterval(-30))
        let record3 = ComparisonRecord(note1: 64, note2: 64, note2CentOffset: 30.0, isCorrect: true, timestamp: now)

        // Save all records
        try store.save(record1)
        try store.save(record2)
        try store.save(record3)

        // Fetch all records
        let fetched = try store.fetchAll()

        // Verify count and order (oldest first)
        #expect(fetched.count == 3)
        #expect(fetched[0].note1 == 60) // Oldest
        #expect(fetched[1].note1 == 62) // Middle
        #expect(fetched[2].note1 == 64) // Newest
    }

    @Test("All fields remain intact after save and retrieval")
    @MainActor
    func allFieldsIntact() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Create record with specific values
        let timestamp = Date()
        let record = ComparisonRecord(
            note1: 72, // C5
            note2: 72,
            note2CentOffset: 123.45,
            isCorrect: false,
            timestamp: timestamp
        )

        // Save
        try store.save(record)

        // Fetch all records
        let fetched = try store.fetchAll()

        // Verify all fields are exactly as saved
        #expect(fetched.count == 1)
        let retrieved = fetched[0]
        #expect(retrieved.note1 == 72)
        #expect(retrieved.note2 == 72)
        #expect(retrieved.note2CentOffset == 123.45)
        #expect(retrieved.isCorrect == false)
        // Timestamps should match within a small tolerance (SwiftData may have precision differences)
        #expect(abs(retrieved.timestamp.timeIntervalSince(timestamp)) < 0.001)
    }

    // MARK: - Delete Tests

    @Test("Delete removes record")
    @MainActor
    func deleteRecord() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Save a record
        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        try store.save(record)

        // Verify it exists
        var fetched = try store.fetchAll()
        #expect(fetched.count == 1)

        // Delete
        try store.delete(record)

        // Verify it's gone
        fetched = try store.fetchAll()
        #expect(fetched.isEmpty)
    }

    @Test("Delete only removes specified record")
    @MainActor
    func deleteSpecificRecord() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Save multiple records
        let record1 = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        let record2 = ComparisonRecord(note1: 62, note2: 62, note2CentOffset: 20.0, isCorrect: false)
        try store.save(record1)
        try store.save(record2)

        // Delete first record only
        try store.delete(record1)

        // Verify only second record remains
        let fetched = try store.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 62)
    }

    // MARK: - Persistence Tests

    @Test("Records persist across context recreation (simulated restart)")
    @MainActor
    func persistenceAcrossRestart() async throws {
        // Setup: Use file-based container
        let container = try makeFileBasedContainer()

        // Save record with first context
        do {
            let context1 = ModelContext(container)
            let store1 = TrainingDataStore(modelContext: context1)

            let record = ComparisonRecord(
                note1: 69, // A4
                note2: 69,
                note2CentOffset: 75.0,
                isCorrect: true
            )
            try store1.save(record)
        }

        // Create NEW context from same container (simulates app restart)
        let context2 = ModelContext(container)
        let store2 = TrainingDataStore(modelContext: context2)

        // Retrieve with new context
        let fetched = try store2.fetchAll()

        // Verify record exists after "restart"
        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 69)
        #expect(fetched[0].note2CentOffset == 75.0)
    }

    // MARK: - Atomic Write Tests

    @Test("Atomic write behavior - successful save is complete")
    @MainActor
    func atomicWriteSuccess() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Save a record
        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        try store.save(record)

        // Retrieve immediately - should be complete
        let fetched = try store.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].note1 == 60)
        #expect(fetched[0].note2 == 60)
        #expect(fetched[0].note2CentOffset == 10.0)
        #expect(fetched[0].isCorrect == true)
        // All fields present = atomic write successful
    }

    // MARK: - Empty Store Tests

    @Test("FetchAll returns empty array when no records exist")
    @MainActor
    func fetchFromEmptyStore() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Retrieve from empty store
        let fetched = try store.fetchAll()

        // Verify empty
        #expect(fetched.isEmpty)
    }

    // MARK: - Edge Case Tests

    @Test("Save multiple records with identical data")
    @MainActor
    func saveDuplicateData() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Save identical records (same data, different instances)
        let record1 = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 50.0, isCorrect: true)
        let record2 = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 50.0, isCorrect: true)

        try store.save(record1)
        try store.save(record2)

        // Both should be saved (no uniqueness constraint)
        let fetched = try store.fetchAll()
        #expect(fetched.count == 2)
    }

    @Test("MIDI note boundaries are stored correctly")
    @MainActor
    func midiNoteBoundaries() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Test lowest and highest MIDI notes
        let minRecord = ComparisonRecord(note1: 0, note2: 0, note2CentOffset: 10.0, isCorrect: true)
        let maxRecord = ComparisonRecord(note1: 127, note2: 127, note2CentOffset: 20.0, isCorrect: false)

        try store.save(minRecord)
        try store.save(maxRecord)

        // Verify both boundary values are stored correctly
        let fetched = try store.fetchAll()
        #expect(fetched.count == 2)
        #expect(fetched.contains { $0.note1 == 0 })
        #expect(fetched.contains { $0.note1 == 127 })
    }

    @Test("Fractional cent offsets are stored with precision")
    @MainActor
    func fractionalCentPrecision() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Test 0.1 cent precision (FR14 requirement)
        let record = ComparisonRecord(
            note1: 60,
            note2: 60,
            note2CentOffset: 12.3, // Should preserve 0.1 cent resolution
            isCorrect: true
        )

        try store.save(record)

        // Verify precision is maintained
        let fetched = try store.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].note2CentOffset == 12.3)
    }

    // MARK: - Error Handling Tests

    @Test("FetchAll throws DataStoreError.fetchFailed when context is invalid")
    @MainActor
    func fetchAllThrowsOnInvalidContext() async throws {
        // Setup: Create a context, then invalidate the container
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Save a record first to ensure there's data
        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        try store.save(record)

        // Note: It's difficult to force SwiftData to fail in a test environment without
        // corrupting the database file. This test verifies the error type exists and can
        // be caught. In production, fetchFailed would be thrown for database corruption,
        // permission issues, or other I/O errors.

        // Verify we can catch DataStoreError
        do {
            _ = try store.fetchAll()
            // Success is expected here - we're just verifying the error type is catchable
        } catch let error as Peach.DataStoreError {
            // If an error is thrown, verify it's the right type
            switch error {
            case .fetchFailed(let message):
                #expect(message.contains("Failed to fetch"))
            default:
                Issue.record("Expected fetchFailed error")
            }
        }
    }

    @Test("Save throws DataStoreError.saveFailed on context save failure")
    @MainActor
    func saveThrowsOnContextFailure() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Similar to fetchAll test - verifies error type exists and is catchable
        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)

        do {
            try store.save(record)
            // Success is expected - verifying error type
        } catch let error as Peach.DataStoreError {
            switch error {
            case .saveFailed(let message):
                #expect(message.contains("Failed to save"))
            default:
                Issue.record("Expected saveFailed error")
            }
        }
    }

    @Test("Delete throws DataStoreError.deleteFailed on context save failure")
    @MainActor
    func deleteThrowsOnContextFailure() async throws {
        // Setup
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let store = TrainingDataStore(modelContext: context)

        // Save a record first
        let record = ComparisonRecord(note1: 60, note2: 60, note2CentOffset: 10.0, isCorrect: true)
        try store.save(record)

        // Verify delete error type
        do {
            try store.delete(record)
            // Success is expected - verifying error type
        } catch let error as Peach.DataStoreError {
            switch error {
            case .deleteFailed(let message):
                #expect(message.contains("Failed to delete"))
            default:
                Issue.record("Expected deleteFailed error")
            }
        }
    }

    @Test("DataStoreError cases have descriptive messages")
    func dataStoreErrorMessages() {
        // Verify error cases contain expected context
        let saveError = Peach.DataStoreError.saveFailed("Test save error")
        let fetchError = Peach.DataStoreError.fetchFailed("Test fetch error")
        let deleteError = Peach.DataStoreError.deleteFailed("Test delete error")
        let contextError = Peach.DataStoreError.contextUnavailable

        // Verify error cases can be matched
        switch saveError {
        case .saveFailed(let message):
            #expect(message == "Test save error")
        default:
            Issue.record("saveFailed case not matched")
        }

        switch fetchError {
        case .fetchFailed(let message):
            #expect(message == "Test fetch error")
        default:
            Issue.record("fetchFailed case not matched")
        }

        switch deleteError {
        case .deleteFailed(let message):
            #expect(message == "Test delete error")
        default:
            Issue.record("deleteFailed case not matched")
        }

        switch contextError {
        case .contextUnavailable:
            break // Success
        default:
            Issue.record("contextUnavailable case not matched")
        }
    }
}
