import Foundation
import CoreGraphics

/// Protocol defining visual and formatting configuration for a chart granularity zone.
///
/// Each conformance provides the point width for chart rendering and an axis label
/// formatter for dates within that zone. Adding a new granularity requires only a new
/// conformance — no changes to existing code.
///
/// Note: `backgroundTint` is intentionally omitted from Core/ to avoid SwiftUI imports.
/// The UI layer maps `BucketSize` → `Color` separately.
protocol GranularityZoneConfig {
    /// Horizontal width in points for each data point at this granularity.
    var pointWidth: CGFloat { get }

    /// Formats a date into an axis label appropriate for this granularity.
    func formatAxisLabel(_ date: Date) -> String
}

/// Zone configuration for monthly granularity.
struct MonthlyZoneConfig: GranularityZoneConfig {
    let pointWidth: CGFloat = 30

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    func formatAxisLabel(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }
}

/// Zone configuration for daily granularity.
struct DailyZoneConfig: GranularityZoneConfig {
    let pointWidth: CGFloat = 40

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    func formatAxisLabel(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }
}

/// Zone configuration for session granularity.
struct SessionZoneConfig: GranularityZoneConfig {
    let pointWidth: CGFloat = 50

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    func formatAxisLabel(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }
}
