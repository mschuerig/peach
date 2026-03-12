import Testing
import Foundation
@testable import Peach

@Suite("ProgressChartView Tests")
struct ProgressChartViewTests {

    // MARK: - Y-Domain Computation

    @Test("computes Y domain from zero to max with stddev")
    func yDomainFromBuckets() async {
        let buckets = [
            TimeBucket(periodStart: Date(), periodEnd: Date(), bucketSize: .month, mean: 20.0, stddev: 5.0, recordCount: 10),
            TimeBucket(periodStart: Date(), periodEnd: Date(), bucketSize: .day, mean: 10.0, stddev: 3.0, recordCount: 5),
            TimeBucket(periodStart: Date(), periodEnd: Date(), bucketSize: .session, mean: 30.0, stddev: 8.0, recordCount: 3),
        ]
        let domain = ProgressChartView.yDomain(for: buckets)
        #expect(domain.lowerBound == 0.0)
        #expect(domain.upperBound == 38.0)
    }

    @Test("Y domain always starts at zero")
    func yDomainAlwaysStartsAtZero() async {
        let buckets = [
            TimeBucket(periodStart: Date(), periodEnd: Date(), bucketSize: .month, mean: 2.0, stddev: 5.0, recordCount: 10),
        ]
        let domain = ProgressChartView.yDomain(for: buckets)
        #expect(domain.lowerBound == 0.0)
        #expect(domain.upperBound == 7.0)
    }

    @Test("Y domain for empty buckets returns 0...1")
    func yDomainEmptyBuckets() async {
        let domain = ProgressChartView.yDomain(for: [])
        #expect(domain.lowerBound == 0.0)
        #expect(domain.upperBound == 1.0)
    }

    @Test("Y domain for single bucket with zero stddev")
    func yDomainSingleBucketZeroStddev() async {
        let buckets = [
            TimeBucket(periodStart: Date(), periodEnd: Date(), bucketSize: .day, mean: 15.0, stddev: 0.0, recordCount: 1),
        ]
        let domain = ProgressChartView.yDomain(for: buckets)
        #expect(domain.lowerBound == 0.0)
        #expect(domain.upperBound == 15.0)
    }

    // MARK: - Data Windowing

    @Test("windowed slice returns correct subset with buffer")
    func windowedSliceWithBuffer() async {
        let buckets = makeBucketArray(count: 50)
        let result = ProgressChartView.windowedBuckets(from: buckets, visibleRange: 30..<40, buffer: 5)
        #expect(result.count == 20)
        #expect(result.first?.mean == 25.0)
        #expect(result.last?.mean == 44.0)
    }

    @Test("windowed slice clamps at start boundary")
    func windowedSliceClampsAtStart() async {
        let buckets = makeBucketArray(count: 50)
        let result = ProgressChartView.windowedBuckets(from: buckets, visibleRange: 0..<5, buffer: 5)
        #expect(result.count == 10)
        #expect(result.first?.mean == 0.0)
    }

    @Test("windowed slice clamps at end boundary")
    func windowedSliceClampsAtEnd() async {
        let buckets = makeBucketArray(count: 50)
        let result = ProgressChartView.windowedBuckets(from: buckets, visibleRange: 45..<50, buffer: 5)
        #expect(result.count == 10)
        #expect(result.last?.mean == 49.0)
    }

    @Test("windowed slice with fewer buckets than buffer returns all")
    func windowedSliceFewBuckets() async {
        let buckets = makeBucketArray(count: 8)
        let result = ProgressChartView.windowedBuckets(from: buckets, visibleRange: 2..<6, buffer: 5)
        #expect(result.count == 8)
    }

    @Test("windowed slice with empty buckets returns empty")
    func windowedSliceEmpty() async {
        let result = ProgressChartView.windowedBuckets(from: [], visibleRange: 0..<0, buffer: 5)
        #expect(result.isEmpty)
    }

    // MARK: - Zone Config Dictionary

    @Test("zone configs contains month, day, and session")
    func zoneConfigsContainsExpectedKeys() async {
        let configs = ProgressChartView.zoneConfigs
        #expect(configs[.month] != nil)
        #expect(configs[.day] != nil)
        #expect(configs[.session] != nil)
    }

