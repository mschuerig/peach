import Foundation

/// A physical frequency in Hz — the final output of pitch-to-sound conversion.
///
/// Frequency is what `NotePlayer` receives. Produced by `Pitch.frequency(referencePitch:)`
/// and reconstructed from audio via `Pitch.init(frequency:referencePitch:)`.
struct Frequency: Hashable, Comparable, Sendable {
    let rawValue: Double

    init(_ rawValue: Double) {
        precondition(rawValue > 0, "Frequency must be positive, got \(rawValue)")
        self.rawValue = rawValue
    }

    static let concert440 = Frequency(440.0)

    // MARK: - Comparable

    static func < (lhs: Frequency, rhs: Frequency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - ExpressibleByFloatLiteral

extension Frequency: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.init(value)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Frequency: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(Double(value))
    }
}
