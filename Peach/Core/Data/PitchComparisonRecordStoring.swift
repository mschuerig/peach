import Foundation

/// Protocol for pitch comparison record persistence operations
///
/// This protocol enables testable dependency injection for PitchComparisonSession.
/// TrainingDataStore conforms to this protocol, allowing mock implementations in tests.
protocol PitchComparisonRecordStoring {
    /// Saves a pitch comparison record to persistent storage
    /// - Parameter record: The PitchComparisonRecord to save
    /// - Throws: DataStoreError.saveFailed if save operation fails
    func save(_ record: PitchComparisonRecord) throws

    /// Fetches all pitch comparison records from persistent storage
    /// - Returns: All PitchComparisonRecord instances
    /// - Throws: DataStoreError.fetchFailed if fetch operation fails
    func fetchAllPitchComparisons() throws -> [PitchComparisonRecord]
}

/// Extension to make TrainingDataStore conform to the protocol
extension TrainingDataStore: PitchComparisonRecordStoring {
    // TrainingDataStore already implements save() and fetchAllPitchComparisons()
    // This extension just declares conformance
}
