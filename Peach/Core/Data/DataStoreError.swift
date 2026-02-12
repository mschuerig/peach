import Foundation

/// Errors that can occur during TrainingDataStore operations
enum DataStoreError: Error {
    /// Failed to save a record to the data store
    case saveFailed(String)

    /// Failed to fetch records from the data store
    case fetchFailed(String)

    /// Failed to delete a record from the data store
    case deleteFailed(String)

    /// ModelContext is unavailable or invalid
    case contextUnavailable
}
