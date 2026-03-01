import Testing
import Foundation
@testable import Peach

// @Test(arguments:) is incompatible with default MainActor isolation in Swift 6.2:
// the macro expansion accesses static properties from a nonisolated context, and
// SoundFontLibrary() can't be called outside MainActor. All tests use for loops
// with Issue.record for per-case failure reporting instead.

@Suite("SoundFont Preset Stress Tests",
       .enabled(if: ProcessInfo.processInfo.environment["RUN_STRESS_TESTS"] != nil))
struct SoundFontPresetStressTests {

    // MARK: - Constants

    private static let representativeTags: Set<String> = [
        "sf2:0:0", "sf2:0:24", "sf2:0:42",
        "sf2:0:48", "sf2:0:56", "sf2:0:73", "sf2:8:80"
    ]

    private static let focusTags: Set<String> = [
        "sf2:0:0", "sf2:0:42", "sf2:0:73", "sf2:8:80"
    ]

    private static let midiNoteValues: [UInt8] = [0, 21, 36, 48, 60, 69, 84, 96, 108, 127]

    // MARK: - Factory

    private func makePlayer() throws -> SoundFontNotePlayer {
        try SoundFontNotePlayer(userSettings: MockUserSettings(), stopPropagationDelay: .zero)
    }

    // MARK: - Task 2: Per-Preset Smoke Test

    @Test("Every preset loads and plays a note without crash")
    func presetSmoke() async throws {
        let allPresets = SoundFontLibrary().availablePresets
        #expect(!allPresets.isEmpty, "SoundFontLibrary discovered no presets")

        for preset in allPresets {
            let player = try makePlayer()
            do {
                try await player.loadPreset(program: preset.program, bank: preset.bank)
                let handle = try await player.play(frequency: 440.0, velocity: 63, amplitudeDB: 0.0)
                try await Task.sleep(for: .milliseconds(100))
                try await handle.stop()
            } catch {
                Issue.record(
                    "Preset '\(preset.name)' (bank \(preset.bank), program \(preset.program)) failed: \(error)"
                )
            }
        }
    }

    // MARK: - Task 3: MIDI Note Range Sweep

    @Test("Representative presets play across MIDI note range without crash")
    func midiNoteRangeSweep() async throws {
        let presets = SoundFontLibrary().availablePresets.filter {
            Self.representativeTags.contains($0.tag)
        }
        #expect(!presets.isEmpty, "No representative presets found")

        for preset in presets {
            let player = try makePlayer()
            try await player.loadPreset(program: preset.program, bank: preset.bank)

            for midiNote in Self.midiNoteValues {
                let frequency = TuningSystem.equalTemperament.frequency(
                    for: MIDINote(Int(midiNote)),
                    referencePitch: .concert440
                )
                do {
                    let handle = try await player.play(
                        frequency: frequency, velocity: 63, amplitudeDB: 0.0
                    )
                    try await Task.sleep(for: .milliseconds(100))
                    try await handle.stop()
                } catch {
                    Issue.record(
                        "Preset '\(preset.name)' (bank \(preset.bank), program \(preset.program)) failed at MIDI note \(midiNote): \(error)"
                    )
                }
            }
        }
    }

    // MARK: - Task 4: Duration Variation

    @Test("Varied durations do not crash for focus presets")
    func durationVariation() async throws {
        let presets = SoundFontLibrary().availablePresets.filter {
            Self.focusTags.contains($0.tag)
        }
        let durations: [TimeInterval] = [0.01, 0.1, 0.5]

        for preset in presets {
            let player = try makePlayer()
            try await player.loadPreset(program: preset.program, bank: preset.bank)

            for duration in durations {
                do {
                    try await player.play(
                        frequency: 440.0, duration: duration, velocity: 63, amplitudeDB: 0.0
                    )
                } catch {
                    Issue.record(
                        "Preset '\(preset.name)' (bank \(preset.bank), program \(preset.program)) failed at duration \(duration)s: \(error)"
                    )
                }
            }
        }
    }

    // MARK: - Task 5: Velocity Variation

    @Test("Varied velocities do not crash for focus presets")
    func velocityVariation() async throws {
        let presets = SoundFontLibrary().availablePresets.filter {
            Self.focusTags.contains($0.tag)
        }
        let velocities: [MIDIVelocity] = [1, 63, 127]

        for preset in presets {
            let player = try makePlayer()
            try await player.loadPreset(program: preset.program, bank: preset.bank)

            for velocity in velocities {
                do {
                    let handle = try await player.play(
                        frequency: 440.0, velocity: velocity, amplitudeDB: 0.0
                    )
                    try await Task.sleep(for: .milliseconds(100))
                    try await handle.stop()
                } catch {
                    Issue.record(
                        "Preset '\(preset.name)' (bank \(preset.bank), program \(preset.program)) failed at velocity \(velocity.rawValue): \(error)"
                    )
                }
            }
        }
    }

    // MARK: - Task 6: Rapid Preset Switching

    @Test("Rapid preset loading without play does not crash")
    func rapidPresetLoadOnly() async throws {
        let player = try makePlayer()
        let presets = Array(SoundFontLibrary().availablePresets.prefix(15))

        for preset in presets {
            try await player.loadPreset(program: preset.program, bank: preset.bank)
        }
    }

    @Test("Load-play-stop-switch cycle does not crash")
    func loadPlayStopSwitchCycle() async throws {
        let player = try makePlayer()
        let presets = Array(SoundFontLibrary().availablePresets.prefix(8))

        for preset in presets {
            try await player.loadPreset(program: preset.program, bank: preset.bank)
            let handle = try await player.play(frequency: 440.0, velocity: 63, amplitudeDB: 0.0)
            try await Task.sleep(for: .milliseconds(50))
            try await handle.stop()
        }
    }
}
