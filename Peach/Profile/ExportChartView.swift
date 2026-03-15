import SwiftUI
import Charts

struct ExportChartView: View {
    let mode: TrainingMode
    let progressTimeline: ProgressTimeline
    let date: Date

    init(mode: TrainingMode, progressTimeline: ProgressTimeline, date: Date = Date()) {
        self.mode = mode
        self.progressTimeline = progressTimeline
        self.date = date
    }

    private var config: TrainingModeConfig { mode.config }

    var body: some View {
        let buckets = progressTimeline.allGranularityBuckets(for: mode)
        let ewma = progressTimeline.currentEWMA(for: mode)
        let trend = progressTimeline.trend(for: mode)
        let stddev = buckets.last?.stddev ?? 0

        VStack(alignment: .leading, spacing: 12) {
            headlineRow(ewma: ewma, stddev: stddev, trend: trend)
            chartContent(buckets: buckets)
                .frame(height: 180)
            timestampRow
            attributionRow
        }
        .padding()
        .frame(width: 390)
        .background(Color(.systemBackground))
    }

    // MARK: - Headline Row

    private func headlineRow(ewma: Double?, stddev: Double, trend: Trend?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(config.displayName)
                .font(.headline)

            Spacer()

            if let ewma {
                Text(ProgressChartView.formatEWMA(ewma))
                    .font(.title2.bold())
                Text(ProgressChartView.formatStdDev(stddev))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let trend {
                Image(systemName: ProgressChartView.trendSymbol(trend))
                    .foregroundStyle(ProgressChartView.trendColor(trend))
            }
        }
    }

    // MARK: - Chart

    private func chartContent(buckets: [TimeBucket]) -> some View {
        let yDomain = ProgressChartView.yDomain(for: buckets)
        let separatorData = ProgressChartView.zoneSeparatorData(for: buckets)
        let labels = ProgressChartView.yearLabels(for: buckets)

        return Chart {
            zoneBackgrounds(separatorData: separatorData, yDomain: yDomain)
            zoneDividers(separatorData: separatorData)
            stddevBand(buckets: buckets)
            ewmaLine(buckets: buckets)
            sessionDots(buckets: buckets)

            RuleMark(y: .value("Baseline", config.optimalBaseline.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .foregroundStyle(.green.opacity(0.6))
        }
        .chartXScale(domain: -0.5...Double(buckets.count) - 0.5)
        .chartYScale(domain: yDomain)
        .chartYAxisLabel(config.unitLabel)
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                if let idx = value.as(Double.self), idx >= 0, Int(idx) < buckets.count {
                    let bucket = buckets[Int(idx)]
                    AxisGridLine()
                    AxisValueLabel {
                        Text(ProgressChartView.formatAxisLabel(
                            bucket.periodStart,
                            size: bucket.bucketSize,
                            index: Int(idx),
                            buckets: buckets
                        ))
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotAreaFrame = proxy.plotFrame {
                    let plotFrame = geometry[plotAreaFrame]

                    ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                        if let xFirst = proxy.position(forX: Double(label.firstIndex)),
                           let xLast = proxy.position(forX: Double(label.lastIndex)) {
                            Text(String(label.year))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .position(
                                    x: plotFrame.origin.x + (xFirst + xLast) / 2.0,
                                    y: geometry.size.height + 8
                                )
                        }
                    }
                }
            }
        }
        .padding(.bottom, labels.isEmpty ? 0 : 16)
    }

    // MARK: - Chart Content Layers

    private func zoneBackgrounds(separatorData: ProgressChartView.ZoneSeparatorData, yDomain: ClosedRange<Double>) -> some ChartContent {
        ForEach(Array(separatorData.zones.enumerated()), id: \.offset) { _, zone in
            RectangleMark(
                xStart: .value("ZS", Double(zone.startIndex) - 0.5),
                xEnd: .value("ZE", Double(zone.endIndex) + 0.5),
                yStart: .value("Y0", yDomain.lowerBound),
                yEnd: .value("Y1", yDomain.upperBound)
            )
            .foregroundStyle(zoneTint(for: zone.bucketSize).opacity(0.06))
        }
    }

    private func zoneDividers(separatorData: ProgressChartView.ZoneSeparatorData) -> some ChartContent {
        ForEach(separatorData.dividerIndices, id: \.self) { idx in
            RuleMark(x: .value("Div", Double(idx) - 0.5))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(.secondary)
        }
    }

    private func stddevBand(buckets: [TimeBucket]) -> some ChartContent {
        ForEach(ProgressChartView.lineDataWithSessionBridge(for: buckets), id: \.position) { point in
            AreaMark(
                x: .value("Index", point.position),
                yStart: .value("Low", max(0, point.mean - point.stddev)),
                yEnd: .value("High", point.mean + point.stddev)
            )
            .foregroundStyle(.blue.opacity(0.15))
        }
    }

    private func ewmaLine(buckets: [TimeBucket]) -> some ChartContent {
        ForEach(ProgressChartView.lineDataWithSessionBridge(for: buckets), id: \.position) { point in
            LineMark(
                x: .value("Index", point.position),
                y: .value("EWMA", point.mean)
            )
            .foregroundStyle(.blue)
        }
    }

    private func sessionDots(buckets: [TimeBucket]) -> some ChartContent {
        ForEach(Array(buckets.enumerated()), id: \.element.periodStart) { i, bucket in
            if bucket.bucketSize == .session {
                PointMark(
                    x: .value("Index", Double(i)),
                    y: .value("Value", bucket.mean)
                )
                .foregroundStyle(.blue)
                .symbolSize(20)
            }
        }
    }

    private func zoneTint(for bucketSize: BucketSize) -> Color {
        switch bucketSize {
        case .month: Color(.systemBackground)
        case .day: Color(.secondarySystemBackground)
        case .session: Color(.systemBackground)
        }
    }

    // MARK: - Timestamp & Attribution

    private var timestampRow: some View {
        Text(date.formatted(.dateTime.day().month(.wide).year().hour().minute()))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var attributionRow: some View {
        HStack {
            Spacer()
            Text("Peach")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
