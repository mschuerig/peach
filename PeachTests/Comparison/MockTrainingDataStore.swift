import Foundation
@testable import Peach

final class MockTrainingDataStore: ComparisonRecordStoring, ComparisonObserver, PitchMatchingObserver {
    // MARK: - Comparison Test State Tracking

    var saveCallCount = 0
    var lastSavedRecord: ComparisonRecord?
    var savedRecords: [ComparisonRecord] = []
    var shouldThrowError = false
    var errorToThrow: DataStoreError = .saveFailed("Mock error")

    // MARK: - Observer Domain Object Tracking

    var completedComparisons: [CompletedComparison] = []
    var completedPitchMatchings: [CompletedPitchMatching] = []

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

    func fetchAllComparisons() throws -> [ComparisonRecord] {
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

    func fetchAllPitchMatchings() throws -> [PitchMatchingRecord] {
        if shouldThrowError {
            throw DataStoreError.fetchFailed("Mock error")
        }
        return savedPitchMatchingRecords
    }

    // MARK: - Test Helpers

    func reset() {
        saveCallCount = 0
        lastSavedRecord = nil
        savedRecords = []
        completedComparisons = []
        completedPitchMatchings = []
        savePitchMatchingCallCount = 0
        lastSavedPitchMatchingRecord = nil
        savedPitchMatchingRecords = []
        shouldThrowError = false
    }

    // MARK: - ComparisonObserver Protocol

    func comparisonCompleted(_ completed: CompletedComparison) {
        completedComparisons.append(completed)
        // Create record for backward compatibility with tests that check savedRecords
        let comparison = completed.comparison
        let record = ComparisonRecord(
            referenceNote: comparison.referenceNote.rawValue,
            targetNote: comparison.targetNote.note.rawValue,
            centOffset: comparison.targetNote.offset.rawValue,
            isCorrect: completed.isCorrect,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: completed.timestamp
        )
        try? save(record)
    }

    // MARK: - PitchMatchingObserver Protocol

    func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
        completedPitchMatchings.append(result)
        // Create record for backward compatibility with tests that check savedPitchMatchingRecords
        let record = PitchMatchingRecord(
            referenceNote: result.referenceNote.rawValue,
            targetNote: result.targetNote.rawValue,
            initialCentOffset: result.initialCentOffset,
            userCentError: result.userCentError,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: result.timestamp
        )
        try? save(record)
    }
}
