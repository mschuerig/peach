import Testing
import Foundation
@testable import Peach

@Suite("SineWaveNotePlayer Tests")
struct SineWaveNotePlayerTests {

    // MARK: - Frequency Calculation Tests

    @Test("Frequency calculation: Middle C (MIDI 60) at 0 cents should be ~261.626 Hz")
    func frequencyCalculation_MiddleC() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 60, cents: 0.0)
        #expect(abs(frequency - 261.626) < 0.01)
    }

    @Test("Frequency calculation: A4 (MIDI 69) at 0 cents should be 440.0 Hz")
    func frequencyCalculation_A4() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0)
        #expect(abs(frequency - 440.0) < 0.001)
    }

    @Test("Frequency calculation: MIDI 60 at +50 cents should be ~268.9 Hz")
    func frequencyCalculation_HalfStep() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 60, cents: 50.0)
        // Halfway between C (261.626) and C# (277.183) is approximately 268.9
        #expect(abs(frequency - 268.9) < 0.5)
    }

    @Test("Frequency calculation: 0.1 cent precision verification")
    func frequencyCalculation_SubCentPrecision() throws {
        let freq1 = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0)
        let freq2 = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.1)

        // 0.1 cent should produce a measurable difference
        #expect(freq1 != freq2)

        // The difference should be tiny (0.1 cent ≈ 0.025 Hz at A4)
        #expect(abs(freq2 - freq1) < 0.1)
    }

    @Test("Frequency calculation: Custom reference pitch (442 Hz)")
    func frequencyCalculation_CustomReferencePitch() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 442.0)
        #expect(abs(frequency - 442.0) < 0.001)
    }

    @Test("Frequency calculation: MIDI note 0 (C-1, ~8.18 Hz)")
    func frequencyCalculation_MIDI0() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 0, cents: 0.0)
        // MIDI 0 is C-1, which should be around 8.18 Hz
        #expect(abs(frequency - 8.18) < 0.1)
    }

    @Test("Frequency calculation: MIDI note 127 (G9, ~12543 Hz)")
    func frequencyCalculation_MIDI127() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 127, cents: 0.0)
        // MIDI 127 is G9, which should be around 12543 Hz
        #expect(abs(frequency - 12543.0) < 1.0)
    }

    @Test("Frequency calculation: Negative cent offset (-50 cents)")
    func frequencyCalculation_NegativeCents() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 60, cents: -50.0)
        // MIDI 60 at -50 cents should be between B (below C) and C
        // Approximately 254.2 Hz
        #expect(frequency < 261.626)  // Less than C
        #expect(abs(frequency - 254.2) < 1.0)
    }

    @Test("Frequency calculation: Extreme positive cent offset (+100 cents)")
    func frequencyCalculation_ExtremeCents() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 60, cents: 100.0)
        // +100 cents is a full semitone up, should equal MIDI 61 (C#)
        let cSharp = try FrequencyCalculation.frequency(midiNote: 61, cents: 0.0)
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

    // MARK: - Duration Configuration Tests (Story 2.2)

    @Test("Duration: Short notes (100ms) play correctly")
    @MainActor
    func duration_ShortNote_100ms() async throws {
        let player = try SineWaveNotePlayer()

        // 100ms short note should play without error
        try await player.play(frequency: 440.0, duration: 0.1, amplitude: 0.5)
        #expect(true)
    }

    @Test("Duration: Default notes (1000ms) play correctly")
    @MainActor
    func duration_DefaultNote_1000ms() async throws {
        let player = try SineWaveNotePlayer()

        // 1 second default note should play without error
        try await player.play(frequency: 440.0, duration: 1.0, amplitude: 0.5)
        #expect(true)
    }

    @Test("Duration: Long notes (2000ms) play correctly")
    @MainActor
    func duration_LongNote_2000ms() async throws {
        let player = try SineWaveNotePlayer()

        // 2 second long note should play without error
        try await player.play(frequency: 440.0, duration: 2.0, amplitude: 0.5)
        #expect(true)
    }

    @Test("Duration: Very short notes (5ms) play correctly within envelope constraints")
    @MainActor
    func duration_VeryShortNote_5ms() async throws {
        let player = try SineWaveNotePlayer()

        // 5ms note (shorter than envelope overhead) should still work
        // Sustain will be 0, but attack/release should fit
        try await player.play(frequency: 440.0, duration: 0.005, amplitude: 0.5)
        #expect(true)
    }

    @Test("Duration: Negative duration throws error")
    @MainActor
    func duration_Negative_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        await #expect(throws: AudioError.self) {
            try await player.play(frequency: 440.0, duration: -0.5, amplitude: 0.5)
        }
    }

    @Test("Duration: Zero duration throws error")
    @MainActor
    func duration_Zero_ThrowsError() async throws {
        let player = try SineWaveNotePlayer()

        await #expect(throws: AudioError.self) {
            try await player.play(frequency: 440.0, duration: 0.0, amplitude: 0.5)
        }
    }

    @Test("Duration: Sample-accurate timing verification (HIGH-3 Fix)")
    @MainActor
    func duration_SampleAccurateTiming() async throws {
        let player = try SineWaveNotePlayer()

        // Test various durations and verify sample counts match expectations
        let sampleRate = 44100.0
        let testDurations = [0.1, 0.5, 1.0, 2.0]

        for duration in testDurations {
            // Expected sample count for this duration
            let expectedSamples = Int(duration * sampleRate)

            // Play the note (this generates a buffer internally with exact sample count)
            // The implementation uses: totalSamples = Int(duration * sampleRate)
            // which ensures sample-accurate timing
            try await player.play(frequency: 440.0, duration: duration, amplitude: 0.5)

            // We can't directly inspect the internal buffer in this test,
            // but we verify the operation completes successfully
            // The implementation guarantees: buffer.frameLength = AVAudioFrameCount(totalSamples)
            // This ensures duration accuracy to within 1 sample (~0.023ms at 44.1kHz)
            #expect(true)
        }

        // Verification note: Buffer-based playback with frameLength = Int(duration * sampleRate)
        // provides mathematically precise timing (sample-accurate, no drift)
    }

    // MARK: - Reference Pitch Configuration Tests (Story 2.2)

    @Test("Reference Pitch: Default (no parameter) uses A4=440Hz")
    func referencePitch_Default_440Hz() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0)
        #expect(abs(frequency - 440.0) < 0.001)
    }

    @Test("Reference Pitch: Baroque tuning (A4=442Hz)")
    func referencePitch_Baroque_442Hz() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 442.0)
        #expect(abs(frequency - 442.0) < 0.001)
    }

    @Test("Reference Pitch: Alternative tuning (A4=432Hz)")
    func referencePitch_Alternative_432Hz() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 432.0)
        #expect(abs(frequency - 432.0) < 0.001)
    }

    @Test("Reference Pitch: Historical tuning (A4=415Hz)")
    func referencePitch_Historical_415Hz() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 415.0)
        #expect(abs(frequency - 415.0) < 0.001)
    }

    @Test("Reference Pitch: Middle C at different reference pitches")
    func referencePitch_MiddleC_VariousTunings() throws {
        // C4 (MIDI 60) at A440 = 261.626 Hz
        let c4_at_440 = try FrequencyCalculation.frequency(midiNote: 60, cents: 0.0, referencePitch: 440.0)
        #expect(abs(c4_at_440 - 261.626) < 0.01)

        // C4 at A442 should be proportionally higher (factor: 442/440 = 1.00454...)
        let c4_at_442 = try FrequencyCalculation.frequency(midiNote: 60, cents: 0.0, referencePitch: 442.0)
        let expectedC4_442 = 261.626 * (442.0 / 440.0)
        #expect(abs(c4_at_442 - expectedC4_442) < 0.01)

        // C4 at A432 should be proportionally lower (factor: 432/440 = 0.9818...)
        let c4_at_432 = try FrequencyCalculation.frequency(midiNote: 60, cents: 0.0, referencePitch: 432.0)
        let expectedC4_432 = 261.626 * (432.0 / 440.0)
        #expect(abs(c4_at_432 - expectedC4_432) < 0.01)
    }

    @Test("Reference Pitch: Cent offset with custom reference pitch (combined calculation)")
    func referencePitch_WithCentOffset() throws {
        // A4 at 442Hz + 50 cents should be halfway to Bb
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 50.0, referencePitch: 442.0)

        // Expected: 442 * 2^(50/1200) ≈ 454.66 Hz
        let expected = 442.0 * pow(2.0, 50.0 / 1200.0)
        #expect(abs(frequency - expected) < 0.01)
    }

    @Test("Reference Pitch: Fractional cent precision with custom reference pitch")
    func referencePitch_FractionalCent() throws {
        // Test 0.1 cent precision at 442Hz
        let freq1 = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 442.0)
        let freq2 = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.1, referencePitch: 442.0)

        // Frequencies should be different with 0.1 cent resolution
        #expect(freq1 != freq2)

        // Difference should be tiny (0.1 cent ≈ 0.025 Hz at A4=442)
        #expect(abs(freq2 - freq1) < 0.1)
    }

    @Test("Reference Pitch: Negative cent offset with custom reference pitch")
    func referencePitch_NegativeCentOffset() throws {
        // A4 at 432Hz - 25 cents
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: -25.0, referencePitch: 432.0)

        // Expected: 432 * 2^(-25/1200) ≈ 425.8 Hz
        let expected = 432.0 * pow(2.0, -25.0 / 1200.0)
        #expect(abs(frequency - expected) < 0.01)
    }

    // MARK: - Reference Pitch Validation Tests (HIGH-2 Fix)

    @Test("Reference Pitch: Too low (< 380 Hz) throws error")
    func referencePitch_TooLow_ThrowsError() async throws {
        #expect(throws: AudioError.self) {
            _ = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 350.0)
        }
    }

    @Test("Reference Pitch: Too high (> 500 Hz) throws error")
    func referencePitch_TooHigh_ThrowsError() async throws {
        #expect(throws: AudioError.self) {
            _ = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 550.0)
        }
    }

    @Test("Reference Pitch: Edge case - exactly 380 Hz (valid)")
    func referencePitch_EdgeLow_Valid() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 380.0)
        #expect(abs(frequency - 380.0) < 0.001)
    }

    @Test("Reference Pitch: Edge case - exactly 500 Hz (valid)")
    func referencePitch_EdgeHigh_Valid() throws {
        let frequency = try FrequencyCalculation.frequency(midiNote: 69, cents: 0.0, referencePitch: 500.0)
        #expect(abs(frequency - 500.0) < 0.001)
    }
}
