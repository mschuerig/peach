import Foundation
@testable import Peach

/// Mock ComparisonRecordStoring and ComparisonObserver for testing ComparisonSession
final class MockTrainingDataStore: ComparisonRecordStoring, ComparisonObserver {
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

    // MARK: - ComparisonObserver Protocol

    func comparisonCompleted(_ completed: CompletedComparison) {
        let comparison = completed.comparison
        let record = ComparisonRecord(
            note1: comparison.note1,
            note2: comparison.note2,
            note2CentOffset: comparison.isSecondNoteHigher ? comparison.centDifference : -comparison.centDifference,
            isCorrect: completed.isCorrect,
            timestamp: completed.timestamp
        )
        try? save(record)
    }
}