    @Test("zone configs does not contain week")
    func zoneConfigsExcludesWeek() async {
        let configs = ProgressChartView.zoneConfigs
        #expect(configs[.week] == nil)
    }

    @Test("zone config point widths match expected values")
    func zoneConfigPointWidths() async {
        let configs = ProgressChartView.zoneConfigs
        #expect(configs[.month]?.pointWidth == 30)
        #expect(configs[.day]?.pointWidth == 40)
        #expect(configs[.session]?.pointWidth == 50)
    }

    // MARK: - Initial Scroll Position

    @Test("initial scroll position places latest data at right edge")
    func initialScrollPositionPinsRight() async {
        let buckets = makeBucketArray(count: 30)
        let position = ProgressChartView.initialScrollPosition(for: buckets)
        // With 30 buckets and visibleBucketCount=12, should start at index 18
        #expect(position == Double(30 - ProgressChartView.visibleBucketCount))
    }

    @Test("initial scroll position for small dataset returns zero")
    func initialScrollPositionSmallDataset() async {
        let buckets = makeBucketArray(count: 5)
        let position = ProgressChartView.initialScrollPosition(for: buckets)
        #expect(position == 0)
    }

    // MARK: - Trend Display

    @Test("trend symbol for improving is arrow.down.right")
    func trendSymbolImproving() async {
        #expect(ProgressChartView.trendSymbol(.improving) == "arrow.down.right")
    }

    @Test("trend symbol for stable is arrow.right")
    func trendSymbolStable() async {
        #expect(ProgressChartView.trendSymbol(.stable) == "arrow.right")
    }

    @Test("trend symbol for declining is arrow.up.right")
    func trendSymbolDeclining() async {
        #expect(ProgressChartView.trendSymbol(.declining) == "arrow.up.right")
    }

    @Test("trend label for improving")
    func trendLabelImproving() async {
        let label = ProgressChartView.trendLabel(.improving)
        #expect(!label.isEmpty)
    }

    // MARK: - EWMA Formatting

    @Test("formats EWMA value with one decimal place")
    func formatEWMA() async {
        let formatted = ProgressChartView.formatEWMA(23.456)
        #expect(formatted.contains("23.5") || formatted.contains("23,5"))
    }

    @Test("formats stddev with plus-minus prefix")
    func formatStdDev() async {
        let formatted = ProgressChartView.formatStdDev(5.78)
        #expect(formatted.contains("±"))
    }

    // MARK: - Accessibility

    @Test("chart accessibility value includes EWMA and trend")
    func chartAccessibilityValue() async {
        let value = ProgressChartView.chartAccessibilityValue(
            ewma: 25.3,
            trend: .improving,
            unitLabel: "cents"
        )
        #expect(!value.isEmpty)
    }

    // MARK: - Zone Separator Metadata (Index-Based)

