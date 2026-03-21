import Foundation

/// Protocol for pitch comparison record persistence operations
///
/// This protocol enables testable dependency injection for PitchDiscriminationSession.
/// TrainingDataStore conforms to this protocol, allowing mock implementations in tests.
protocol PitchDiscriminationRecordStoring {
    /// Saves a pitch comparison record to persistent storage
    /// - Parameter record: The PitchDiscriminationRecord to save
    /// - Throws: DataStoreError.saveFailed if save operation fails
    func save(_ record: PitchDiscriminationRecord) throws

    /// Fetches all pitch comparison records from persistent storage
    /// - Returns: All PitchDiscriminationRecord instances
    /// - Throws: DataStoreError.fetchFailed if fetch operation fails
    func fetchAllPitchDiscriminations() throws -> [PitchDiscriminationRecord]
}

/// Extension to make TrainingDataStore conform to the protocol
extension TrainingDataStore: PitchDiscriminationRecordStoring {
    // TrainingDataStore already implements save() and fetchAllPitchDiscriminations()
    // This extension just declares conformance
}
