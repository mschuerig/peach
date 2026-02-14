import Foundation

/// Represents a single pitch comparison challenge for training
///
/// # Story 3.2 Placeholder Implementation
///
/// Until Epic 4 implements the adaptive algorithm, comparisons use simplified random generation:
/// - **note1**: Random MIDI note between 48 (C3) and 72 (C5)
/// - **note2**: Same MIDI note as note1
/// - **centDifference**: Fixed at 100.0 cents (1 semitone, easily detectable)
/// - **isSecondNoteHigher**: Randomly true or false
///
/// Epic 4 will replace random generation with AdaptiveNoteStrategy, but the Comparison
/// structure will remain unchanged - just different generation logic.
struct Comparison {
    /// First note as MIDI number (0-127)
    let note1: Int

    /// Second note as MIDI number (0-127, same as note1 for placeholder)
    let note2: Int

    /// Cent difference applied to note2 (always 100.0 for placeholder)
    let centDifference: Double

    /// Whether the second note is higher than the first
    let isSecondNoteHigher: Bool

    /// Generates a random placeholder comparison for training
    ///
    /// **Placeholder Logic (Story 3.2):**
    /// - Selects random MIDI note between 48 (C3) and 72 (C5) for note1
    /// - Sets note2 = note1 (same MIDI note)
    /// - Uses fixed 100 cent difference (1 semitone, easily detectable)
    /// - Randomly determines if second note is higher or lower
    ///
    /// **Why this works:**
    /// - Simple and testable with no algorithm complexity
    /// - 100 cents = 1 semitone = easily detectable interval for testing
    /// - Epic 4 will replace with AdaptiveNoteStrategy using same Comparison structure
    ///
    /// - Returns: A randomly generated comparison with 100 cent difference
    static func random() -> Comparison {
        let note1 = Int.random(in: 48...72)  // C3 to C5 range
        let note2 = note1  // Same MIDI note (pitch difference comes from cents)
        let centDifference = 100.0  // 1 semitone placeholder
        let isSecondNoteHigher = Bool.random()  // Randomly higher or lower

        return Comparison(
            note1: note1,
            note2: note2,
            centDifference: centDifference,
            isSecondNoteHigher: isSecondNoteHigher
        )
    }

    /// Calculates the frequency for note1 using standard reference pitch
    ///
    /// Uses FrequencyCalculation utility with configurable reference pitch.
    /// Epic 6 will expose reference pitch configuration from Settings.
    ///
    /// - Parameter referencePitch: The reference pitch in Hz (default: 440.0 for A4)
    /// - Returns: Frequency in Hz for the first note
    /// - Throws: AudioError.invalidFrequency if calculation fails (should never happen with valid MIDI)
    func note1Frequency(referencePitch: Double = 440.0) throws -> Double {
        return try FrequencyCalculation.frequency(midiNote: note1, referencePitch: referencePitch)
    }

    /// Calculates the frequency for note2 with cent offset applied
    ///
    /// Applies the cent difference in the direction specified by isSecondNoteHigher:
    /// - If second note is higher: adds centDifference
    /// - If second note is lower: subtracts centDifference
    ///
    /// - Parameter referencePitch: The reference pitch in Hz (default: 440.0 for A4)
    /// - Returns: Frequency in Hz for the second note
    /// - Throws: AudioError.invalidFrequency if calculation fails
    func note2Frequency(referencePitch: Double = 440.0) throws -> Double {
        let cents = isSecondNoteHigher ? centDifference : -centDifference
        return try FrequencyCalculation.frequency(midiNote: note2, cents: cents, referencePitch: referencePitch)
    }

    /// Validates if the user's answer matches the correct comparison
    ///
    /// - Parameter userAnswerHigher: True if user answered "higher", false if "lower"
    /// - Returns: True if the user's answer matches isSecondNoteHigher
    func isCorrect(userAnswerHigher: Bool) -> Bool {
        return userAnswerHigher == isSecondNoteHigher
    }
}

/// Represents a completed comparison with the user's answer
///
/// Bundles together a comparison and the user's response for recording and analysis.
/// This eliminates redundant parameters when passing comparison results to observers.
struct CompletedComparison {
    /// The comparison that was presented
    let comparison: Comparison

    /// Whether the user answered "higher" (true) or "lower" (false)
    let userAnsweredHigher: Bool

    /// Whether the user's answer was correct (computed property)
    var isCorrect: Bool {
        comparison.isCorrect(userAnswerHigher: userAnsweredHigher)
    }

    /// Timestamp when the comparison was completed
    let timestamp: Date

    /// Creates a completed comparison
    ///
    /// - Parameters:
    ///   - comparison: The comparison that was presented
    ///   - userAnsweredHigher: Whether the user answered "higher"
    ///   - timestamp: When the comparison was completed (defaults to now)
    init(comparison: Comparison, userAnsweredHigher: Bool, timestamp: Date = Date()) {
        self.comparison = comparison
        self.userAnsweredHigher = userAnsweredHigher
        self.timestamp = timestamp
    }
}
