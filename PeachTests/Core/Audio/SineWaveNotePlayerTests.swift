import Testing
import Foundation
@testable import Peach

@Suite("SineWaveNotePlayer Tests")
struct SineWaveNotePlayerTests {

    // MARK: - Frequency Calculation Tests

    @Test("Frequency calculation: Middle C (MIDI 60) at 0 cents should be ~261.626 Hz")
    func frequencyCalculation_MiddleC() {
        let frequency = FrequencyCalculation.frequency(midiNote: 60, cents: 0.0)
        #expect(abs(frequency - 261.626) < 0.01)
    }

    @Test("Frequency calculation: A4 (MIDI 69) at 0 cents should be 440.0 Hz")
    func frequencyCalculation_A4() {
        let frequency = FrequencyCalculation.frequency(midiNote: 69, cents: 0.0)
        #expect(abs(frequency - 440.0) < 0.001)
    }

    @Test("Frequency calculation: MIDI 60 at +50 cents should be ~268.9 Hz")
    func frequencyCalculation_HalfStep() {
        let frequency = FrequencyCalculation.frequency(midiNote: 60, cents: 50.0)
        // Halfway between C (261.626) and C# (277.183) is approximately 268.9
        #expect(abs(frequency - 268.9) < 0.5)
    }

    @Test("Frequency calculation: 0.1 cent precision verification")
    func frequencyCalculation_SubCentPrecision() {
        let freq1 = FrequencyCalculation.frequency(midiNote: 69, cents: 0.0)
        let freq2 = FrequencyCalculation.frequency(midiNote: 69, cents: 0.1)

        // 0.1 cent should produce a measurable difference
        #expect(freq1 != freq2)

        // The difference should be tiny (0.1 cent ≈ 0.025 Hz at A4)
        #expect(abs(freq2 - freq1) < 0.1)
    }

