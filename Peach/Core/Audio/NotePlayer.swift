import Foundation

/// Errors that can occur during audio playback operations.
enum AudioError: Error {
    case engineStartFailed(String)
    case nodeAttachFailed(String)
    case renderFailed(String)
    case invalidFrequency(String)
    case contextUnavailable
}

/// A protocol for playing musical notes at specified frequencies.
///
/// Conforming types are responsible for generating audio output at precise frequencies
/// with controlled envelopes to prevent audible artifacts. The protocol is frequency-agnostic
/// and has no concept of MIDI notes, cents, or musical context.
///
/// - Note: Implementations should ensure sub-10ms latency and frequency accuracy within 0.1 cent.
protocol NotePlayer {
    /// Plays a note at the specified frequency for the given duration.
    ///
    /// - Parameters:
    ///   - frequency: The frequency in Hz (must be positive and within audible range)
    ///   - duration: The total duration of the note in seconds
    /// - Throws: `AudioError` if playback cannot be initiated or maintained
    func play(frequency: Double, duration: TimeInterval) async throws

    /// Stops playback cleanly with a release envelope to prevent clicks.
    ///
    /// - Throws: `AudioError` if playback cannot be stopped gracefully
    func stop() async throws
}
