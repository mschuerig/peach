import Foundation
@testable import Peach

final class MockTrainingProfile: TrainingProfile {
    // MARK: - Test State

    private var stubbedStatistics: [StatisticsKey: TrainingDisciplineStatistics] = [:]

    // MARK: - TrainingProfile Protocol

    func statistics(for key: StatisticsKey) -> StatisticalSummary? {
        guard let stats = stubbedStatistics[key], stats.recordCount > 0 else { return nil }
        return .continuous(stats)
    }

    // MARK: - Test Helpers

    func stub(_ key: StatisticsKey, mean: Double, count: Int = 1) {
        var stats = TrainingDisciplineStatistics()
        for i in 0..<count {
            stats.addPoint(
                MetricPoint(timestamp: Date().addingTimeInterval(Double(i)), value: mean),
                config: key.statisticsConfig
            )
        }
        stubbedStatistics[key] = stats
    }
}
