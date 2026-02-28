import Foundation

/// A resolved point in pitch space: a MIDI note plus a baked-in cent offset.
///
/// By the time a Pitch exists, the tuning system has already been applied
/// (via `MIDINote.pitch(at:in:)`). `frequency(referencePitch:)` is pure math
/// — it converts the note + cents into Hz using the given reference pitch.
/// The inverse, `Pitch.init(frequency:referencePitch:)`, recovers the nearest
/// MIDI note and remaining cent remainder from a raw Hz value.
struct Pitch: Hashable, Sendable {
    let note: MIDINote
    let cents: Cents

    /// The MIDI note whose frequency equals the reference pitch (A4 = 440 Hz by convention).
    private static let referenceMIDINote = 69
    /// Number of semitones (and MIDI steps) in one octave.
    private static let semitonesPerOctave = 12.0
    /// Number of cents in one semitone.
    private static let centsPerSemitone = 100.0
    /// Frequency ratio between a note and the note one octave above it.
    private static let octaveRatio = 2.0

    func frequency(referencePitch: Frequency) -> Frequency {
        let semitones = Double(note.rawValue - Self.referenceMIDINote)
            + cents.rawValue / Self.centsPerSemitone
        return Frequency(referencePitch.rawValue * pow(Self.octaveRatio, semitones / Self.semitonesPerOctave))
    }
}

extension Pitch {
    init(frequency: Frequency, referencePitch: Frequency) {
        let exactMidi = Double(Self.referenceMIDINote)
            + Self.semitonesPerOctave * log2(frequency.rawValue / referencePitch.rawValue)
        let roundedMidi = Int(exactMidi.rounded())
        let centsRemainder = (exactMidi - Double(roundedMidi)) * Self.centsPerSemitone
        self.init(
            note: MIDINote(roundedMidi.clamped(to: MIDINote.validRange)),
            cents: Cents(centsRemainder)
        )
    }
}
