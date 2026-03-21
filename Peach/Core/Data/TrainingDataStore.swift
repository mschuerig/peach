import SwiftData
import Foundation
import os

/// Pure persistence layer for PitchDiscriminationRecord and PitchMatchingRecord storage and retrieval
/// Responsibilities: CREATE, READ, DELETE operations only - no business logic
final class TrainingDataStore {
    private static let logger = Logger(subsystem: "com.peach.app", category: "TrainingDataStore")
    private let modelContext: ModelContext

    /// Creates a TrainingDataStore with the given ModelContext
    /// - Parameter modelContext: SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Saves a comparison record to persistent storage
    /// - Parameter record: The PitchDiscriminationRecord to save
    /// - Throws: DataStoreError.saveFailed if save operation fails
    func save(_ record: PitchDiscriminationRecord) throws {
        do {
            try modelContext.transaction {
                modelContext.insert(record)
            }
        } catch {
            throw DataStoreError.saveFailed("Failed to save PitchDiscriminationRecord: \(error.localizedDescription)")
        }
    }

    /// Fetches all comparison records from persistent storage
    /// - Returns: All PitchDiscriminationRecord instances sorted by timestamp (oldest first)
    /// - Throws: DataStoreError.fetchFailed if fetch operation fails
    /// - Note: Loads all records into memory at once. For MVP with expected low data volumes (hundreds to low thousands
    ///   of records), this is acceptable. Future optimization: implement batched iteration if data volume becomes large
    ///   (tens of thousands of records or memory pressure observed).
    func fetchAllPitchDiscriminations() throws -> [PitchDiscriminationRecord] {
        let descriptor = FetchDescriptor<PitchDiscriminationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataStoreError.fetchFailed("Failed to fetch records: \(error.localizedDescription)")
        }
    }

    /// Deletes a comparison record from persistent storage
    /// - Parameter record: The PitchDiscriminationRecord to delete
    /// - Throws: DataStoreError.deleteFailed if delete operation fails
    func delete(_ record: PitchDiscriminationRecord) throws {
        do {
            try modelContext.transaction {
                modelContext.delete(record)
            }
        } catch {
            throw DataStoreError.deleteFailed("Failed to delete record: \(error.localizedDescription)")
        }
    }

    /// Deletes all records from persistent storage
    /// Used by Settings "Reset All Training Data" action
    /// - Throws: DataStoreError.deleteFailed if batch delete fails; rolls back on partial failure
    func deleteAll() throws {
        do {
            try modelContext.transaction {
                try modelContext.delete(model: PitchDiscriminationRecord.self)
                try modelContext.delete(model: PitchMatchingRecord.self)
                try modelContext.delete(model: RhythmComparisonRecord.self)
                try modelContext.delete(model: RhythmMatchingRecord.self)
            }
        } catch {
            throw DataStoreError.deleteFailed("Failed to delete all records: \(error.localizedDescription)")
        }
    }

    /// Atomically replaces all records: deletes existing data and inserts new records in a single transaction.
    /// If any insert fails, the entire operation rolls back and existing data is preserved.
    /// - Parameters:
    ///   - pitchDiscriminations: Comparison records to insert
    ///   - pitchMatchings: Pitch matching records to insert
    /// - Throws: DataStoreError.saveFailed if the transaction fails
    func replaceAllRecords(
        pitchDiscriminations: [PitchDiscriminationRecord],
        pitchMatchings: [PitchMatchingRecord]
    ) throws {
        do {
            try modelContext.transaction {
                try modelContext.delete(model: PitchDiscriminationRecord.self)
                try modelContext.delete(model: PitchMatchingRecord.self)
                try modelContext.delete(model: RhythmComparisonRecord.self)
                try modelContext.delete(model: RhythmMatchingRecord.self)
                for record in pitchDiscriminations {
                    modelContext.insert(record)
                }
                for record in pitchMatchings {
                    modelContext.insert(record)
                }
            }
        } catch {
            throw DataStoreError.saveFailed("Failed to replace all records: \(error.localizedDescription)")
        }
    }

    // MARK: - Rhythm Comparison CRUD

    func save(_ record: RhythmComparisonRecord) throws {
        do {
            try modelContext.transaction {
                modelContext.insert(record)
            }
        } catch {
            throw DataStoreError.saveFailed("Failed to save RhythmComparisonRecord: \(error.localizedDescription)")
        }
    }

    func fetchAllRhythmComparisons() throws -> [RhythmComparisonRecord] {
        let descriptor = FetchDescriptor<RhythmComparisonRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataStoreError.fetchFailed("Failed to fetch rhythm comparison records: \(error.localizedDescription)")
        }
    }

    func deleteAllRhythmComparisons() throws {
        do {
            try modelContext.transaction {
                try modelContext.delete(model: RhythmComparisonRecord.self)
            }
        } catch {
            throw DataStoreError.deleteFailed("Failed to delete all rhythm comparison records: \(error.localizedDescription)")
        }
    }

    // MARK: - Rhythm Matching CRUD

    func save(_ record: RhythmMatchingRecord) throws {
        do {
            try modelContext.transaction {
                modelContext.insert(record)
            }
        } catch {
            throw DataStoreError.saveFailed("Failed to save RhythmMatchingRecord: \(error.localizedDescription)")
        }
    }

    func fetchAllRhythmMatchings() throws -> [RhythmMatchingRecord] {
        let descriptor = FetchDescriptor<RhythmMatchingRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataStoreError.fetchFailed("Failed to fetch rhythm matching records: \(error.localizedDescription)")
        }
    }

    func deleteAllRhythmMatchings() throws {
        do {
            try modelContext.transaction {
                try modelContext.delete(model: RhythmMatchingRecord.self)
            }
        } catch {
            throw DataStoreError.deleteFailed("Failed to delete all rhythm matching records: \(error.localizedDescription)")
        }
    }

    // MARK: - Pitch Matching CRUD

    /// Saves a pitch matching record to persistent storage
    /// - Parameter record: The PitchMatchingRecord to save
    /// - Throws: DataStoreError.saveFailed if save operation fails
    func save(_ record: PitchMatchingRecord) throws {
        do {
            try modelContext.transaction {
                modelContext.insert(record)
            }
        } catch {
            throw DataStoreError.saveFailed("Failed to save PitchMatchingRecord: \(error.localizedDescription)")
        }
    }

    /// Fetches all pitch matching records from persistent storage
    /// - Returns: All PitchMatchingRecord instances sorted by timestamp (oldest first)
    /// - Throws: DataStoreError.fetchFailed if fetch operation fails
    func fetchAllPitchMatchings() throws -> [PitchMatchingRecord] {
        let descriptor = FetchDescriptor<PitchMatchingRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataStoreError.fetchFailed("Failed to fetch pitch matching records: \(error.localizedDescription)")
        }
    }
}

