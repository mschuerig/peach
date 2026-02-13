import Foundation

/// Errors that can occur during audio playback operations.
public enum AudioError: Error {
    /// The audio engine failed to start.
    /// - Parameter message: Detailed error context
    case engineStartFailed(String)

    /// Failed to attach an audio node to the engine.
    /// - Parameter message: Detailed error context
    case nodeAttachFailed(String)

    /// Audio rendering failed during playback.
    /// - Parameter message: Detailed error context
    case renderFailed(String)

    /// The specified frequency is invalid (negative, zero, or outside audible range).
    /// - Parameter message: Detailed error context including the invalid value
    case invalidFrequency(String)

    /// The audio context or format could not be created.
    case contextUnavailable
}

/// A protocol for playing musical notes at specified frequencies.
///
/// Conforming types are responsible for generating audio output at precise frequencies
/// with controlled envelopes to prevent audible artifacts. The protocol is frequency-agnostic
/// and has no concept of MIDI notes, cents, or musical context.
///
/// - Note: Implementations should ensure sub-10ms latency and frequency accuracy within 0.1 cent.
public protocol NotePlayer {
    /// Plays a note at the specified frequency for the given duration.
    ///
    /// - Parameters:
    ///   - frequency: The frequency in Hz (must be positive and within audible range)
    ///   - duration: The total duration of the note in seconds
    ///   - amplitude: The amplitude/volume (0.0 to 1.0, default: 0.5)
    /// - Throws: `AudioError` if playback cannot be initiated or maintained
    func play(frequency: Double, duration: TimeInterval, amplitude: Double) async throws

    /// Stops playback cleanly with a release envelope to prevent clicks.
    ///
    /// - Throws: `AudioError` if playback cannot be stopped gracefully
    func stop() async throws
}
