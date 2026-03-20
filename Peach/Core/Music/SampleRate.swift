import Foundation

/// A sample rate in Hz — the number of audio samples per second.
struct SampleRate: Hashable, Comparable, Sendable {
    let rawValue: Double

    init(_ rawValue: Double) {
        precondition(rawValue > 0, "SampleRate must be positive, got \(rawValue)")
        self.rawValue = rawValue
    }

    static let standard44100 = SampleRate(44100.0)
    static let standard48000 = SampleRate(48000.0)

    // MARK: - Comparable

    static func < (lhs: SampleRate, rhs: SampleRate) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - ExpressibleByFloatLiteral

extension SampleRate: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.init(value)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension SampleRate: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(Double(value))
    }
}
