import Foundation

/// Maps storage records to domain-level metric points, keyed by training mode.
///
/// This lives in the app layer so that neither `PerceptualProfile` nor `ProgressTimeline`
/// needs to import or reference storage record types.
enum MetricPointMapper {

    /// Extracts metric points for all training modes from storage records.
    ///
    /// For comparison modes, only correct answers contribute to the profile
    /// (behavioral parity with the original PerceptualProfile).
    static func extractMetrics(
        pitchComparisonRecords: [PitchComparisonRecord],
        pitchMatchingRecords: [PitchMatchingRecord]
    ) -> [TrainingMode: [MetricPoint]] {
        let correctComparisons = pitchComparisonRecords.filter(\.isCorrect)
        var result: [TrainingMode: [MetricPoint]] = [:]

        result[.unisonPitchComparison] = correctComparisons
            .filter { $0.interval == 0 }
            .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.centOffset)) }

        result[.intervalPitchComparison] = correctComparisons
            .filter { $0.interval != 0 }
            .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.centOffset)) }

        result[.unisonMatching] = pitchMatchingRecords
            .filter { $0.interval == 0 }
            .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.userCentError)) }

        result[.intervalMatching] = pitchMatchingRecords
            .filter { $0.interval != 0 }
            .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.userCentError)) }

        return result
    }

    /// Maps a single completed pitch comparison to its training mode metric point, if applicable.
    static func metricPoint(from completed: CompletedPitchComparison) -> (mode: TrainingMode, point: MetricPoint)? {
        guard completed.isCorrect else { return nil }
        let pc = completed.pitchComparison
        let interval = (try? Interval.between(pc.referenceNote, pc.targetNote.note))?.rawValue ?? 0
        let mode: TrainingMode = interval == 0 ? .unisonPitchComparison : .intervalPitchComparison
        let point = MetricPoint(timestamp: completed.timestamp, value: pc.targetNote.offset.magnitude)
        return (mode: mode, point: point)
    }

    /// Maps a single completed pitch matching to its training mode metric point.
    static func metricPoint(from result: CompletedPitchMatching) -> (mode: TrainingMode, point: MetricPoint) {
        let interval = (try? Interval.between(result.referenceNote, result.targetNote))?.rawValue ?? 0
        let mode: TrainingMode = interval == 0 ? .unisonMatching : .intervalMatching
        let point = MetricPoint(timestamp: result.timestamp, value: result.userCentError.magnitude)
        return (mode: mode, point: point)
    }
}
