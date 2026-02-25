import Foundation
@testable import Peach

/// Mock ComparisonRecordStoring, ComparisonObserver, and PitchMatchingObserver for testing
final class MockTrainingDataStore: ComparisonRecordStoring, ComparisonObserver, PitchMatchingObserver {
    // MARK: - Comparison Test State Tracking

    var saveCallCount = 0
    var lastSavedRecord: ComparisonRecord?
    var savedRecords: [ComparisonRecord] = []
    var shouldThrowError = false
    var errorToThrow: DataStoreError = .saveFailed("Mock error")

    // MARK: - Pitch Matching Test State Tracking

    var savePitchMatchingCallCount = 0
    var lastSavedPitchMatchingRecord: PitchMatchingRecord?
    var savedPitchMatchingRecords: [PitchMatchingRecord] = []

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

    // MARK: - Pitch Matching Methods

    func save(_ record: PitchMatchingRecord) throws {
        savePitchMatchingCallCount += 1
        lastSavedPitchMatchingRecord = record

        if shouldThrowError {
            throw errorToThrow
        }

        savedPitchMatchingRecords.append(record)
    }

    func fetchAllPitchMatching() throws -> [PitchMatchingRecord] {
        if shouldThrowError {
            throw DataStoreError.fetchFailed("Mock error")
        }
        return savedPitchMatchingRecords
    }

    func deleteAllPitchMatching() throws {
        if shouldThrowError {
            throw DataStoreError.deleteFailed("Mock error")
        }
        savedPitchMatchingRecords = []
    }

    // MARK: - Test Helpers

    func reset() {
        saveCallCount = 0
        lastSavedRecord = nil
        savedRecords = []
        savePitchMatchingCallCount = 0
        lastSavedPitchMatchingRecord = nil
        savedPitchMatchingRecords = []
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

    // MARK: - PitchMatchingObserver Protocol

    func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
        let record = PitchMatchingRecord(
            referenceNote: result.referenceNote,
            initialCentOffset: result.initialCentOffset,
            userCentError: result.userCentError,
            timestamp: result.timestamp
        )
        try? save(record)
    }
}
