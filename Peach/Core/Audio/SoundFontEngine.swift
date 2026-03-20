@preconcurrency import AVFoundation
import os

// MARK: - Scheduled MIDI Event

/// A MIDI event scheduled for sample-accurate dispatch on the audio render thread.
struct ScheduledMIDIEvent: Sendable {
    let sampleOffset: Int64
    let midiStatus: UInt8
    let midiNote: UInt8
    let velocity: UInt8
}

// MARK: - Schedule Data

/// All mutable state shared between the render thread and the main thread.
/// Access is synchronized via `OSAllocatedUnfairLock`.
nonisolated private struct ScheduleData: @unchecked Sendable {
    let buffer: UnsafeMutablePointer<ScheduledMIDIEvent>
    let capacity: Int
    var count: Int = 0
    var nextIndex: Int = 0
    var samplePosition: Int64 = 0
    var midiBlock: AUScheduleMIDIEventBlock?
}

final class SoundFontEngine {

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.peach.app", category: "SoundFontEngine")

    // MARK: - Audio Components

    private let engine: AVAudioEngine
    private let sampler: AVAudioUnitSampler
    private let sourceNode: AVAudioSourceNode

    // MARK: - State

    private var loadedPreset: SF2Preset
    private var activeMuteCount = 0

    // MARK: - Constants

    private nonisolated static let channel: UInt8 = 0
    private nonisolated static let defaultBankMSB: UInt8 = 0x79 // kAUSampler_DefaultMelodicBankMSB

    /// Pitch bend range in semitones, set via MIDI RPN in `sendPitchBendRange()`.
    /// All pitch bend calculations derive their cent limits from this value.
    nonisolated static let pitchBendRangeSemitones: Int = 2

    /// Maximum pitch bend displacement in cents, derived from `pitchBendRangeSemitones`.
    nonisolated static let pitchBendRangeCents: Double = Double(pitchBendRangeSemitones) * 100.0

    private nonisolated static let scheduleCapacity = 4096

    // MARK: - SF2 URL

    private let sf2URL: URL

    // MARK: - Render-Thread Schedule Storage

    /// Pre-allocated event buffer, owned by SoundFontEngine for deallocation.
    private let scheduleBuffer: UnsafeMutablePointer<ScheduledMIDIEvent>

    /// Synchronized access to schedule state. The render thread uses `withLockIfAvailable`
    /// (try-lock, non-blocking) so it never stalls the audio pipeline. The main thread
    /// uses `withLock` (blocking, acceptable off the render thread).
    private let scheduleLockState: OSAllocatedUnfairLock<ScheduleData>

    // MARK: - Initialization

    init(library: SoundFontLibrary, soundSource: any SoundSourceID) throws {
        let preset = library.resolve(soundSource)
        self.sf2URL = library.sf2URL
        self.loadedPreset = preset

        let engine = AVAudioEngine()
        let sampler = AVAudioUnitSampler()
        self.engine = engine
        self.sampler = sampler

        // Pre-allocate event buffer
        let scheduleBuffer = UnsafeMutablePointer<ScheduledMIDIEvent>.allocate(capacity: Self.scheduleCapacity)
        self.scheduleBuffer = scheduleBuffer

        // Attach and connect sampler
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        try Self.configureAudioSession()
        try engine.start()
        try sampler.loadSoundBankInstrument(
            at: library.sf2URL,
            program: UInt8(preset.program),
            bankMSB: Self.defaultBankMSB,
            bankLSB: UInt8(preset.bank)
        )

        // Create lock state with MIDI event block (available after engine start)
        let lockState = OSAllocatedUnfairLock(initialState: ScheduleData(
            buffer: scheduleBuffer,
            capacity: Self.scheduleCapacity,
            midiBlock: sampler.auAudioUnit.scheduleMIDIEventBlock
        ))
        self.scheduleLockState = lockState

        // Create source node (outputs silence, serves as render-thread clock)
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let sourceNode = AVAudioSourceNode(format: sourceFormat) { @Sendable
            isSilence, timestamp, frameCount, outputData -> OSStatus in

            isSilence.pointee = true
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            for buf in abl {
                if let data = buf.mData {
                    memset(data, 0, Int(buf.mDataByteSize))
                }
            }

            // Read sample time before entering lock to avoid capturing non-Sendable pointer
            let hostSampleTime = AUEventSampleTime(timestamp.pointee.mSampleTime)

            // Try-lock: if the main thread is updating the schedule, skip this frame
            // rather than blocking the audio render thread.
            _ = lockState.withLockIfAvailable { data in
                guard let midiBlock = data.midiBlock, data.count > 0 else { return }

                let windowStart = data.samplePosition
                let windowEnd = windowStart + Int64(frameCount)

                while data.nextIndex < data.count {
                    let event = data.buffer[data.nextIndex]
                    if event.sampleOffset >= windowEnd { break }
                    if event.sampleOffset >= windowStart {
                        let intraBufferOffset = event.sampleOffset - windowStart
                        let absoluteSampleTime = hostSampleTime
                            + AUEventSampleTime(intraBufferOffset)
                        var midiBytes = (event.midiStatus, event.midiNote, event.velocity)
                        withUnsafePointer(to: &midiBytes) { tuplePtr in
                            tuplePtr.withMemoryRebound(to: UInt8.self, capacity: 3) { bytesPtr in
                                midiBlock(absoluteSampleTime, 0, 3, bytesPtr)
                            }
                        }
                    }
                    data.nextIndex += 1
                }

                data.samplePosition = windowEnd
            }

            return noErr
        }
        self.sourceNode = sourceNode

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: sourceFormat)

