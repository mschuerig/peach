import AVFoundation
import os

final class SoundFontEngine {

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.peach.app", category: "SoundFontEngine")

    // MARK: - Audio Components

    private let engine: AVAudioEngine
    let sampler: AVAudioUnitSampler

    // MARK: - State

    private var isSessionConfigured = false
    private var loadedProgram: Int
    private var loadedBank: Int

    // MARK: - Constants

    nonisolated static let channel: UInt8 = 0
    private nonisolated static let defaultBankMSB: UInt8 = 0x79 // kAUSampler_DefaultMelodicBankMSB
    nonisolated static let pitchBendCenter: UInt16 = 8192

    /// Pitch bend range in semitones, set via MIDI RPN in `sendPitchBendRange()`.
    /// All pitch bend calculations derive their cent limits from this value.
    nonisolated static let pitchBendRangeSemitones: Int = 2

    /// Maximum pitch bend displacement in cents, derived from `pitchBendRangeSemitones`.
    nonisolated static let pitchBendRangeCents: Double = Double(pitchBendRangeSemitones) * 100.0

    // MARK: - SF2 URL

    private let sf2URL: URL

    // MARK: - Initialization

    init(library: SoundFontLibrary, initialProgram: Int, initialBank: Int) throws {
        self.sf2URL = library.sf2URL
        self.engine = AVAudioEngine()
        self.sampler = AVAudioUnitSampler()
        self.loadedProgram = initialProgram
        self.loadedBank = initialBank

        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        try engine.start()
        try sampler.loadSoundBankInstrument(
            at: sf2URL,
            program: UInt8(initialProgram),
            bankMSB: Self.defaultBankMSB,
            bankLSB: UInt8(initialBank)
        )

        sendPitchBendRange()

        logger.info("SoundFontEngine initialized with \(library.sf2URL.lastPathComponent), preset sf2:\(initialBank):\(initialProgram)")
    }

    // MARK: - Audio Session & Engine Lifecycle

    func ensureAudioSessionConfigured() throws {
        if !isSessionConfigured {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            isSessionConfigured = true
        }
    }

    func ensureEngineRunning() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    // MARK: - Preset Loading

    func loadPreset(program: Int, bank: Int = 0) async throws {
        guard (0...127).contains(program) else {
            throw AudioError.invalidPreset("Program \(program) outside valid MIDI range 0-127")
        }
        guard (0...127).contains(bank) else {
            throw AudioError.invalidPreset("Bank \(bank) outside valid range 0-127")
        }
        guard program != loadedProgram || bank != loadedBank else { return }

        try sampler.loadSoundBankInstrument(
            at: sf2URL,
            program: UInt8(clamping: program),
            bankMSB: Self.defaultBankMSB,
            bankLSB: UInt8(clamping: bank)
        )

        loadedProgram = program
        loadedBank = bank

        sendPitchBendRange()

        // Allow audio graph to settle after instrument load — without this delay
        // the first MIDI note-on after a preset switch produces no sound.
        try await Task.sleep(for: .milliseconds(20))

        logger.info("Loaded preset bank \(bank) program \(program)")
    }

    // MARK: - Immediate MIDI Dispatch

    func startNote(_ midiNote: UInt8, velocity: UInt8, amplitudeDB: AmplitudeDB, pitchBend: UInt16, channel: UInt8) {
        sampler.sendPitchBend(pitchBend, onChannel: channel)
        sampler.overallGain = Float(amplitudeDB.rawValue)
        sampler.startNote(midiNote, withVelocity: velocity, onChannel: channel)
    }

    func stopNote(_ midiNote: UInt8, channel: UInt8) {
        sampler.stopNote(midiNote, onChannel: channel)
    }

    func stopAllNotes(channel: UInt8, stopPropagationDelay: Duration) async {
        if stopPropagationDelay > .zero {
            sampler.volume = 0
            try? await Task.sleep(for: stopPropagationDelay)
        }
        sampler.sendController(123, withValue: 0, onChannel: channel)
        sampler.sendPitchBend(Self.pitchBendCenter, onChannel: channel)
        if stopPropagationDelay > .zero {
            sampler.volume = 1.0
        }
    }

    func sendPitchBend(_ value: UInt16, channel: UInt8) {
        sampler.sendPitchBend(value, onChannel: channel)
    }

    // MARK: - MIDI Helpers

    private func sendPitchBendRange() {
        // MIDI RPN 0x0000 (Pitch Bend Sensitivity): set range to ±pitchBendRangeSemitones
        sampler.sendController(101, withValue: 0, onChannel: Self.channel)   // RPN MSB
        sampler.sendController(100, withValue: 0, onChannel: Self.channel)   // RPN LSB
        sampler.sendController(6, withValue: UInt8(Self.pitchBendRangeSemitones), onChannel: Self.channel)  // Data Entry MSB (semitones)
        sampler.sendController(38, withValue: 0, onChannel: Self.channel)    // Data Entry LSB (cents)
    }
}
