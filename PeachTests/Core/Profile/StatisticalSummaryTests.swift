import Testing
import Foundation
@testable import Peach

@Suite("StatisticalSummary Tests")
struct StatisticalSummaryTests {

    @Test("recordCount delegates to TrainingDisciplineStatistics")
    func recordCountDelegates() async {
        var stats = TrainingDisciplineStatistics()
        stats.addPoint(MetricPoint(timestamp: Date(), value: 10.0), config: .default)
        stats.addPoint(MetricPoint(timestamp: Date(), value: 20.0), config: .default)

        let summary = StatisticalSummary.continuous(stats)
        #expect(summary.recordCount == 2)
    }

    @Test("trend delegates to TrainingDisciplineStatistics")
    func trendDelegates() async {
        var stats = TrainingDisciplineStatistics()
        let now = Date()
        stats.addPoint(MetricPoint(timestamp: now.addingTimeInterval(-2), value: 50.0), config: .default)
        stats.addPoint(MetricPoint(timestamp: now.addingTimeInterval(-1), value: 10.0), config: .default)

        let summary = StatisticalSummary.continuous(stats)
        #expect(summary.trend != nil)
    }

    @Test("ewma delegates to TrainingDisciplineStatistics")
    func ewmaDelegates() async {
        var stats = TrainingDisciplineStatistics()
        stats.addPoint(MetricPoint(timestamp: Date(), value: 15.0), config: .default)

        let summary = StatisticalSummary.continuous(stats)
        #expect(summary.ewma != nil)
    }

    @Test("metrics delegates to TrainingDisciplineStatistics")
    func metricsDelegates() async {
        var stats = TrainingDisciplineStatistics()
        let point = MetricPoint(timestamp: Date(), value: 42.0)
        stats.addPoint(point, config: .default)

        let summary = StatisticalSummary.continuous(stats)
        #expect(summary.metrics.count == 1)
        #expect(summary.metrics[0].value == 42.0)
    }

    @Test("empty statistics returns zero recordCount")
    func emptyStatistics() async {
        let summary = StatisticalSummary.continuous(TrainingDisciplineStatistics())
        #expect(summary.recordCount == 0)
        #expect(summary.trend == nil)
        #expect(summary.ewma == nil)
        #expect(summary.metrics.isEmpty)
    }
}
