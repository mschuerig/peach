import Foundation

/// Protocol for pitch comparison selection strategies in adaptive training
///
/// Defines the contract for algorithms that select the next pitch comparison
/// based on the user's perceptual profile and training settings.
///
/// # Architecture Boundary
///
/// NextPitchComparisonStrategy reads from PitchComparisonProfile and TrainingSettings,
/// and returns a PitchComparison value type. It has no concept of:
/// - Audio playback (NotePlayer's responsibility)
/// - Data persistence (TrainingDataStore's responsibility)
/// - Profile updates (PitchComparisonProfile's responsibility)
/// - UI rendering (SwiftUI's responsibility)
///
/// # Usage
///
/// The default implementation (`KazezNoteStrategy`) is injected into PitchComparisonSession
/// in `PeachApp.swift` (Story 9.1).
/// ```swift
/// let strategy: NextPitchComparisonStrategy = KazezNoteStrategy()
/// let pitchComparison = strategy.nextPitchComparison(profile: profile, settings: settings, lastPitchComparison: nil, interval: .prime)
/// ```
protocol NextPitchComparisonStrategy {
    /// Selects the next pitch comparison based on user's perceptual profile and settings
    ///
    /// Stateless selection - all inputs passed via parameters, output depends only on inputs.
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile with training statistics
    ///   - settings: Training configuration (note range, difficulty bounds, reference pitch)
    ///   - lastPitchComparison: The most recently completed pitch comparison (nil on first comparison)
    ///   - interval: The directed musical interval to apply between reference and target note.
    ///     `.prime` produces unison (target == reference); other intervals transpose the target
    ///     by the interval's semitone count via `MIDINote.transposed(by:)`.
    /// - Returns: A PitchComparison ready to be played by NotePlayer
    func nextPitchComparison(
        profile: PitchComparisonProfile,
        settings: TrainingSettings,
        lastPitchComparison: CompletedPitchComparison?,
        interval: DirectedInterval
    ) -> PitchComparison
}

/// Training configuration for pitch comparison selection
///
/// Contains settings that control the adaptive algorithm's behavior.
/// Exposed to users via SettingsScreen (@AppStorage) and read live by PitchComparisonSession.
///
/// # Defaults
///
/// - Note range: C2 to C6 (MIDI 36-84) — typical vocal/instrument range
/// - Reference pitch: 440Hz — standard concert pitch (A4)
/// - Difficulty bounds: 0.1 to 100.0 cents — practical human pitch comparison range
struct TrainingSettings {
    var noteRange: NoteRange
    var referencePitch: Frequency
    var minCentDifference: Cents
    var maxCentDifference: Cents

    init(
        noteRange: NoteRange = NoteRange(lowerBound: MIDINote(36), upperBound: MIDINote(84)),
        referencePitch: Frequency,
        minCentDifference: Cents = 0.1,
        maxCentDifference: Cents = 100.0
    ) {
        self.noteRange = noteRange
        self.referencePitch = referencePitch
        self.minCentDifference = minCentDifference
        self.maxCentDifference = maxCentDifference
    }
}
