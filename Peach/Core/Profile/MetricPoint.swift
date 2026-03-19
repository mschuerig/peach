import Foundation

/// A single timestamped measurement from a training exercise.
struct MetricPoint {
    let timestamp: Date
    let value: Double
}
