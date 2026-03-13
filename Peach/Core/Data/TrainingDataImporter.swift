import Foundation

enum TrainingDataImporter {

    enum ImportMode {
        case replace
        case merge
    }

    struct ImportSummary {
        let pitchComparisonsImported: Int
        let pitchMatchingsImported: Int
        let pitchComparisonsSkipped: Int
        let pitchMatchingsSkipped: Int
        let parseErrorCount: Int

        var totalImported: Int { pitchComparisonsImported + pitchMatchingsImported }
        var totalSkipped: Int { pitchComparisonsSkipped + pitchMatchingsSkipped }
    }

    static func importData(
        _ parseResult: CSVImportParser.ImportResult,
        mode: ImportMode,
        into store: TrainingDataStore
    ) throws -> ImportSummary {
        switch mode {
        case .replace:
            return try replaceAll(parseResult, into: store)
        case .merge:
            return try mergeRecords(parseResult, into: store)
        }
    }

    // MARK: - Replace Mode

    private static func replaceAll(
        _ parseResult: CSVImportParser.ImportResult,
        into store: TrainingDataStore
    ) throws -> ImportSummary {
        try store.replaceAllRecords(
            pitchComparisons: parseResult.pitchComparisons,
            pitchMatchings: parseResult.pitchMatchings
        )

        return ImportSummary(
            pitchComparisonsImported: parseResult.pitchComparisons.count,
            pitchMatchingsImported: parseResult.pitchMatchings.count,
            pitchComparisonsSkipped: 0,
            pitchMatchingsSkipped: 0,
            parseErrorCount: parseResult.errors.count
        )
    }

    // MARK: - Merge Mode

    private static func mergeRecords(
        _ parseResult: CSVImportParser.ImportResult,
        into store: TrainingDataStore
    ) throws -> ImportSummary {
        let existingComparisons = try store.fetchAllPitchComparisons()
        let existingPitchMatchings = try store.fetchAllPitchMatchings()

        var existingKeys = Set<DuplicateKey>()
        for record in existingComparisons {
            existingKeys.insert(DuplicateKey(
                timestamp: record.timestamp,
                referenceNote: record.referenceNote,
                targetNote: record.targetNote,
                trainingType: TrainingType.pitchComparison
            ))
        }
        for record in existingPitchMatchings {
            existingKeys.insert(DuplicateKey(
                timestamp: record.timestamp,
                referenceNote: record.referenceNote,
                targetNote: record.targetNote,
                trainingType: TrainingType.pitchMatching
            ))
        }

        var pitchComparisonsImported = 0
        var pitchComparisonsSkipped = 0
        for record in parseResult.pitchComparisons {
            let key = DuplicateKey(
                timestamp: record.timestamp,
                referenceNote: record.referenceNote,
                targetNote: record.targetNote,
                trainingType: TrainingType.pitchComparison
            )
            if existingKeys.contains(key) {
                pitchComparisonsSkipped += 1
            } else {
                try store.save(record)
                existingKeys.insert(key)
                pitchComparisonsImported += 1
            }
        }

        var pitchMatchingsImported = 0
        var pitchMatchingsSkipped = 0
        for record in parseResult.pitchMatchings {
            let key = DuplicateKey(
                timestamp: record.timestamp,
                referenceNote: record.referenceNote,
                targetNote: record.targetNote,
                trainingType: TrainingType.pitchMatching
            )
            if existingKeys.contains(key) {
                pitchMatchingsSkipped += 1
            } else {
                try store.save(record)
                existingKeys.insert(key)
                pitchMatchingsImported += 1
            }
        }

        return ImportSummary(
            pitchComparisonsImported: pitchComparisonsImported,
            pitchMatchingsImported: pitchMatchingsImported,
            pitchComparisonsSkipped: pitchComparisonsSkipped,
            pitchMatchingsSkipped: pitchMatchingsSkipped,
            parseErrorCount: parseResult.errors.count
        )
    }

    // MARK: - Duplicate Key

    private enum TrainingType {
        static let pitchComparison = "pitchComparison"
        static let pitchMatching = "pitchMatching"
    }

    private struct DuplicateKey: Hashable {
        let timestampSeconds: Int64
        let referenceNote: Int
        let targetNote: Int
        let trainingType: String

        init(timestamp: Date, referenceNote: Int, targetNote: Int, trainingType: String) {
            self.timestampSeconds = Int64(timestamp.timeIntervalSinceReferenceDate)
            self.referenceNote = referenceNote
            self.targetNote = targetNote
            self.trainingType = trainingType
        }
    }
}
