import SwiftUI

/// Displays mean detection threshold, standard deviation, and trend indicator
/// Data is derived from PerceptualProfile (mean/stdDev) and TrendAnalyzer (trend)
struct SummaryStatisticsView: View {
    @Environment(\.perceptualProfile) private var profile
    @Environment(\.trendAnalyzer) private var trendAnalyzer

    private let midiRange: ClosedRange<Int>

    init(midiRange: ClosedRange<Int> = 36...84) {
        self.midiRange = midiRange
    }

    var body: some View {
        let stats = Self.computeStats(from: profile, midiRange: midiRange)

        HStack(spacing: 24) {
            statItem(
                label: "Mean",
                value: Self.formatMean(stats?.mean)
            )
            .accessibilityLabel(Self.accessibilityMean(stats?.mean))

            statItem(
                label: "Std Dev",
                value: Self.formatStdDev(stats?.stdDev)
            )
            .accessibilityLabel(Self.accessibilityStdDev(stats?.stdDev))

            if let trend = trendAnalyzer.trend {
                trendItem(trend: trend)
                    .accessibilityLabel(Self.accessibilityTrend(trend))
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: stats == nil ? .ignore : .contain)
        .accessibilityLabel(stats == nil ? "No training data yet" : "")
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func trendItem(trend: Trend) -> some View {
        VStack(spacing: 2) {
            Image(systemName: Self.trendSymbol(trend))
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Trend")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Trend Display

    /// SF Symbol name for each trend direction
    /// Down-right = improving (threshold going down is good)
    /// Right = stable
    /// Up-right = declining (threshold going up is bad)
    static func trendSymbol(_ trend: Trend) -> String {
        switch trend {
        case .improving: "arrow.down.right"
        case .stable: "arrow.right"
        case .declining: "arrow.up.right"
        }
    }

    // MARK: - Statistics Computation

    struct Stats {
        let mean: Double
        let stdDev: Double?
    }

    /// Computes display statistics from the profile using absolute per-note means
    /// Returns nil if no trained notes exist (cold start)
    @MainActor
    static func computeStats(from profile: PerceptualProfile, midiRange: ClosedRange<Int>) -> Stats? {
        let trainedNotes = midiRange.filter { profile.statsForNote($0).isTrained }
        guard !trainedNotes.isEmpty else { return nil }

        let absMeans = trainedNotes.map { abs(profile.statsForNote($0).mean) }
        let mean = absMeans.reduce(0.0, +) / Double(absMeans.count)

        let stdDev: Double?
        if absMeans.count >= 2 {
            let variance = absMeans.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(absMeans.count - 1)
            stdDev = sqrt(variance)
        } else {
            stdDev = nil
        }

        return Stats(mean: mean, stdDev: stdDev)
    }

    // MARK: - Formatting

    static func formatMean(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded())) cents"
    }

    static func formatMean(_ value: Double) -> String {
        formatMean(Optional(value))
    }

    static func formatStdDev(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "±\(Int(value.rounded())) cents"
    }

    static func formatStdDev(_ value: Double) -> String {
        formatStdDev(Optional(value))
    }

    // MARK: - Accessibility

    static func accessibilityMean(_ value: Double?) -> String {
        guard let value else { return "No training data yet" }
        return "Mean detection threshold: \(Int(value.rounded())) cents"
    }

    static func accessibilityStdDev(_ value: Double?) -> String {
        guard let value else { return "" }
        return "Standard deviation: \(Int(value.rounded())) cents"
    }

    static func accessibilityTrend(_ trend: Trend) -> String {
        switch trend {
        case .improving: "Trend: improving"
        case .stable: "Trend: stable"
        case .declining: "Trend: declining"
        }
    }
}

#Preview("With Data") {
    SummaryStatisticsView()
        .environment(\.perceptualProfile, {
            let p = PerceptualProfile()
            for note in stride(from: 36, through: 84, by: 3) {
                let threshold = Double.random(in: 10...80)
                p.update(note: note, centOffset: threshold, isCorrect: true)
            }
            return p
        }())
}

#Preview("Cold Start") {
    SummaryStatisticsView()
}
