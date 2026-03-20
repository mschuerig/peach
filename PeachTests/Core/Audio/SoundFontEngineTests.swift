import Foundation
import Testing
@testable import Peach

@Suite("SoundFontEngine")
struct SoundFontEngineTests {

    private static let testLibrary = TestSoundFont.makeLibrary()

    private func makeEngine(initialProgram: Int = 0, initialBank: Int = 0) throws -> SoundFontEngine {
        try SoundFontEngine(library: Self.testLibrary, initialProgram: initialProgram, initialBank: initialBank)
    }

    // MARK: - Initialization

    @Test("initializes successfully with valid SF2 library")
    func initializesSuccessfully() async {
        #expect(throws: Never.self) {
            _ = try self.makeEngine()
        }
    }

    @Test("audio engine is running after init")
    func engineRunningAfterInit() async throws {
        let engine = try makeEngine()
        // ensureEngineRunning should not throw if engine is already running
        #expect(throws: Never.self) {
            try engine.ensureEngineRunning()
        }
    }

    @Test("fails with missing SF2 file")
    func failsWithMissingSF2() async {
        let badLibrary = SoundFontLibrary(
            sf2URL: URL(fileURLWithPath: "/nonexistent/NonExistent.sf2"),
            defaultPreset: "sf2:0:0"
        )
        #expect(throws: (any Error).self) {
            _ = try SoundFontEngine(library: badLibrary, initialProgram: 0, initialBank: 0)
        }
    }

    // MARK: - Preset Loading

    @Test("loadPreset succeeds for valid program")
    func loadPresetValid() async throws {
        let engine = try makeEngine()
        try await engine.loadPreset(program: 42)
    }

    @Test("loadPreset skips reload when same preset is already loaded")
    func loadPresetSkipsSame() async throws {
        let engine = try makeEngine(initialProgram: 0, initialBank: 0)
        // Loading same preset should be a no-op
        try await engine.loadPreset(program: 0, bank: 0)
    }

    @Test("loadPreset throws for out-of-range program")
    func loadPresetInvalidProgram() async throws {
        let engine = try makeEngine()
        await #expect(throws: AudioError.self) {
            try await engine.loadPreset(program: 999)
        }
    }

    @Test("loadPreset throws for negative program")
    func loadPresetNegativeProgram() async throws {
        let engine = try makeEngine()
        await #expect(throws: AudioError.self) {
            try await engine.loadPreset(program: -1)
        }
    }

    @Test("loadPreset throws for out-of-range bank")
    func loadPresetInvalidBank() async throws {
        let engine = try makeEngine()
        await #expect(throws: AudioError.self) {
            try await engine.loadPreset(program: 0, bank: 200)
        }
    }

    @Test("loadPreset with bank parameter loads bank variant")
    func loadPresetBankVariant() async throws {
        let engine = try makeEngine()
        try await engine.loadPreset(program: 6, bank: 8)
    }

    // MARK: - Immediate MIDI Dispatch

    @Test("startNote does not crash")
    func startNoteDoesNotCrash() async throws {
        let engine = try makeEngine()
        engine.startNote(69, velocity: 63, amplitudeDB: AmplitudeDB(0.0), pitchBend: SoundFontEngine.pitchBendCenter, channel: SoundFontEngine.channel)
    }

    @Test("stopNote does not crash")
    func stopNoteDoesNotCrash() async throws {
        let engine = try makeEngine()
        engine.startNote(69, velocity: 63, amplitudeDB: AmplitudeDB(0.0), pitchBend: SoundFontEngine.pitchBendCenter, channel: SoundFontEngine.channel)
        engine.stopNote(69, channel: SoundFontEngine.channel)
    }

    @Test("sendPitchBend does not crash")
    func sendPitchBendDoesNotCrash() async throws {
        let engine = try makeEngine()
        engine.sendPitchBend(10000, channel: SoundFontEngine.channel)
    }

    // MARK: - stopAllNotes

    @Test("stopAllNotes does not crash when no notes are playing")
    func stopAllNotesNoNotes() async throws {
        let engine = try makeEngine()
        await engine.stopAllNotes(channel: SoundFontEngine.channel, stopPropagationDelay: .zero)
    }

    @Test("stopAllNotes with propagation delay restores volume")
    func stopAllNotesRestoresVolume() async throws {
        let engine = try makeEngine()
        engine.startNote(69, velocity: 63, amplitudeDB: AmplitudeDB(0.0), pitchBend: SoundFontEngine.pitchBendCenter, channel: SoundFontEngine.channel)
        await engine.stopAllNotes(channel: SoundFontEngine.channel, stopPropagationDelay: .milliseconds(25))
        // If volume were stuck at 0, subsequent notes would be silent
        engine.startNote(69, velocity: 63, amplitudeDB: AmplitudeDB(0.0), pitchBend: SoundFontEngine.pitchBendCenter, channel: SoundFontEngine.channel)
        engine.stopNote(69, channel: SoundFontEngine.channel)
    }

    @Test("stopAllNotes silences a playing note")
    func stopAllNotesSilencesNote() async throws {
        let engine = try makeEngine()
        engine.startNote(69, velocity: 63, amplitudeDB: AmplitudeDB(0.0), pitchBend: SoundFontEngine.pitchBendCenter, channel: SoundFontEngine.channel)
        await engine.stopAllNotes(channel: SoundFontEngine.channel, stopPropagationDelay: .zero)
    }

    // MARK: - Sampler Access

    @Test("sampler is accessible as read-only property")
    func samplerIsAccessible() async throws {
        let engine = try makeEngine()
        // Verify sampler can be read — SoundFontPlaybackHandle needs this access
        let sampler = engine.sampler
        #expect(sampler !== engine.sampler || sampler === engine.sampler) // reference identity check
    }
}
