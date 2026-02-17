import SwiftUI
import Charts

/// Data point for the confidence band visualization
struct ConfidenceBandDataPoint: Identifiable {
    let midiNote: Int
    let threshold: Double
    let upperBound: Double
    let lowerBound: Double
    let isTrained: Bool

    var id: Int { midiNote }
}

/// A contiguous group of trained data points (no gaps)
struct ConfidenceBandSegment: Identifiable {
    let id: Int
    let points: [ConfidenceBandDataPoint]
}

/// Prepares confidence band data from a PerceptualProfile
enum ConfidenceBandData {

    /// Minimum display value for log scale compatibility (log(0) is undefined)
    static let logFloor: Double = 0.5

    /// Extracts per-note data points for the confidence band chart
    /// Uses absolute mean for threshold (handles signed centOffset)
    /// Band width = mean ± stdDev, clamped to >= logFloor
    @MainActor
    static func prepare(from profile: PerceptualProfile, midiRange: ClosedRange<Int>) -> [ConfidenceBandDataPoint] {
        (midiRange.lowerBound...midiRange.upperBound).map { note in
            let stats = profile.statsForNote(note)

            if stats.isTrained {
                let absMean = abs(stats.mean)
                let upper = absMean + stats.stdDev
                let lower = max(logFloor, absMean - stats.stdDev)

                return ConfidenceBandDataPoint(
                    midiNote: note,
                    threshold: max(logFloor, absMean),
                    upperBound: max(logFloor, upper),
                    lowerBound: lower,
                    isTrained: true
                )
            } else {
                return ConfidenceBandDataPoint(
                    midiNote: note,
                    threshold: 0,
                    upperBound: 0,
                    lowerBound: 0,
                    isTrained: false
                )
            }
        }
    }

    /// Groups trained data points into contiguous segments
    /// Gaps (untrained notes) break segments so the chart doesn't interpolate across them
    static func segments(from points: [ConfidenceBandDataPoint]) -> [ConfidenceBandSegment] {
        var segments: [ConfidenceBandSegment] = []
        var current: [ConfidenceBandDataPoint] = []
        var index = 0

        for point in points {
            if point.isTrained {
                current.append(point)
            } else {
                if !current.isEmpty {
                    segments.append(ConfidenceBandSegment(id: index, points: current))
                    index += 1
                    current = []
                }
            }
        }

        if !current.isEmpty {
            segments.append(ConfidenceBandSegment(id: index, points: current))
        }

        return segments
    }
}

/// Renders the confidence band overlay using Swift Charts AreaMark
/// Y-axis: 0 cents (best) at bottom near keyboard, higher values further away
/// Logarithmic scale to emphasize the musically relevant low-cent range
struct ConfidenceBandView: View {
    let dataPoints: [ConfidenceBandDataPoint]
    let layout: PianoKeyboardLayout

    var body: some View {
        let segments = ConfidenceBandData.segments(from: dataPoints)

        Chart {
            ForEach(segments) { segment in
                ForEach(segment.points) { point in
                    AreaMark(
                        x: .value("Note", point.midiNote),
                        yStart: .value("Lower", point.lowerBound),
                        yEnd: .value("Upper", point.upperBound),
                        series: .value("Segment", segment.id)
                    )
                    .foregroundStyle(.tint.opacity(0.3))

                    LineMark(
                        x: .value("Note", point.midiNote),
                        y: .value("Threshold", point.threshold),
                        series: .value("Segment", segment.id)
                    )
                    .foregroundStyle(.tint)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
        }
        .chartXScale(domain: layout.midiRange)
        .chartXAxis(.hidden)
        .chartYScale(domain: ConfidenceBandData.logFloor...yAxisMax, type: .log)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let cents = value.as(Double.self) {
                        Text("\(Int(cents))¢")
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
    }

    private var yAxisMax: Double {
        let maxValue = dataPoints
            .filter { $0.isTrained }
            .map(\.upperBound)
            .max() ?? 100

        // Round up to a nice ceiling for the log scale
        return max(100, ceil(maxValue / 10) * 10)
    }
}
