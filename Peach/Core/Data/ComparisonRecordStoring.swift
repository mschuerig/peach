import Foundation

/// Protocol for comparison record persistence operations
///
/// This protocol enables testable dependency injection for TrainingSession.
/// TrainingDataStore conforms to this protocol, allowing mock implementations in tests.
@MainActor
protocol ComparisonRecordStoring {
    /// Saves a comparison record to persistent storage
    /// - Parameter record: The ComparisonRecord to save
    /// - Throws: DataStoreError.saveFailed if save operation fails
    func save(_ record: ComparisonRecord) throws

    /// Fetches all comparison records from persistent storage
    /// - Returns: All ComparisonRecord instances
    /// - Throws: DataStoreError.fetchFailed if fetch operation fails
    func fetchAll() throws -> [ComparisonRecord]
}

/// Extension to make TrainingDataStore conform to the protocol
extension TrainingDataStore: ComparisonRecordStoring {
    // TrainingDataStore already implements save() and fetchAll()
    // This extension just declares conformance
}
