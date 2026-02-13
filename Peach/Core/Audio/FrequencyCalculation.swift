import Foundation

/// Utilities for converting musical note information to frequencies.
public enum FrequencyCalculation {
    /// Converts a MIDI note number and cent offset to a frequency in Hz.
    ///
    /// Uses the equal temperament formula:
    /// `f = referencePitch * 2^((midiNote - 69) / 12) * 2^(cents / 1200)`
    ///
    /// - Parameters:
    ///   - midiNote: MIDI note number (0-127, where 69 = A4)
    ///   - cents: Cent offset from the MIDI note (-100 to +100 typical range)
    ///   - referencePitch: Reference pitch for A4 in Hz (default: 440.0)
    /// - Returns: Frequency in Hz with 0.1 cent precision
    ///
    /// # Examples
    /// - Middle C (MIDI 60) at 0 cents → 261.626 Hz
    /// - A4 (MIDI 69) at 0 cents → 440.000 Hz
    /// - MIDI 60 at +50 cents → ~268.9 Hz (halfway between C and C#)
    ///
    /// - Precondition: midiNote must be in range 0-127
    public static func frequency(midiNote: Int, cents: Double = 0.0, referencePitch: Double = 440.0) -> Double {
        precondition(midiNote >= 0 && midiNote <= 127, "MIDI note must be in range 0-127, got \(midiNote)")

        let semitonesFromA4 = Double(midiNote - 69)
        let octaveOffset = semitonesFromA4 / 12.0
        let centOffset = cents / 1200.0

        return referencePitch * pow(2.0, octaveOffset) * pow(2.0, centOffset)
    }
}