    @Test("returns zone separator data for three-zone buckets with correct indices")
    func zoneSeparatorsThreeZones() async {
        let base = Date(timeIntervalSinceReferenceDate: 0)
        let buckets = [
            TimeBucket(periodStart: base, periodEnd: base.addingTimeInterval(3600), bucketSize: .month, mean: 10, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: base.addingTimeInterval(86400), periodEnd: base.addingTimeInterval(86400 + 3600), bucketSize: .month, mean: 12, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: base.addingTimeInterval(86400 * 2), periodEnd: base.addingTimeInterval(86400 * 2 + 3600), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
            TimeBucket(periodStart: base.addingTimeInterval(86400 * 3), periodEnd: base.addingTimeInterval(86400 * 3 + 3600), bucketSize: .day, mean: 9, stddev: 1, recordCount: 3),
            TimeBucket(periodStart: base.addingTimeInterval(86400 * 4), periodEnd: base.addingTimeInterval(86400 * 4 + 3600), bucketSize: .session, mean: 7, stddev: 1, recordCount: 1),
        ]

        let separators = ProgressChartView.zoneSeparatorData(for: buckets)

        #expect(separators.zones.count == 3)
        #expect(separators.dividerIndices.count == 2)

        #expect(separators.zones[0].bucketSize == .month)
        #expect(separators.zones[0].startIndex == 0)
        #expect(separators.zones[0].endIndex == 1)

        #expect(separators.zones[1].bucketSize == .day)
        #expect(separators.zones[1].startIndex == 2)
        #expect(separators.zones[1].endIndex == 3)

        #expect(separators.zones[2].bucketSize == .session)
        #expect(separators.zones[2].startIndex == 4)
        #expect(separators.zones[2].endIndex == 4)

        // Divider indices at zone transitions
        #expect(separators.dividerIndices[0] == 2)
        #expect(separators.dividerIndices[1] == 4)
    }

    @Test("returns no zone separators for single-zone buckets")
    func zoneSeparatorsSingleZone() async {
        let base = Date(timeIntervalSinceReferenceDate: 0)
        let buckets = [
            TimeBucket(periodStart: base, periodEnd: base.addingTimeInterval(3600), bucketSize: .day, mean: 10, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: base.addingTimeInterval(86400), periodEnd: base.addingTimeInterval(86400 + 3600), bucketSize: .day, mean: 12, stddev: 1, recordCount: 5),
        ]

        let separators = ProgressChartView.zoneSeparatorData(for: buckets)
        #expect(separators.zones.isEmpty)
        #expect(separators.dividerIndices.isEmpty)
    }

    @Test("returns zone separator data for two-zone buckets")
    func zoneSeparatorsTwoZones() async {
        let base = Date(timeIntervalSinceReferenceDate: 0)
        let buckets = [
            TimeBucket(periodStart: base, periodEnd: base.addingTimeInterval(3600), bucketSize: .month, mean: 10, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: base.addingTimeInterval(86400), periodEnd: base.addingTimeInterval(86400 + 3600), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
            TimeBucket(periodStart: base.addingTimeInterval(86400 * 2), periodEnd: base.addingTimeInterval(86400 * 2 + 3600), bucketSize: .day, mean: 9, stddev: 1, recordCount: 3),
        ]

        let separators = ProgressChartView.zoneSeparatorData(for: buckets)
        #expect(separators.zones.count == 2)
        #expect(separators.dividerIndices.count == 1)
        #expect(separators.dividerIndices[0] == 1)
    }

    @Test("returns no zone separators for empty buckets")
    func zoneSeparatorsEmpty() async {
        let separators = ProgressChartView.zoneSeparatorData(for: [])
        #expect(separators.zones.isEmpty)
        #expect(separators.dividerIndices.isEmpty)
    }

    // MARK: - Year Boundary Tests

    @Test("year boundary within monthly zone adds divider index")
    func yearBoundaryDivider() async {
        let calendar = Calendar.current
        // Monthly buckets spanning Oct 2025 through Feb 2026 — year boundary at index 3
        let oct2025 = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
        let nov2025 = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1))!
        let dec2025 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        let jan2026 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let feb2026 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let mar2026 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!

        let buckets = [
            TimeBucket(periodStart: oct2025, periodEnd: nov2025, bucketSize: .month, mean: 10, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: nov2025, periodEnd: dec2025, bucketSize: .month, mean: 11, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: dec2025, periodEnd: jan2026, bucketSize: .month, mean: 12, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: jan2026, periodEnd: feb2026, bucketSize: .month, mean: 13, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: feb2026, periodEnd: mar2026, bucketSize: .month, mean: 14, stddev: 1, recordCount: 5),
            // Day zone starts at index 5 — far enough from year boundary at index 3
            TimeBucket(periodStart: mar2026, periodEnd: mar2026.addingTimeInterval(86400), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
        ]

        let separators = ProgressChartView.zoneSeparatorData(for: buckets)
        // Zone divider at index 5 (month→day transition)
        // Year divider at index 3 (Dec 2025 → Jan 2026) — not near zone transition
        #expect(separators.dividerIndices.contains(3), "Year boundary between Dec 2025 and Jan 2026 should be a divider")
        #expect(separators.dividerIndices.contains(5), "Zone transition should be a divider")
    }

    @Test("year boundary within 1 index of zone transition is suppressed")
    func yearBoundaryDeduplication() async {
        let calendar = Calendar.current
        // Monthly bucket for Dec 2025, then zone transition immediately at Jan 2026 (day zone)
        let dec2025 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        let jan2026 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!

        let buckets = [
            TimeBucket(periodStart: dec2025, periodEnd: jan2026, bucketSize: .month, mean: 10, stddev: 1, recordCount: 5),
            // Zone transition at index 1 (day zone starts at Jan 2026)
            TimeBucket(periodStart: jan2026, periodEnd: jan2026.addingTimeInterval(86400), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
        ]

        let separators = ProgressChartView.zoneSeparatorData(for: buckets)
        // Zone divider at index 1. Year boundary would also be at index 1 — should be deduplicated (only 1 divider).
        #expect(separators.dividerIndices.count == 1)
        #expect(separators.dividerIndices[0] == 1)
    }

    // MARK: - Year Label Tests

    @Test("year labels for monthly buckets spanning two years")
    func yearLabelsMultiYear() async {
        let calendar = Calendar.current
        let oct2025 = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
        let nov2025 = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1))!
        let dec2025 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        let jan2026 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let feb2026 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!

        let buckets = [
            TimeBucket(periodStart: oct2025, periodEnd: nov2025, bucketSize: .month, mean: 10, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: nov2025, periodEnd: dec2025, bucketSize: .month, mean: 11, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: dec2025, periodEnd: jan2026, bucketSize: .month, mean: 12, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: jan2026, periodEnd: feb2026, bucketSize: .month, mean: 13, stddev: 1, recordCount: 5),
            // Day zone
            TimeBucket(periodStart: feb2026, periodEnd: feb2026.addingTimeInterval(86400), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
        ]

        let labels = ProgressChartView.yearLabels(for: buckets)

        #expect(labels.count == 2)
        #expect(labels[0].year == 2025)
        #expect(labels[0].firstIndex == 0)
        #expect(labels[0].lastIndex == 2)
        #expect(labels[1].year == 2026)
        #expect(labels[1].firstIndex == 3)
        #expect(labels[1].lastIndex == 3)
    }

    @Test("year labels for monthly buckets within single year")
    func yearLabelsSingleYear() async {
        let calendar = Calendar.current
        let oct2025 = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
        let nov2025 = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1))!
        let dec2025 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!

