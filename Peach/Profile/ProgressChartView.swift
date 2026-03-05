import SwiftUI
import Charts

struct ProgressChartView: View {
    let mode: TrainingMode

    // Tap-to-expand interaction disabled pending UX evaluation.
    // The subBuckets API and displayBuckets logic remain tested and ready.
    // Re-enable when we have a clear UX direction for drill-down.
    private static let chartExpansionEnabled = false

    @Environment(\.progressTimeline) private var progressTimeline
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var expandedBucketIndex: Int?

    private var config: TrainingModeConfig { mode.config }

    var body: some View {
        let state = progressTimeline.state(for: mode)

        switch state {
        case .noData:
            EmptyView()
        case .active:
            activeCard
        }
    }

    // MARK: - Active Card

    private var activeCard: some View {
        let baseBuckets = progressTimeline.buckets(for: mode)
        let buckets: [TimeBucket] = if Self.chartExpansionEnabled {
            Self.displayBuckets(
                from: baseBuckets,
                expandedIndex: expandedBucketIndex,
                timeline: progressTimeline,
                mode: mode
            )
        } else {
            baseBuckets
        }
        let ewma = progressTimeline.currentEWMA(for: mode)
        let trend = progressTimeline.trend(for: mode)
        let stddev = baseBuckets.last?.stddev ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            headlineRow(ewma: ewma, stddev: stddev, trend: trend)
            chart(buckets: buckets)
                .frame(height: chartHeight)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Progress chart for \(config.displayName)"))
        .accessibilityValue(Self.chartAccessibilityValue(
            ewma: ewma,
            trend: trend,
            unitLabel: config.unitLabel
        ))
    }

    // MARK: - Headline Row

    private func headlineRow(ewma: Double?, stddev: Double, trend: Trend?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(config.displayName)
                .font(.headline)

            Spacer()

            if let ewma {
                Text(Self.formatEWMA(ewma))
                    .font(.title2.bold())
                Text(Self.formatStdDev(stddev))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let trend {
                Image(systemName: Self.trendSymbol(trend))
                    .foregroundStyle(Self.trendColor(trend))
                    .accessibilityLabel(Self.trendLabel(trend))
            }
        }
    }

    // MARK: - Chart

    private func chart(buckets: [TimeBucket]) -> some View {
        let now = Date()
        let bucketSizeByDate = Dictionary(uniqueKeysWithValues: buckets.map { ($0.periodStart, $0.bucketSize) })
        return Chart {
            ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                AreaMark(
                    x: .value("Time", bucket.periodStart),
                    yStart: .value("Low", max(0, bucket.mean - bucket.stddev)),
                    yEnd: .value("High", bucket.mean + bucket.stddev)
                )
                .foregroundStyle(.blue.opacity(0.15))
            }

            ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                LineMark(
                    x: .value("Time", bucket.periodStart),
                    y: .value("EWMA", bucket.mean)
                )
                .foregroundStyle(.blue)
            }

            RuleMark(y: .value("Baseline", config.optimalBaseline.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .foregroundStyle(.green.opacity(0.6))
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let size = bucketSizeByDate[date] ?? .day
                        Text(Self.bucketLabel(for: date, size: size, relativeTo: now))
                    }
                }
            }
        }
        .chartYAxisLabel(config.unitLabel)
    }

    private var chartHeight: CGFloat {
        horizontalSizeClass == .compact ? 180 : 240
    }

    // MARK: - Expansion Helpers (gated by chartExpansionEnabled)

    static func displayBuckets(
        from baseBuckets: [TimeBucket],
        expandedIndex: Int?,
        timeline: ProgressTimeline,
        mode: TrainingMode
    ) -> [TimeBucket] {
        guard let expandedIndex,
              expandedIndex < baseBuckets.count else {
            return baseBuckets
        }
        let expandedBucket = baseBuckets[expandedIndex]
        let subs = timeline.subBuckets(for: mode, expanding: expandedBucket)
        guard !subs.isEmpty else { return baseBuckets }

        var result = baseBuckets
        result.replaceSubrange(expandedIndex...expandedIndex, with: subs)
        return result
    }

    // MARK: - Static Helpers

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    static func bucketLabel(for date: Date, size: BucketSize, relativeTo now: Date) -> String {
        switch size {
        case .session:
            return relativeFormatter.localizedString(for: date, relativeTo: now)
        case .day:
            return date.formatted(.dateTime.weekday(.abbreviated))
        case .week:
            return date.formatted(.dateTime.month(.abbreviated).day())
        case .month:
            return date.formatted(.dateTime.month(.abbreviated))
        }
    }

    static func trendSymbol(_ trend: Trend) -> String {
        switch trend {
        case .improving: "arrow.down.right"
        case .stable: "arrow.right"
        case .declining: "arrow.up.right"
        }
    }

    static func trendLabel(_ trend: Trend) -> String {
        switch trend {
        case .improving: String(localized: "Improving")
        case .stable: String(localized: "Stable")
        case .declining: String(localized: "Declining")
        }
    }

    static func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .improving: .green
        case .stable: .secondary
        case .declining: .orange
        }
    }

    static func formatEWMA(_ value: Double) -> String {
        TrainingStatsView.formattedCents(value)
    }

    static func formatStdDev(_ value: Double) -> String {
        "±\(TrainingStatsView.formattedCents(value))"
    }

    static func chartAccessibilityValue(ewma: Double?, trend: Trend?, unitLabel: String) -> String {
        var parts: [String] = []
        if let ewma {
            parts.append(String(localized: "Current: \(Self.formatEWMA(ewma)) \(unitLabel)"))
        }
        if let trend {
            parts.append(String(localized: "trend: \(trendLabel(trend))"))
        }
        return parts.joined(separator: ", ")
    }
}
