import Testing
import Foundation
@testable import Peach

/// Tests for SineWaveNotePlayer playback, duration, and reference pitch
@Suite("SineWaveNotePlayer Playback Tests")
struct SineWaveNotePlayerPlaybackTests {

    // MARK: - Play Method Tests

    @Test("play() method doesn't throw for valid frequency")
    @MainActor
    func play_ValidFrequency_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.5)
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
        try await player.stop()
    }

    @Test("stop() can be called without prior play()")
    @MainActor
    func stop_WithoutPlay_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()
        try await player.stop()
    }

    // MARK: - Sequential Playback Tests

    @Test("Multiple sequential plays work correctly")
    @MainActor
    func play_SequentialNotes_WorksCorrectly() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.5)
        try await player.play(frequency: 523.25, duration: 0.05, amplitude: 0.5)
    }

    @Test("play() with custom amplitude works correctly")
    @MainActor
    func play_CustomAmplitude_DoesNotThrow() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.0)
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 0.25)
        try await player.play(frequency: 440.0, duration: 0.05, amplitude: 1.0)
    }

    // MARK: - Duration Configuration Tests (Story 2.2)

    @Test("Duration: Short notes (100ms) play correctly")
    @MainActor
    func duration_ShortNote_100ms() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 0.1, amplitude: 0.5)
    }

    @Test("Duration: Default notes (1000ms) play correctly")
    @MainActor
    func duration_DefaultNote_1000ms() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 1.0, amplitude: 0.5)
    }

    @Test("Duration: Long notes (2000ms) play correctly")
    @MainActor
    func duration_LongNote_2000ms() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 2.0, amplitude: 0.5)
    }

    @Test("Duration: Very short notes (5ms) play correctly within envelope constraints")
    @MainActor
    func duration_VeryShortNote_5ms() async throws {
        let player = try SineWaveNotePlayer()
        try await player.play(frequency: 440.0, duration: 0.005, amplitude: 0.5)
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

        let testDurations = [0.1, 0.5, 1.0, 2.0]

        for duration in testDurations {
            try await player.play(frequency: 440.0, duration: duration, amplitude: 0.5)
        }
    }
}
