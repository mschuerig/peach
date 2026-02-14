import Foundation

/// Protocol for comparison selection strategies in adaptive training
///
/// Defines the contract for algorithms that select the next comparison
/// based on the user's perceptual profile and training settings.
///
/// # Architecture Boundary
///
/// NextNoteStrategy reads from PerceptualProfile and TrainingSettings,
/// and returns a Comparison value type. It has no concept of:
/// - Audio playback (NotePlayer's responsibility)
/// - Data persistence (TrainingDataStore's responsibility)
/// - Profile updates (PerceptualProfile's responsibility)
/// - UI rendering (SwiftUI's responsibility)
///
/// # Usage
///
/// Implementations are injected into TrainingSession (Story 4.3):
/// ```swift
/// let strategy: NextNoteStrategy = AdaptiveNoteStrategy()
/// let comparison = strategy.nextComparison(profile: profile, settings: settings)
/// ```
@MainActor
protocol NextNoteStrategy {
    /// Selects the next comparison based on user's perceptual profile and settings
    ///
    /// - Parameters:
    ///   - profile: User's perceptual profile with training statistics
    ///   - settings: Training configuration (note range, Natural/Mechanical balance)
    /// - Returns: A Comparison ready to be played by NotePlayer
    func nextComparison(profile: PerceptualProfile, settings: TrainingSettings) -> Comparison
}

/// Training configuration for comparison selection
///
/// Contains settings that control the adaptive algorithm's behavior.
/// Epic 6 will create SettingsScreen to expose these via @AppStorage.
///
/// # Defaults
///
/// - Note range: C2 to C6 (MIDI 36-84) — typical vocal/instrument range
/// - Natural/Mechanical: 0.5 — balanced between exploration and weak spot focus
/// - Reference pitch: 440Hz — standard concert pitch (A4)
struct TrainingSettings {
    /// Minimum MIDI note for comparisons (0-127)
    var noteRangeMin: Int

    /// Maximum MIDI note for comparisons (0-127)
    var noteRangeMax: Int

    /// Balance between nearby notes (0.0) and weak spots (1.0)
    /// - 0.0 (Natural): 100% nearby notes — exploratory, region-focused training
    /// - 0.5 (Balanced): 50/50 mix of nearby and weak spot jumps
    /// - 1.0 (Mechanical): 100% weak spots — laser-focused on weaknesses
    var naturalVsMechanical: Double

    /// Reference pitch for frequency calculation in Hz
    /// Standard concert pitch: A4 = 440Hz
    var referencePitch: Double

    /// Creates training settings with default values
    ///
    /// - Parameters:
    ///   - noteRangeMin: Minimum MIDI note (default: 36 = C2)
    ///   - noteRangeMax: Maximum MIDI note (default: 84 = C6)
    ///   - naturalVsMechanical: Natural/Mechanical balance (default: 0.5 = balanced)
    ///   - referencePitch: Reference pitch in Hz (default: 440.0 = A4)
    init(
        noteRangeMin: Int = 36,
        noteRangeMax: Int = 84,
        naturalVsMechanical: Double = 0.5,
        referencePitch: Double = 440.0
    ) {
        self.noteRangeMin = noteRangeMin
        self.noteRangeMax = noteRangeMax
        self.naturalVsMechanical = naturalVsMechanical
        self.referencePitch = referencePitch
    }

    /// Whether a MIDI note is within the configured range
    ///
    /// - Parameter note: MIDI note (0-127)
    /// - Returns: True if note is within noteRangeMin...noteRangeMax
    func isInRange(_ note: Int) -> Bool {
        return note >= noteRangeMin && note <= noteRangeMax
    }
}
