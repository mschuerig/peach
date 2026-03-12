import SwiftUI
import Charts

struct ProgressChartView: View {
    let mode: TrainingMode

    @Environment(\.progressTimeline) private var progressTimeline
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var scrollPosition: Double = .infinity
    @State private var selectedBucketIndex: Int?

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
        let buckets = progressTimeline.allGranularityBuckets(for: mode)
        let ewma = progressTimeline.currentEWMA(for: mode)
        let trend = progressTimeline.trend(for: mode)
        let stddev = buckets.last?.stddev ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            headlineRow(ewma: ewma, stddev: stddev, trend: trend)
            chartLayout(buckets: buckets)
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

    // MARK: - Chart Layout

    @ViewBuilder
    private func chartLayout(buckets: [TimeBucket]) -> some View {
        let yDomain = Self.yDomain(for: buckets)
        let needsScrolling = buckets.count > Self.visibleBucketCount

        if needsScrolling {
            scrollableChartBody(buckets: buckets, yDomain: yDomain)
        } else {
            staticChartBody(buckets: buckets, yDomain: yDomain)
        }
    }

    private func scrollableChartBody(buckets: [TimeBucket], yDomain: ClosedRange<Double>) -> some View {
        let separatorData = Self.zoneSeparatorData(for: buckets)
        let labels = Self.yearLabels(for: buckets)

        return chartContent(
            buckets: buckets,
            yDomain: yDomain,
            separatorData: separatorData,
            yearLabels: labels
        )
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: Self.visibleBucketCount)
        .chartScrollPosition(x: $scrollPosition)
        .chartGesture { proxy in
            SpatialTapGesture()
                .onEnded { value in
                    guard let x: Double = proxy.value(atX: value.location.x) else {
                        selectedBucketIndex = nil
                        return
                    }
                    selectedBucketIndex = Self.findNearestBucketIndex(atX: x, bucketCount: buckets.count)
                }
        }
        .onChange(of: scrollPosition) { _, _ in
            selectedBucketIndex = nil
        }
        .onAppear {
            scrollPosition = Self.initialScrollPosition(for: buckets)
        }
    }

    private func staticChartBody(buckets: [TimeBucket], yDomain: ClosedRange<Double>) -> some View {
        let separatorData = Self.zoneSeparatorData(for: buckets)
        let labels = Self.yearLabels(for: buckets)
        return chartContent(
            buckets: buckets,
            yDomain: yDomain,
            separatorData: separatorData,
            yearLabels: labels
        )
        .chartGesture { proxy in
            SpatialTapGesture()
                .onEnded { value in
                    guard let x: Double = proxy.value(atX: value.location.x) else {
                        selectedBucketIndex = nil
                        return
                    }
                    selectedBucketIndex = Self.findNearestBucketIndex(atX: x, bucketCount: buckets.count)
                }
        }
    }

    private func chartContent(
        buckets: [TimeBucket],
        yDomain: ClosedRange<Double>,
        separatorData: ZoneSeparatorData,
        yearLabels: [YearLabel]
    ) -> some View {
        return Chart {
            // Layer 1: Zone background tints
            ForEach(Array(separatorData.zones.enumerated()), id: \.offset) { _, zone in
                RectangleMark(
                    xStart: .value("ZS", Double(zone.startIndex) - 0.5),
                    xEnd: .value("ZE", Double(zone.endIndex) + 0.5),
                    yStart: .value("Y0", yDomain.lowerBound),
                    yEnd: .value("Y1", yDomain.upperBound)
                )
                .foregroundStyle(Self.zoneTint(for: zone.bucketSize).opacity(0.06))
            }

            // Layer 2: Zone and year boundary divider lines
            ForEach(separatorData.dividerIndices, id: \.self) { idx in
                RuleMark(x: .value("Div", Double(idx) - 0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary)
            }

            // Layer 3: Stddev band (month + day + session bridge)
            ForEach(Self.lineDataWithSessionBridge(for: buckets), id: \.position) { point in
                AreaMark(
                    x: .value("Index", point.position),
                    yStart: .value("Low", max(0, point.mean - point.stddev)),
                    yEnd: .value("High", point.mean + point.stddev)
                )
                .foregroundStyle(.blue.opacity(0.15))
            }

            // Layer 4: EWMA line (month + day + session bridge)
            ForEach(Self.lineDataWithSessionBridge(for: buckets), id: \.position) { point in
                LineMark(
                    x: .value("Index", point.position),
                    y: .value("EWMA", point.mean)
                )
                .foregroundStyle(.blue)
            }

            // Layer 5: Session dots (disconnected, no line)
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

            // Layer 6: Baseline
            RuleMark(y: .value("Baseline", config.optimalBaseline.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .foregroundStyle(.green.opacity(0.6))

            // Layer 7: Selection indicator
            if let selectedIndex = selectedBucketIndex, selectedIndex < buckets.count {
                RuleMark(x: .value("Selected", Double(selectedIndex)))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
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
                        Text(Self.formatAxisLabel(
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
                let plotFrame = geometry[proxy.plotFrame!]

                // Selection annotation popover
                if let selectedIndex = selectedBucketIndex,
                   selectedIndex < buckets.count,
                   let xPos = proxy.position(forX: Double(selectedIndex)) {
                    let clampedX = min(max(plotFrame.origin.x + xPos, plotFrame.origin.x + 40), plotFrame.maxX - 40)
                    annotationView(for: buckets[selectedIndex])
                        .position(
                            x: clampedX,
                            y: plotFrame.origin.y - 4
                        )
                }

                // Year labels below X-axis
                ForEach(Array(yearLabels.enumerated()), id: \.offset) { _, label in
                    if let xFirst = proxy.position(forX: Double(label.firstIndex)),
                       let xLast = proxy.position(forX: Double(label.lastIndex)) {
                        Text(String(label.year))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .position(
                                x: plotFrame.origin.x + (xFirst + xLast) / 2.0,
                                y: plotFrame.maxY + Self.yearLabelYOffset
                            )
                    }
                }
            }
        }
        .padding(.bottom, yearLabels.isEmpty ? 0 : 16)
    }

    private func annotationView(for bucket: TimeBucket) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.annotationDateLabel(bucket.periodStart, size: bucket.bucketSize))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(Self.formatEWMA(bucket.mean))
                .font(.caption.bold())
            Text(Self.formatStdDev(bucket.stddev))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(localized: "\(bucket.recordCount) records"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private var chartHeight: CGFloat {
        horizontalSizeClass == .compact ? 180 : 240
    }

    // MARK: - Layout Constants

    /// Vertical offset for year labels below the X-axis.
    /// Approximation — Swift Charts does not expose axis label height.
    /// See Story 41.10 for a planned AnnotationMark-based alternative.
    private static let yearLabelYOffset: CGFloat = 28

    // MARK: - Static Helpers

    static let zoneConfigs: [BucketSize: any GranularityZoneConfig] = [
        .month: MonthlyZoneConfig(),
        .day: DailyZoneConfig(),
        .session: SessionZoneConfig(),
    ]

    // MARK: - Line Data with Session Bridge

    struct LinePoint {
        let position: Double
        let mean: Double
        let stddev: Double
    }

    static func lineDataWithSessionBridge(for buckets: [TimeBucket]) -> [LinePoint] {
        var points: [LinePoint] = []
        for (i, bucket) in buckets.enumerated() where bucket.bucketSize != .session {
            points.append(LinePoint(position: Double(i), mean: bucket.mean, stddev: bucket.stddev))
        }
        // Bridge: extend line/band to separator position (firstSessionIndex - 0.5)
        let sessionBuckets = buckets.enumerated().filter { $0.element.bucketSize == .session }
        if let first = sessionBuckets.first {
            let totalRecords = sessionBuckets.map(\.element.recordCount).reduce(0, +)
            if totalRecords > 0 {
                let mean = sessionBuckets.map { $0.element.mean * Double($0.element.recordCount) }.reduce(0, +) / Double(totalRecords)
                let weightedVariance = sessionBuckets.map { pow($0.element.stddev, 2) * Double($0.element.recordCount) }.reduce(0, +) / Double(totalRecords)
                points.append(LinePoint(position: Double(first.offset) - 0.5, mean: mean, stddev: sqrt(weightedVariance)))
            }
        }
        return points
    }

    // MARK: - Zone Separator Data

    struct ZoneInfo {
        let bucketSize: BucketSize
        let startIndex: Int
        let endIndex: Int
    }

    struct YearLabel {
        let year: Int
        let firstIndex: Int
        let lastIndex: Int
    }

    struct ZoneSeparatorData {
        let zones: [ZoneInfo]
        let dividerIndices: [Int]
    }

    static func zoneSeparatorData(for buckets: [TimeBucket]) -> ZoneSeparatorData {
        let boundaries = ChartLayoutCalculator.zoneBoundaries(for: buckets)

        guard boundaries.count > 1 else {
            return ZoneSeparatorData(zones: [], dividerIndices: [])
        }

        let zones = boundaries.map { boundary in
            ZoneInfo(
                bucketSize: boundary.bucketSize,
                startIndex: boundary.startIndex,
                endIndex: boundary.endIndex
            )
        }

        // Zone transition divider indices
        var dividerIndices = boundaries.dropFirst().map(\.startIndex)

        // Year boundary dividers within monthly zones
        let calendar = Calendar.current
        for boundary in boundaries where boundary.bucketSize == .month && boundary.endIndex > boundary.startIndex {
            for i in (boundary.startIndex + 1)...boundary.endIndex {
                let prevYear = calendar.component(.year, from: buckets[i - 1].periodStart)
                let currYear = calendar.component(.year, from: buckets[i].periodStart)
                if currYear != prevYear {
                    // Deduplicate: suppress year boundary within 1 index of a zone transition
                    let isNearZoneTransition = dividerIndices.contains { abs($0 - i) <= 1 }
                    if !isNearZoneTransition {
                        dividerIndices.append(i)
                    }
                }
            }
        }

        dividerIndices.sort()

        return ZoneSeparatorData(zones: zones, dividerIndices: dividerIndices)
    }

    static func yearLabels(for buckets: [TimeBucket]) -> [YearLabel] {
        let boundaries = ChartLayoutCalculator.zoneBoundaries(for: buckets)
        let calendar = Calendar.current
        var labels: [YearLabel] = []

        for boundary in boundaries where boundary.bucketSize == .month {
            var currentYear = calendar.component(.year, from: buckets[boundary.startIndex].periodStart)
            var spanStart = boundary.startIndex

            if boundary.endIndex > boundary.startIndex {
                for i in (boundary.startIndex + 1)...boundary.endIndex {
                    let year = calendar.component(.year, from: buckets[i].periodStart)
                    if year != currentYear {
                        labels.append(YearLabel(year: currentYear, firstIndex: spanStart, lastIndex: i - 1))
                        currentYear = year
                        spanStart = i
                    }
                }
            }
            // Final span
            labels.append(YearLabel(year: currentYear, firstIndex: spanStart, lastIndex: boundary.endIndex))
        }

        return labels
    }

    private static func zoneTint(for bucketSize: BucketSize) -> Color {
        switch bucketSize {
        case .month: Color(.systemBackground)
        case .day: Color(.secondarySystemBackground)
        case .session: Color(.systemBackground)
        case .week: Color(.systemBackground)
        }
    }

    static func yDomain(for buckets: [TimeBucket]) -> ClosedRange<Double> {
        guard !buckets.isEmpty else { return 0...1 }
        let rawMax = buckets.map { $0.mean + $0.stddev }.max() ?? 1
        let yMax = max(1, rawMax)
        return 0...yMax
    }

    static let visibleBucketCount = 8

    /// Returns the index-based scroll position so that the most recent data appears at the right edge.
    static func initialScrollPosition(for buckets: [TimeBucket]) -> Double {
        guard !buckets.isEmpty else { return 0 }
        return max(0, Double(buckets.count) - Double(visibleBucketCount))
    }

    static func annotationDateLabel(_ date: Date, size: BucketSize) -> String {
        let formatter = DateFormatter()
        switch size {
        case .month:
            formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        case .day, .week:
            formatter.setLocalizedDateFormatFromTemplate("E MMM d")
        case .session:
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        }
        return formatter.string(from: date)
    }

    static func findNearestBucketIndex(atX x: Double, bucketCount: Int) -> Int? {
        let index = Int(x.rounded(.toNearestOrEven))
        guard index >= 0, index < bucketCount else { return nil }
        return index
    }

    static func formatAxisLabel(_ date: Date, size: BucketSize, index: Int, buckets: [TimeBucket]) -> String {
        if size == .session {
            // Show "Today" only for the first session bucket
            let isFirst = index == 0 || buckets[index - 1].bucketSize != .session
            return isFirst ? String(localized: "Today") : ""
        }
        guard let config = zoneConfigs[size] else { return "" }
        var label = config.formatAxisLabel(date)
        // Strip trailing dot from German abbreviations (e.g., "Dez." → "Dez", "Mo." → "Mo")
        if label.hasSuffix(".") {
            label.removeLast()
        }
        return label
    }

    static func trendSymbol(_ trend: Trend) -> String {
        TrainingStatsView.trendSymbol(trend)
    }

    static func trendLabel(_ trend: Trend) -> String {
        TrainingStatsView.trendLabel(trend)
    }

    static func trendColor(_ trend: Trend) -> Color {
        TrainingStatsView.trendColor(trend)
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
