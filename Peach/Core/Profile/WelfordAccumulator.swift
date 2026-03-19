import Foundation

/// Welford's online algorithm for computing running mean and variance in a single pass.
struct WelfordAccumulator {
    private(set) var count: Int = 0
    private(set) var mean: Double = 0.0
    private var m2: Double = 0.0

    mutating func update(_ value: Double) {
        count += 1
        let delta = value - mean
        mean += delta / Double(count)
        let delta2 = value - mean
        m2 += delta * delta2
    }

    var centsMean: Cents? {
        count > 0 ? Cents(mean) : nil
    }

    var centsStdDev: Cents? {
        guard count >= 2 else { return nil }
        return Cents(sqrt(m2 / Double(count - 1)))
    }

    var populationStdDev: Double? {
        count >= 2 ? sqrt(m2 / Double(count)) : nil
    }
}