    @Test("Frequency calculation: Custom reference pitch (442 Hz)")
    func frequencyCalculation_CustomReferencePitch() {
        let frequency = FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 442.0)
        #expect(abs(frequency - 442.0) < 0.001)
    }

    @Test("Frequency calculation: MIDI note 0 (C-1, ~8.18 Hz)")
    func frequencyCalculation_MIDI0() {
        let frequency = FrequencyCalculation.frequency(midiNote: 0, cents: 0.0)
        // MIDI 0 is C-1, which should be around 8.18 Hz
        #expect(abs(frequency - 8.18) < 0.1)
    }

    @Test("Frequency calculation: MIDI note 127 (G9, ~12543 Hz)")
    func frequencyCalculation_MIDI127() {
        let frequency = FrequencyCalculation.frequency(midiNote: 127, cents: 0.0)
        // MIDI 127 is G9, which should be around 12543 Hz
        #expect(abs(frequency - 12543.0) < 1.0)
    }

    @Test("Frequency calculation: Negative cent offset (-50 cents)")
    func frequencyCalculation_NegativeCents() {
        let frequency = FrequencyCalculation.frequency(midiNote: 60, cents: -50.0)
        // MIDI 60 at -50 cents should be between B (below C) and C
        // Approximately 254.2 Hz
        #expect(frequency < 261.626)  // Less than C
        #expect(abs(frequency - 254.2) < 1.0)
    }

    @Test("Frequency calculation: Extreme positive cent offset (+100 cents)")
    func frequencyCalculation_ExtremeCents() {
        let frequency = FrequencyCalculation.frequency(midiNote: 60, cents: 100.0)
        // +100 cents is a full semitone up, should equal MIDI 61 (C#)
        let cSharp = FrequencyCalculation.frequency(midiNote: 61, cents: 0.0)
        #expect(abs(frequency - cSharp) < 0.01)
    }

    // MARK: - AudioError Tests

    @Test("AudioError cases are properly defined")
    func audioError_CasesExist() {
        let error1: AudioError = .engineStartFailed("test")
        let error2: AudioError = .nodeAttachFailed("test")
        let error3: AudioError = .renderFailed("test")
        let error4: AudioError = .invalidFrequency("test")
        let error5: AudioError = .contextUnavailable

        // Verify errors can be created and are distinct
        #expect(error1 as Error is AudioError)
        #expect(error2 as Error is AudioError)
        #expect(error3 as Error is AudioError)
        #expect(error4 as Error is AudioError)
        #expect(error5 as Error is AudioError)
    }

    // MARK: - SineWaveNotePlayer Protocol Conformance

    @Test("SineWaveNotePlayer conforms to NotePlayer protocol")
    @MainActor
    func sineWaveNotePlayer_ProtocolConformance() throws {
        let player = try SineWaveNotePlayer()
        #expect(player is NotePlayer)
    }

    // MARK: - SineWaveNotePlayer Initialization

    @Test("SineWaveNotePlayer initializes without throwing")
    @MainActor
    func sineWaveNotePlayer_InitializesSuccessfully() {
        #expect(throws: Never.self) {
            _ = try SineWaveNotePlayer()
        }
    }

    @Test("SineWaveNotePlayer can be created and destroyed cleanly")
    @MainActor
    func sineWaveNotePlayer_Lifecycle() throws {
        let player = try SineWaveNotePlayer()
        // Player should be created successfully
        #expect(player is SineWaveNotePlayer)

        // Should be able to be deinitialized without issues
        // (deinit will be called when player goes out of scope)
    }

    // MARK: - Play Method Tests

    @Test("play() method doesn't throw for valid frequency")
    @MainActor
    func play_ValidFrequency_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()

        // Should not throw for valid inputs (works in simulator with AVAudioSession configured)
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.5)
        #expect(true)
    }

    @Test("play() throws AudioError.invalidFrequency for negative frequency")
    @MainActor
    func play_NegativeFrequency_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        await #expect(throws: AudioError.self) {
            try await player.play(frequency: -100.0, duration: 0.1, amplitude: 0.5)
        }
    }

    @Test("play() throws AudioError.invalidFrequency for zero frequency")
    @MainActor
    func play_ZeroFrequency_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        await #expect(throws: AudioError.self) {
            try await player.play(frequency: 0.0, duration: 0.1, amplitude: 0.5)
        }
    }

    @Test("play() throws AudioError.invalidFrequency for extremely high frequency")
    @MainActor
    func play_ExtremelyHighFrequency_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        // 50 kHz is beyond normal audible range
        await #expect(throws: AudioError.self) {
            try await player.play(frequency: 50000.0, duration: 0.1, amplitude: 0.5)
        }
    }

    @Test("play() throws error for invalid amplitude (negative)")
    @MainActor
    func play_NegativeAmplitude_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        await #expect(throws: AudioError.self) {
            try await player.play(frequency: 440.0, duration: 0.1, amplitude: -0.1)
        }
    }

    @Test("play() throws error for invalid amplitude (> 1.0)")
    @MainActor
    func play_ExcessiveAmplitude_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        await #expect(throws: AudioError.self) {
            try await player.play(frequency: 440.0, duration: 0.1, amplitude: 1.5)
        }
    }

    // MARK: - Stop Method Tests

    @Test("stop() method doesn't throw")
    @MainActor
    func stop_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()

        // Stop should not throw (does nothing if not playing)
        try await player.stop()
        #expect(true)
    }

    @Test("stop() can be called without prior play()")
    @MainActor
    func stop_WithoutPlay_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()

        // Calling stop without playing should not throw
        try await player.stop()
        #expect(true)
    }

    // MARK: - Sequential Playback Tests

    @Test("Multiple sequential plays work correctly")
    @MainActor
    func play_SequentialNotes_WorksCorrectly() async throws {
        let player = try SineWaveNotePlayer()

        // Play first note
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.5)

        // Play second note
        try await player.play(frequency: 523.25, duration: 0.05, amplitude: 0.5)

        // Both should complete without errors
        #expect(true)
    }

    @Test("play() with custom amplitude works correctly")
    @MainActor
    func play_CustomAmplitude_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()

        // Test various valid amplitudes
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.0)
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.25)
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 1.0)

        #expect(true)
    }
}
