import Foundation
import OSLog

@Observable
final class PerceptualProfile: PitchComparisonProfile, PitchMatchingProfile {

    private var modes: [TrainingMode: ModeStatistics] = [:]

    private let logger = Logger(subsystem: "com.peach.app", category: "PerceptualProfile")

    // MARK: - Initialization

    init() {
        for mode in TrainingMode.allCases {
            modes[mode] = ModeStatistics()
        }
        logger.info("PerceptualProfile initialized (cold start)")
    }

    // MARK: - Per-Mode Query API

    func statistics(for mode: TrainingMode) -> ModeStatistics? {
        modes[mode]
    }

    func hasData(for mode: TrainingMode) -> Bool {
        (modes[mode]?.recordCount ?? 0) > 0
    }

    func trend(for mode: TrainingMode) -> Trend? {
        modes[mode]?.trend
    }

    func currentEWMA(for mode: TrainingMode) -> Double? {
        modes[mode]?.ewma
    }

    func recordCount(for mode: TrainingMode) -> Int {
        modes[mode]?.recordCount ?? 0
    }

    // MARK: - PitchComparisonProfile (backward-compatible aggregate)

    func updateComparison(note: MIDINote, centOffset: Cents, isCorrect: Bool) {
        guard isCorrect else { return }
        let point = MetricPoint(timestamp: Date(), value: centOffset.magnitude)
        let mode = TrainingMode.unisonPitchComparison
        modes[mode]?.addPoint(point, config: mode.config)
    }

    var comparisonMean: Cents? {
        weightedMean(for: [.unisonPitchComparison, .intervalPitchComparison])
    }

    var comparisonStdDev: Cents? {
        weightedStdDev(for: [.unisonPitchComparison, .intervalPitchComparison])
    }

    // MARK: - PitchMatchingProfile (backward-compatible aggregate)

    func updateMatching(note: MIDINote, centError: Cents) {
        let point = MetricPoint(timestamp: Date(), value: centError.magnitude)
        let mode = TrainingMode.unisonMatching
        modes[mode]?.addPoint(point, config: mode.config)
    }

    var matchingMean: Cents? {
        weightedMean(for: [.unisonMatching, .intervalMatching])
    }

    var matchingStdDev: Cents? {
        weightedStdDev(for: [.unisonMatching, .intervalMatching])
    }

    var matchingSampleCount: Int {
        (modes[.unisonMatching]?.recordCount ?? 0) +
        (modes[.intervalMatching]?.recordCount ?? 0)
    }

    // MARK: - Rebuild

    func rebuild(metrics: [TrainingMode: [MetricPoint]]) {
        for mode in TrainingMode.allCases {
            var stats = ModeStatistics()
            if let points = metrics[mode], !points.isEmpty {
                let sorted = points.sorted { $0.timestamp < $1.timestamp }
                stats.rebuild(from: sorted, config: mode.config)
            }
            modes[mode] = stats
        }
        logger.info("PerceptualProfile rebuilt from metric points")
    }

    // MARK: - Reset

    func resetComparison() {
        modes[.unisonPitchComparison] = ModeStatistics()
        modes[.intervalPitchComparison] = ModeStatistics()
        logger.info("PerceptualProfile comparison data reset")
    }

    func resetMatching() {
        modes[.unisonMatching] = ModeStatistics()
        modes[.intervalMatching] = ModeStatistics()
        logger.info("Matching statistics reset")
    }

    func resetAll() {
        for mode in TrainingMode.allCases {
            modes[mode] = ModeStatistics()
        }
        logger.info("PerceptualProfile fully reset to cold start")
    }

    // MARK: - Private Helpers

    private func weightedMean(for targetModes: [TrainingMode]) -> Cents? {
        var totalCount = 0
        var totalSum = 0.0
        for mode in targetModes {
            if let stats = modes[mode], stats.recordCount > 0 {
                totalCount += stats.recordCount
                totalSum += stats.welford.mean * Double(stats.recordCount)
            }
        }
        guard totalCount > 0 else { return nil }
        return Cents(totalSum / Double(totalCount))
    }

    private func weightedStdDev(for targetModes: [TrainingMode]) -> Cents? {
        // Combined sample standard deviation using parallel Welford merge
        var totalCount = 0
        var combinedMean = 0.0
        var combinedM2 = 0.0

        for mode in targetModes {
            guard let stats = modes[mode], stats.recordCount > 0 else { continue }
            let n = stats.recordCount
            let mean = stats.welford.mean

            if totalCount == 0 {
                totalCount = n
                combinedMean = mean
                // M2 from sample variance: stdDev = sqrt(M2/(n-1)), so M2 = stdDev^2 * (n-1)
                if let stdDev = stats.welford.centsStdDev {
                    combinedM2 = stdDev.rawValue * stdDev.rawValue * Double(n - 1)
                }
            } else {
                let delta = mean - combinedMean
                let newTotal = totalCount + n
                let newMean = (combinedMean * Double(totalCount) + mean * Double(n)) / Double(newTotal)
                // Chan's parallel algorithm for combining M2
                if let stdDev = stats.welford.centsStdDev {
                    let m2B = stdDev.rawValue * stdDev.rawValue * Double(n - 1)
                    combinedM2 += m2B + delta * delta * Double(totalCount) * Double(n) / Double(newTotal)
                } else {
                    combinedM2 += delta * delta * Double(totalCount) * Double(n) / Double(newTotal)
                }
                combinedMean = newMean
                totalCount = newTotal
            }
        }

        guard totalCount >= 2 else { return nil }
        return Cents(sqrt(combinedM2 / Double(totalCount - 1)))
    }
}

// MARK: - PitchComparisonObserver

extension PerceptualProfile: PitchComparisonObserver {
    func pitchComparisonCompleted(_ completed: CompletedPitchComparison) {
        let pc = completed.pitchComparison
        let interval = (try? Interval.between(pc.referenceNote, pc.targetNote.note))?.rawValue ?? 0
        let isUnison = interval == 0
        let mode: TrainingMode = isUnison ? .unisonPitchComparison : .intervalPitchComparison

        guard completed.isCorrect else { return }

        let point = MetricPoint(
            timestamp: completed.timestamp,
            value: pc.targetNote.offset.magnitude
        )
        modes[mode]?.addPoint(point, config: mode.config)
    }
}

// MARK: - PitchMatchingObserver

extension PerceptualProfile: PitchMatchingObserver {
    func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
        let interval = (try? Interval.between(result.referenceNote, result.targetNote))?.rawValue ?? 0
        let isUnison = interval == 0
        let mode: TrainingMode = isUnison ? .unisonMatching : .intervalMatching

        let point = MetricPoint(
            timestamp: result.timestamp,
            value: result.userCentError.magnitude
        )
        modes[mode]?.addPoint(point, config: mode.config)
    }
}
