import SwiftData
import Foundation

/// Pure persistence layer for ComparisonRecord storage and retrieval
/// Responsibilities: CREATE, READ, DELETE operations only - no business logic
@MainActor
final class TrainingDataStore {
    private let modelContext: ModelContext

    /// Creates a TrainingDataStore with the given ModelContext
    /// - Parameter modelContext: SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Saves a comparison record to persistent storage
    /// - Parameter record: The ComparisonRecord to save
    /// - Throws: DataStoreError.saveFailed if save operation fails
    func save(_ record: ComparisonRecord) throws {
        modelContext.insert(record)
        do {
            try modelContext.save()
        } catch {
            throw DataStoreError.saveFailed("Failed to save ComparisonRecord: \(error.localizedDescription)")
        }
    }

    /// Returns a sequence for iterating over all records without loading them all into memory
    /// Records are fetched in batches for memory efficiency
    ///
    /// - Important: Iteration MUST occur on the MainActor due to SwiftData's ModelContext requirement.
    ///   In practice, this is safe because iteration will happen in SwiftUI views or other MainActor-isolated
    ///   contexts. Do NOT iterate from Task.detached or other non-MainActor contexts.
    ///
    /// - Parameter batchSize: Number of records to fetch per batch (default: 100)
    /// - Returns: A sequence that yields ComparisonRecords sorted by timestamp (oldest first)
    ///
    /// Example usage:
    /// ```swift
    /// @MainActor
    /// func initializeProfile() {
    ///     for record in store.records() {
    ///         profile.process(record)
    ///     }
    /// }
    /// ```
    func records(batchSize: Int = 100) -> ComparisonRecordSequence {
        ComparisonRecordSequence(modelContext: modelContext, batchSize: batchSize)
    }

    /// Deletes a comparison record from persistent storage
    /// - Parameter record: The ComparisonRecord to delete
    /// - Throws: DataStoreError.deleteFailed if delete operation fails
    func delete(_ record: ComparisonRecord) throws {
        modelContext.delete(record)
        do {
            try modelContext.save()
        } catch {
            throw DataStoreError.deleteFailed("Failed to delete record: \(error.localizedDescription)")
        }
    }
}

// MARK: - Sequence and Iterator

/// Sequence for iterating over ComparisonRecords in batches
///
/// - Important: This sequence holds a SwiftData ModelContext, which is main-thread bound.
///   Iteration must occur on the MainActor. Created via TrainingDataStore.records()
struct ComparisonRecordSequence: Sequence {
    let modelContext: ModelContext
    let batchSize: Int

    func makeIterator() -> ComparisonRecordIterator {
        ComparisonRecordIterator(modelContext: modelContext, batchSize: batchSize)
    }
}

/// Iterator that fetches ComparisonRecords in batches to minimize memory usage
///
/// - Important: Calls modelContext.fetch() which requires MainActor.
///   Do not use this iterator from background threads.
struct ComparisonRecordIterator: IteratorProtocol {
    private let modelContext: ModelContext
    private let batchSize: Int
    private var currentBatch: [ComparisonRecord] = []
    private var currentIndex: Int = 0
    private var offset: Int = 0
    private var isExhausted: Bool = false

    init(modelContext: ModelContext, batchSize: Int) {
        self.modelContext = modelContext
        self.batchSize = batchSize
    }

    mutating func next() -> ComparisonRecord? {
        // If we've consumed current batch, fetch next batch
        if currentIndex >= currentBatch.count {
            guard !isExhausted else { return nil }

            var descriptor = FetchDescriptor<ComparisonRecord>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset

            do {
                currentBatch = try modelContext.fetch(descriptor)
                currentIndex = 0
                offset += batchSize

                if currentBatch.isEmpty {
                    isExhausted = true
                    return nil
                }
            } catch {
                isExhausted = true
                return nil
            }
        }

        let record = currentBatch[currentIndex]
        currentIndex += 1
        return record
    }
}
