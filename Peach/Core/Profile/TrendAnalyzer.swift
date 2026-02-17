import Foundation
import SwiftUI

/// Direction of user's detection threshold trend
enum Trend: Equatable {
    /// User is detecting smaller differences (threshold going down — improvement)
    case improving
    /// No significant change in detection ability
    case stable
    /// User is detecting larger differences (threshold going up — regression)
    case declining
}

/// Analyzes trend direction from chronological comparison records
///
/// Computes trend by splitting records into earlier and later halves,
/// comparing mean `abs(note2CentOffset)` between them.
/// Conforms to `ComparisonObserver` for incremental updates during training.
@Observable
@MainActor
final class TrendAnalyzer {

    /// Minimum number of records required before showing any trend
    static let minimumRecordCount = 20

    /// Percentage threshold for classifying trend (>5% change required)
    static let changeThreshold = 0.05

    /// Current computed trend direction, or nil if insufficient data
    private(set) var trend: Trend?

    /// Stored absolute cent offsets for trend computation (chronological order)
    private var absOffsets: [Double]

    /// Creates a TrendAnalyzer from existing comparison records
    /// - Parameter records: Historical records sorted by timestamp (oldest first)
    init(records: [ComparisonRecord] = []) {
        self.absOffsets = records.map { abs($0.note2CentOffset) }
        self.trend = nil
        recompute()
    }

    /// Recomputes trend from stored offsets
    private func recompute() {
        guard absOffsets.count >= Self.minimumRecordCount else {
            trend = nil
            return
        }

        let midpoint = absOffsets.count / 2
        let earlierHalf = absOffsets[..<midpoint]
        let laterHalf = absOffsets[midpoint...]

        let earlierMean = earlierHalf.reduce(0.0, +) / Double(earlierHalf.count)
        let laterMean = laterHalf.reduce(0.0, +) / Double(laterHalf.count)

        guard earlierMean > 0 else {
            trend = .stable
            return
        }

        let changeRatio = (laterMean - earlierMean) / earlierMean

        if changeRatio < -Self.changeThreshold {
            trend = .improving
        } else if changeRatio > Self.changeThreshold {
            trend = .declining
        } else {
            trend = .stable
        }
    }
}

// MARK: - ComparisonObserver Conformance

extension TrendAnalyzer: ComparisonObserver {
    func comparisonCompleted(_ completed: CompletedComparison) {
        let comparison = completed.comparison
        let centOffset = comparison.isSecondNoteHigher ? comparison.centDifference : -comparison.centDifference
        absOffsets.append(abs(centOffset))
        recompute()
    }
}

// MARK: - Environment Key

private struct TrendAnalyzerKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: TrendAnalyzer = {
        @MainActor func makeDefault() -> TrendAnalyzer {
            TrendAnalyzer()
        }
        return MainActor.assumeIsolated {
            makeDefault()
        }
    }()
}

extension EnvironmentValues {
    var trendAnalyzer: TrendAnalyzer {
        get { self[TrendAnalyzerKey.self] }
        set { self[TrendAnalyzerKey.self] = newValue }
    }
}