        sendPitchBendRange()

        logger.info("SoundFontEngine initialized with \(library.sf2URL.lastPathComponent), preset \(preset.rawValue)")
    }

    isolated deinit {
        engine.stop()
        scheduleBuffer.deallocate()
    }

    // MARK: - Audio Session & Engine Lifecycle

    func ensureAudioSessionConfigured() throws {
        try Self.configureAudioSession()
    }

    func ensureEngineRunning() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    // MARK: - Preset Loading

    func loadPreset(_ preset: SF2Preset) async throws {
        guard (0...127).contains(preset.program) else {
            throw AudioError.invalidPreset("Program \(preset.program) outside valid MIDI range 0-127")
        }
        guard (0...127).contains(preset.bank) else {
            throw AudioError.invalidPreset("Bank \(preset.bank) outside valid range 0-127")
        }
        guard preset != loadedPreset else { return }

        try sampler.loadSoundBankInstrument(
            at: sf2URL,
            program: UInt8(clamping: preset.program),
            bankMSB: Self.defaultBankMSB,
            bankLSB: UInt8(clamping: preset.bank)
        )

        loadedPreset = preset

        sendPitchBendRange()

        // Allow audio graph to settle after instrument load — without this delay
        // the first MIDI note-on after a preset switch produces no sound.
        try await Task.sleep(for: .milliseconds(20))

        logger.info("Loaded preset \(preset.rawValue)")
    }

    // MARK: - Immediate MIDI Dispatch

    func startNote(_ midiNote: MIDINote, velocity: MIDIVelocity, amplitudeDB: AmplitudeDB, pitchBend: PitchBendValue) {
        sampler.sendPitchBend(pitchBend.rawValue, onChannel: Self.channel)
        sampler.overallGain = Float(amplitudeDB.rawValue)
        sampler.startNote(UInt8(midiNote.rawValue), withVelocity: velocity.rawValue, onChannel: Self.channel)
    }

    func stopNote(_ midiNote: MIDINote) {
        sampler.stopNote(UInt8(midiNote.rawValue), onChannel: Self.channel)
    }

    func stopAllNotes(stopPropagationDelay: Duration) async {
        if stopPropagationDelay > .zero {
            muteForFade()
            try? await Task.sleep(for: stopPropagationDelay)
        }
        sampler.sendController(123, withValue: 0, onChannel: Self.channel)
        sampler.sendPitchBend(PitchBendValue.center.rawValue, onChannel: Self.channel)
        if stopPropagationDelay > .zero {
            restoreAfterFade()
        }
    }

    func sendPitchBend(_ value: PitchBendValue) {
        sampler.sendPitchBend(value.rawValue, onChannel: Self.channel)
    }

    // MARK: - Volume Fade

    func muteForFade() {
        activeMuteCount += 1
        sampler.volume = 0
    }

    func restoreAfterFade() {
        activeMuteCount -= 1
        if activeMuteCount <= 0 {
            activeMuteCount = 0
            sampler.volume = 1.0
        }
    }

    // MARK: - Audio Session

    private static func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    // MARK: - Render-Thread Scheduling

    func scheduleEvents(_ events: [ScheduledMIDIEvent]) {
        scheduleLockState.withLock { data in
            let count = min(events.count, data.capacity)
            for i in 0..<count {
                data.buffer[i] = events[i]
            }
            data.count = count
            data.nextIndex = 0
            data.samplePosition = 0
        }
    }

    func clearSchedule() {
        scheduleLockState.withLock { data in
            data.count = 0
            data.nextIndex = 0
            data.samplePosition = 0
        }
    }

    var scheduledEventCount: Int {
        scheduleLockState.withLock { data in data.count }
    }

    // MARK: - Audio Buffer Configuration

    func configureForRhythmScheduling() throws {
        try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
    }

    func restoreDefaultBufferDuration() throws {
        try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0)
    }

    // MARK: - Schedule Scanning (testable pure function)

    nonisolated static func scanSchedule(
        events: [ScheduledMIDIEvent],
        fromIndex: Int,
        windowStart: Int64,
        windowEnd: Int64
    ) -> (dispatched: [ScheduledMIDIEvent], nextIndex: Int) {
        var dispatched: [ScheduledMIDIEvent] = []
        var index = fromIndex
        while index < events.count {
            let event = events[index]
            if event.sampleOffset >= windowEnd { break }
            if event.sampleOffset >= windowStart {
                dispatched.append(event)
            }
            index += 1
        }
        return (dispatched, index)
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
