import Testing
import Foundation
@testable import Peach

@Suite("ProgressChartView Tests")
struct ProgressChartViewTests {

    // MARK: - Bucket Label Formatting

    @Test("session bucket formats as relative time")
    func sessionBucketLabel() async {
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)
        let label = ProgressChartView.bucketLabel(for: twoHoursAgo, size: .session, relativeTo: now)
        #expect(!label.isEmpty)
    }

    @Test("day bucket formats as weekday abbreviation")
    func dayBucketLabel() async {
        let monday = dateFromComponents(year: 2026, month: 3, day: 2) // Monday
        let label = ProgressChartView.bucketLabel(for: monday, size: .day, relativeTo: Date())
        #expect(!label.isEmpty)
    }

    @Test("week bucket formats as month and day")
    func weekBucketLabel() async {
        let date = dateFromComponents(year: 2026, month: 3, day: 1)
        let label = ProgressChartView.bucketLabel(for: date, size: .week, relativeTo: Date())
        #expect(label.contains("Mar") || label.contains("Mär"))
    }

    @Test("month bucket formats as month abbreviation")
    func monthBucketLabel() async {
        let date = dateFromComponents(year: 2026, month: 1, day: 15)
        let label = ProgressChartView.bucketLabel(for: date, size: .month, relativeTo: Date())
        #expect(label.contains("Jan"))
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

    // MARK: - Cold Start Message

    @Test("cold start message includes records needed count")
    func coldStartMessage() async {
        let message = ProgressChartView.coldStartMessage(recordsNeeded: 15)
        #expect(message.contains("15"))
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

    // MARK: - Display Buckets

    @Test("displayBuckets returns original buckets when no expansion")
    func displayBucketsNoExpansion() async {
        let timeline = ProgressTimeline()
        let buckets = makeSampleBuckets()
        let result = ProgressChartView.displayBuckets(
            from: buckets,
            expandedIndex: nil,
            timeline: timeline,
            mode: .unisonComparison
        )
        #expect(result.count == buckets.count)
    }

    @Test("displayBuckets replaces expanded bucket with sub-buckets")
    func displayBucketsWithExpansion() async {
        // Create records spanning ~45 days ago (month bucket) with multiple weeks
        let now = Date()
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now.addingTimeInterval(-45 * 86400)))!
        let records = (0..<20).map { i in
            ComparisonRecord(
                referenceNote: 60,
                targetNote: 60,
                centOffset: 10.0 + Double(i),
                isCorrect: true,
                interval: 0,
                tuningSystem: "equalTemperament",
                timestamp: monthStart.addingTimeInterval(Double(i % 28) * 86400 + Double(i) * 60)
            )
        }
        let timeline = ProgressTimeline(comparisonRecords: records)
        let baseBuckets = timeline.buckets(for: .unisonComparison)

        guard let monthIndex = baseBuckets.firstIndex(where: { $0.bucketSize == .month }) else {
            Issue.record("Expected at least one month bucket")
            return
        }

        let result = ProgressChartView.displayBuckets(
            from: baseBuckets,
            expandedIndex: monthIndex,
            timeline: timeline,
            mode: .unisonComparison
        )
        // Should have more buckets than base (month replaced by multiple weeks)
        #expect(result.count > baseBuckets.count)
    }

    @Test("displayBuckets with out-of-range index returns original buckets")
    func displayBucketsOutOfRange() async {
        let timeline = ProgressTimeline()
        let buckets = makeSampleBuckets()
        let result = ProgressChartView.displayBuckets(
            from: buckets,
            expandedIndex: 999,
            timeline: timeline,
            mode: .unisonComparison
        )
        #expect(result.count == buckets.count)
    }

    private func makeSampleBuckets() -> [TimeBucket] {
        let now = Date()
        return [
            TimeBucket(periodStart: now.addingTimeInterval(-86400), periodEnd: now.addingTimeInterval(-43200), bucketSize: .day, mean: 10.0, stddev: 2.0, recordCount: 5),
            TimeBucket(periodStart: now.addingTimeInterval(-43200), periodEnd: now, bucketSize: .day, mean: 8.0, stddev: 1.5, recordCount: 3),
        ]
    }

    // MARK: - Helpers

    private func dateFromComponents(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
