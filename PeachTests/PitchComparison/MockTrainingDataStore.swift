import Foundation
@testable import Peach

final class MockTrainingDataStore: PitchComparisonRecordStoring, PitchComparisonObserver, PitchMatchingObserver {
    // MARK: - Comparison Test State Tracking

    var saveCallCount = 0
    var lastSavedRecord: PitchComparisonRecord?
    var savedRecords: [PitchComparisonRecord] = []
    var shouldThrowError = false
    var errorToThrow: DataStoreError = .saveFailed("Mock error")

    // MARK: - Observer Domain Object Tracking

    var completedComparisons: [CompletedPitchComparison] = []
    var completedPitchMatchings: [CompletedPitchMatching] = []

    // MARK: - Pitch Matching Test State Tracking

    var savePitchMatchingCallCount = 0
    var lastSavedPitchMatchingRecord: PitchMatchingRecord?
    var savedPitchMatchingRecords: [PitchMatchingRecord] = []

    // MARK: - Test Control

    var onSaveCalled: (() -> Void)?
    var onSavePitchMatchingCalled: (() -> Void)?
    var onFetchCalled: (() -> Void)?
    var onPitchComparisonCompletedCalled: (() -> Void)?
    var onPitchMatchingCompletedCalled: (() -> Void)?

    // MARK: - PitchComparisonRecordStoring Protocol

    func save(_ record: PitchComparisonRecord) throws {
        saveCallCount += 1
        lastSavedRecord = record

        onSaveCalled?()

        if shouldThrowError {
            throw errorToThrow
        }

        savedRecords.append(record)
    }

    func fetchAllPitchComparisons() throws -> [PitchComparisonRecord] {
        onFetchCalled?()

        if shouldThrowError {
            throw DataStoreError.fetchFailed("Mock error")
        }
        return savedRecords
    }

    // MARK: - Pitch Matching Methods

    func save(_ record: PitchMatchingRecord) throws {
        savePitchMatchingCallCount += 1
        lastSavedPitchMatchingRecord = record

        onSavePitchMatchingCalled?()

        if shouldThrowError {
            throw errorToThrow
        }

        savedPitchMatchingRecords.append(record)
    }

    func fetchAllPitchMatchings() throws -> [PitchMatchingRecord] {
        onFetchCalled?()

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
        onSaveCalled = nil
        onSavePitchMatchingCalled = nil
        onFetchCalled = nil
        onPitchComparisonCompletedCalled = nil
        onPitchMatchingCompletedCalled = nil
    }

    // MARK: - PitchComparisonObserver Protocol

    func pitchComparisonCompleted(_ completed: CompletedPitchComparison) {
        onPitchComparisonCompletedCalled?()
        completedComparisons.append(completed)
        // Create record for backward compatibility with tests that check savedRecords
        let pitchComparison = completed.pitchComparison
        let record = PitchComparisonRecord(
            referenceNote: pitchComparison.referenceNote.rawValue,
            targetNote: pitchComparison.targetNote.note.rawValue,
            centOffset: pitchComparison.targetNote.offset.rawValue,
            isCorrect: completed.isCorrect,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: completed.timestamp
        )
        try? save(record)
    }

    // MARK: - PitchMatchingObserver Protocol

    func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
        onPitchMatchingCompletedCalled?()
        completedPitchMatchings.append(result)
        // Create record for backward compatibility with tests that check savedPitchMatchingRecords
        let record = PitchMatchingRecord(
            referenceNote: result.referenceNote.rawValue,
            targetNote: result.targetNote.rawValue,
            initialCentOffset: result.initialCentOffset.rawValue,
            userCentError: result.userCentError.rawValue,
            interval: 0,
            tuningSystem: "equalTemperament",
            timestamp: result.timestamp
        )
        try? save(record)
    }
}