        let buckets = [
            TimeBucket(periodStart: oct2025, periodEnd: nov2025, bucketSize: .month, mean: 10, stddev: 1, recordCount: 5),
            TimeBucket(periodStart: nov2025, periodEnd: dec2025, bucketSize: .month, mean: 11, stddev: 1, recordCount: 5),
            // Day zone
            TimeBucket(periodStart: dec2025, periodEnd: dec2025.addingTimeInterval(86400), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
        ]

        let labels = ProgressChartView.yearLabels(for: buckets)

        #expect(labels.count == 1)
        #expect(labels[0].year == 2025)
        #expect(labels[0].firstIndex == 0)
        #expect(labels[0].lastIndex == 1)
    }

    @Test("no year labels when no monthly zone exists")
    func yearLabelsNoMonthlyZone() async {
        let base = Date(timeIntervalSinceReferenceDate: 0)
        let buckets = [
            TimeBucket(periodStart: base, periodEnd: base.addingTimeInterval(86400), bucketSize: .day, mean: 8, stddev: 1, recordCount: 3),
            TimeBucket(periodStart: base.addingTimeInterval(86400), periodEnd: base.addingTimeInterval(86400 * 2), bucketSize: .session, mean: 7, stddev: 1, recordCount: 1),
        ]

        let labels = ProgressChartView.yearLabels(for: buckets)
        #expect(labels.isEmpty)
    }

    // MARK: - Helpers

    private func makeBucketArray(count: Int) -> [TimeBucket] {
        let now = Date()
        return (0..<count).map { i in
            TimeBucket(
                periodStart: now.addingTimeInterval(Double(i) * -86400),
                periodEnd: now.addingTimeInterval(Double(i) * -86400 + 3600),
                bucketSize: .day,
                mean: Double(i),
                stddev: 1.0,
                recordCount: 5
            )
        }
    }
}
