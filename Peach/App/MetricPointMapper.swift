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

        for mode in TrainingMode.allCases {
            switch mode {
            case .unisonPitchComparison:
                result[mode] = correctComparisons
                    .filter { $0.interval == 0 }
                    .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.centOffset)) }
            case .intervalPitchComparison:
                result[mode] = correctComparisons
                    .filter { $0.interval != 0 }
                    .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.centOffset)) }
            case .unisonMatching:
                result[mode] = pitchMatchingRecords
                    .filter { $0.interval == 0 }
                    .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.userCentError)) }
            case .intervalMatching:
                result[mode] = pitchMatchingRecords
                    .filter { $0.interval != 0 }
                    .map { MetricPoint(timestamp: $0.timestamp, value: abs($0.userCentError)) }
            }
        }

        return result
    }
}
