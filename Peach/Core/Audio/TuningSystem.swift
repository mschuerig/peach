import Foundation

/// Defines how intervals map to cent offsets from 12-TET.
///
/// An enum (not a protocol) so it can drive a future Settings picker via
/// `CaseIterable`. Currently only `.equalTemperament`; adding a case
/// (e.g. `.justIntonation`) supplies non-zero cent deviations.
enum TuningSystem: Hashable, Sendable, CaseIterable, Codable {
    case equalTemperament

    func centOffset(for interval: Interval) -> Double {
        switch self {
        case .equalTemperament:
            return Double(interval.semitones) * 100.0
        }
    }
}