// MARK: - Resettable Conformance

extension TrainingDataStore: Resettable {
    func reset() throws {
        try deleteAll()
    }
}

// MARK: - RhythmComparisonObserver Conformance

extension TrainingDataStore: RhythmComparisonObserver {
    func rhythmComparisonCompleted(_ result: CompletedRhythmComparison) {
        let record = RhythmComparisonRecord(
            tempoBPM: result.tempo.value,
            offsetMs: result.offset.duration / .milliseconds(1),
            isCorrect: result.isCorrect,
            timestamp: result.timestamp
        )
        do {
            try save(record)
        } catch let error as DataStoreError {
            Self.logger.warning("Rhythm comparison save error: \(error.localizedDescription)")
        } catch {
            Self.logger.warning("Rhythm comparison unexpected error: \(error.localizedDescription)")
        }
    }
}

// MARK: - RhythmMatchingObserver Conformance

extension TrainingDataStore: RhythmMatchingObserver {
    func rhythmMatchingCompleted(_ result: CompletedRhythmMatching) {
        let record = RhythmMatchingRecord(
            tempoBPM: result.tempo.value,
            userOffsetMs: result.userOffset.duration / .milliseconds(1),
            timestamp: result.timestamp
        )
        do {
            try save(record)
        } catch let error as DataStoreError {
            Self.logger.warning("Rhythm matching save error: \(error.localizedDescription)")
        } catch {
            Self.logger.warning("Rhythm matching unexpected error: \(error.localizedDescription)")
        }
    }
}

// MARK: - PitchMatchingObserver Conformance

extension TrainingDataStore: PitchMatchingObserver {
    func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
        let interval = (try? Interval.between(result.referenceNote, result.targetNote))?.rawValue ?? 0
        let record = PitchMatchingRecord(
            referenceNote: result.referenceNote.rawValue,
            targetNote: result.targetNote.rawValue,
            initialCentOffset: result.initialCentOffset.rawValue,
            userCentError: result.userCentError.rawValue,
            interval: interval,
            tuningSystem: result.tuningSystem.identifier,
            timestamp: result.timestamp
        )

        do {
            try save(record)
        } catch let error as DataStoreError {
            Self.logger.warning("Pitch matching save error: \(error.localizedDescription)")
        } catch {
            Self.logger.warning("Pitch matching unexpected error: \(error.localizedDescription)")
        }
    }
}

// MARK: - PitchDiscriminationObserver Conformance

extension TrainingDataStore: PitchDiscriminationObserver {
    /// Observes pitch comparison completion and persists the result
    /// - Parameter completed: The completed pitch comparison with user's answer and result
    func pitchDiscriminationCompleted(_ completed: CompletedPitchDiscriminationTrial) {
        let trial = completed.trial
        let interval = (try? Interval.between(trial.referenceNote, trial.targetNote.note))?.rawValue ?? 0
        let record = PitchDiscriminationRecord(
            referenceNote: trial.referenceNote.rawValue,
            targetNote: trial.targetNote.note.rawValue,
            centOffset: trial.targetNote.offset.rawValue,
            isCorrect: completed.isCorrect,
            interval: interval,
            tuningSystem: completed.tuningSystem.identifier,
            timestamp: completed.timestamp
        )

        do {
            try save(record)
        } catch let error as DataStoreError {
            // Data error - log but don't propagate (observers shouldn't fail training)
            Self.logger.warning("Pitch comparison save error: \(error.localizedDescription)")
        } catch {
            // Unexpected error - log but don't propagate
            Self.logger.warning("Pitch comparison unexpected error: \(error.localizedDescription)")
        }
    }
}
