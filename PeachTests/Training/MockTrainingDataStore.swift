import Foundation
@testable import Peach

/// Mock ComparisonRecordStoring for testing TrainingSession
@MainActor
final class MockTrainingDataStore: ComparisonRecordStoring {
    // MARK: - Test State Tracking

    var saveCallCount = 0
    var lastSavedRecord: ComparisonRecord?
    var savedRecords: [ComparisonRecord] = []
    var shouldThrowError = false
    var errorToThrow: DataStoreError = .saveFailed("Mock error")

    // MARK: - ComparisonRecordStoring Protocol

    func save(_ record: ComparisonRecord) throws {
        saveCallCount += 1
        lastSavedRecord = record

        if shouldThrowError {
            throw errorToThrow
        }

        savedRecords.append(record)
    }

    func fetchAll() throws -> [ComparisonRecord] {
        if shouldThrowError {
            throw DataStoreError.fetchFailed("Mock error")
        }
        return savedRecords
    }

    // MARK: - Test Helpers

    func reset() {
        saveCallCount = 0
        lastSavedRecord = nil
        savedRecords = []
        shouldThrowError = false
    }
}
