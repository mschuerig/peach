# Story 46.1: Extract SoundFontEngine from SoundFontNotePlayer

Status: ready-for-dev

## Story

As a **developer**,
I want a `SoundFontEngine` class that owns `AVAudioEngine`, `AVAudioUnitSampler`, and audio session configuration,
So that audio hardware ownership is consolidated in one place before adding rhythm playback.

## Acceptance Criteria

1. **Given** `SoundFontEngine` is created, **when** inspected, **then** it owns `AVAudioEngine` and `AVAudioUnitSampler` (melodic) that were previously owned by `SoundFontNotePlayer`.

2. **Given** `SoundFontEngine`, **when** it provides immediate MIDI dispatch, **then** `startNote`/`stopNote` methods are available for pitch training (existing behavior).

3. **Given** `SoundFontEngine`, **when** it manages SoundFont preset loading, **then** it loads presets for the melodic bank using existing `SoundFontLibrary` infrastructure.

4. **Given** `SoundFontEngine` is a concrete internal class (not a protocol), **when** created, **then** it is placed at `Core/Audio/SoundFontEngine.swift` with tests at `PeachTests/Core/Audio/SoundFontEngineTests.swift`.

## Tasks / Subtasks

- [ ] Task 1: Create `SoundFontEngine` class with audio graph ownership (AC: #1, #4)
  - [ ] Create `Peach/Core/Audio/SoundFontEngine.swift`
  - [ ] Move `AVAudioEngine` and `AVAudioUnitSampler` ownership from `SoundFontNotePlayer` into `SoundFontEngine`
  - [ ] Move `isSessionConfigured`, `loadedProgram`, `loadedBank` state into `SoundFontEngine`
  - [ ] Move audio session configuration (`ensureAudioSessionConfigured()`) into `SoundFontEngine`
  - [ ] Move engine lifecycle (`ensureEngineRunning()`) into `SoundFontEngine`
  - [ ] Move pitch bend range RPN setup (`sendPitchBendRange()`) into `SoundFontEngine`
  - [ ] `init(library: SoundFontLibrary, initialProgram: Int, initialBank: Int) throws` — creates engine, attaches sampler, loads initial preset, starts engine

- [ ] Task 2: Add immediate MIDI dispatch methods (AC: #2)
  - [ ] `func startNote(_ midiNote: UInt8, velocity: UInt8, amplitudeDB: AmplitudeDB, pitchBend: UInt16, channel: UInt8)` — sends pitch bend, sets gain, starts MIDI note
  - [ ] `func stopNote(_ midiNote: UInt8, channel: UInt8)` — stops a single MIDI note
  - [ ] `func stopAllNotes(channel: UInt8, stopPropagationDelay: Duration)` — fade volume, CC 123 All Notes Off, reset pitch bend, restore volume
  - [ ] `func sendPitchBend(_ value: UInt16, channel: UInt8)` — pitch bend for frequency adjustment
  - [ ] Expose `sampler` as read-only for `SoundFontPlaybackHandle` (or provide methods it needs)

- [ ] Task 3: Add preset loading (AC: #3)
  - [ ] `func loadPreset(program: Int, bank: Int) async throws` — validates range, skips if already loaded, calls `sampler.loadSoundBankInstrument(at:program:bankMSB:bankLSB:)`, logs change
  - [ ] Move `sf2URL` storage from `SoundFontNotePlayer` into `SoundFontEngine` (engine receives it from `SoundFontLibrary`)

- [ ] Task 4: Write `SoundFontEngine` tests (AC: #4)
  - [ ] Create `PeachTests/Core/Audio/SoundFontEngineTests.swift`
  - [ ] Test initialization succeeds with valid SF2 library
  - [ ] Test audio engine is running after init
  - [ ] Test preset loading (valid programs, skip-if-same, invalid range throws)
  - [ ] Test immediate dispatch methods exist and are callable
  - [ ] Test `stopAllNotes` behavior

- [ ] Task 5: Build and full test suite verification
  - [ ] `bin/build.sh` — zero errors, zero warnings
  - [ ] `bin/test.sh` — full suite passes, zero regressions

## Dev Notes

### This is an extraction — not a rewrite

This story creates `SoundFontEngine` and moves audio-graph ownership into it. It does NOT yet refactor `SoundFontNotePlayer` to delegate — that is story 46.2. After this story, `SoundFontEngine` exists as a standalone class and `SoundFontNotePlayer` still works as before (both may temporarily own audio infrastructure until 46.2 connects them).

**However**, the preferred approach is: if you can cleanly extract AND have `SoundFontNotePlayer` delegate to the engine in one step without breaking tests, that's acceptable. The key constraint is that this story's acceptance criteria are met — `SoundFontEngine` exists with the specified capabilities. Story 46.2 will formalize the delegation and verify all existing tests pass unchanged.

### What moves into SoundFontEngine

From the current `SoundFontNotePlayer` (at `Peach/Core/Audio/SoundFontNotePlayer.swift`):

| Current SoundFontNotePlayer member | Destination |
|-------------------------------------|-------------|
| `private let engine: AVAudioEngine` | `SoundFontEngine` |
| `private let sampler: AVAudioUnitSampler` | `SoundFontEngine` |
| `private var isSessionConfigured: Bool` | `SoundFontEngine` |
| `private var loadedProgram: Int` | `SoundFontEngine` |
| `private var loadedBank: Int` | `SoundFontEngine` |
| `ensureAudioSessionConfigured()` | `SoundFontEngine` |
| `ensureEngineRunning()` | `SoundFontEngine` |
| `sendPitchBendRange()` | `SoundFontEngine` |
| `loadPreset(program:bank:)` | `SoundFontEngine` |
| Sampler attachment to engine graph | `SoundFontEngine.init` |
| Engine start in init | `SoundFontEngine.init` |

### What stays in SoundFontNotePlayer

These remain in `SoundFontNotePlayer` (they are NotePlayer-domain logic, not engine concerns):

| Member | Reason |
|--------|--------|
| `play(frequency:velocity:amplitudeDB:) -> PlaybackHandle` | NotePlayer protocol method |
| `stopAll()` | NotePlayer protocol method |
| `ensurePresetLoaded()` | Reads `userSettings.soundSource`, resolves via library — user-facing behavior |
| `validateFrequency(_:)` | Domain validation |
| `startNote(frequency:velocity:amplitudeDB:) -> UInt8` | Frequency decomposition + pitch bend calculation (calls engine's MIDI dispatch) |
| `decompose(frequency:)` | Static helper: Hz → MIDI + cents |
| `pitchBendValue(forCents:)` | Static helper: cents → pitch bend value |
| Constants (`channel`, `pitchBendCenter`, etc.) | Some may move to engine; decompose/pitchBend constants stay |
| `library: SoundFontLibrary` dependency | For preset resolution |
| `userSettings: UserSettings` dependency | For sound source selection |

### SoundFontEngine design constraints (from architecture.md)

- **Not a protocol** — concrete internal `final class`. Single implementation behind both `SoundFontNotePlayer` and `SoundFontRhythmPlayer`
- **File location**: `Core/Audio/SoundFontEngine.swift`
- **Owns**: `AVAudioEngine`, `AVAudioUnitSampler` (melodic), audio session config
- **Provides**: immediate MIDI dispatch (`startNote`/`stopNote`) for pitch training
- **Future additions** (NOT in this story): `AVAudioSourceNode` for render-thread scheduling (story 46.3), percussion sampler (story 46.4)
- **Do not add render-thread scheduling infrastructure** — that is 46.3
- **Do not add percussion bank support** — that is 46.4

### SoundFontPlaybackHandle consideration

`SoundFontPlaybackHandle` currently holds a direct reference to `AVAudioUnitSampler` for `stopNote` and `adjustFrequency`. After extraction, it needs access to the engine's sampler (or the engine's MIDI dispatch methods). Options:
1. `SoundFontPlaybackHandle` receives a reference to `SoundFontEngine` instead of `AVAudioUnitSampler`
2. `SoundFontPlaybackHandle` receives the sampler from the engine (engine exposes it)
3. `SoundFontPlaybackHandle` receives closure callbacks

Option 2 is simplest for this story (minimal changes to `SoundFontPlaybackHandle`). Option 1 is cleaner long-term. Choose based on what keeps the diff smallest while remaining clean.

### Constants that may need sharing

`SoundFontNotePlayer` has these `nonisolated static` constants:
- `channel: UInt8 = 0` — MIDI channel. Engine needs this for dispatch. Consider making it an engine property or parameter
- `defaultBankMSB: UInt8 = 0x79` — `kAUSampler_DefaultMelodicBankMSB`. Engine needs this for preset loading
- `pitchBendCenter: UInt16 = 8192` — Engine needs for pitch bend reset
- `pitchBendRangeSemitones: Int = 2` / `pitchBendRangeCents: Double = 200.0` — Engine needs for pitch bend range RPN
- `stopPropagationDelay: Duration` — Currently a property; engine's `stopAllNotes` needs it as a parameter
- `validFrequencyRange` — Stays in `SoundFontNotePlayer` (domain validation)

### Existing test suite (66 tests in SoundFontNotePlayerTests)

All existing `SoundFontNotePlayerTests` must continue to pass. Do not modify existing tests — they validate the `NotePlayer` protocol contract which is unchanged. New `SoundFontEngineTests` test the engine's lower-level MIDI dispatch and preset management.

### Initialization pattern

Current `SoundFontNotePlayer` init:
```swift
init(library: SoundFontLibrary, userSettings: UserSettings, stopPropagationDelay: Duration = .milliseconds(25)) throws
```

New `SoundFontEngine` init should be similar but without `userSettings` (engine doesn't know about user preferences — that's `SoundFontNotePlayer`'s concern):
```swift
init(library: SoundFontLibrary, initialProgram: Int, initialBank: Int) throws
```

The engine receives the SF2 URL from the library, creates the audio graph, loads the initial preset, and starts the engine.

### PeachApp.swift wiring (story 46.2 scope)

Do NOT modify `PeachApp.swift` in this story. Story 46.2 will update the composition root to create `SoundFontEngine` first, then pass it to `SoundFontNotePlayer`. For now, `SoundFontEngine` is created and tested independently.

### Testing approach

Since `SoundFontEngine` operates at the MIDI level (not the frequency/domain level), tests should:
- Use `TestSoundFont.makeLibrary()` for a pre-configured library (same as `SoundFontNotePlayerTests`)
- Verify engine starts and runs
- Verify preset loading (valid, skip-if-same, invalid-range)
- Verify `startNote`/`stopNote` don't crash (MIDI dispatch is fire-and-forget on the sampler)
- Verify `stopAllNotes` sends CC 123 and resets state
- All tests must be `async` (default MainActor isolation)
- Use `@Suite("SoundFontEngine")` struct-based suite
- Follow mock contract if introducing any mocks

### Anti-patterns to avoid

- **Do NOT create a protocol for SoundFontEngine** — architecture explicitly says "concrete internal class, not a protocol"
- **Do NOT add render-thread scheduling** — that is story 46.3 (`AVAudioSourceNode`, `scheduleMIDIEventBlock`)
- **Do NOT add percussion sampler** — that is story 46.4
- **Do NOT modify `NotePlayer` or `PlaybackHandle` protocols** — they are unchanged
- **Do NOT modify `PeachApp.swift`** — wiring happens in story 46.2
- **Do NOT use XCTest** — Swift Testing only
- **Do NOT add explicit `@MainActor`** — redundant with default isolation
- **Do NOT add `import Foundation`** in `SoundFontEngine.swift` unless needed — use `import AVFoundation` (which includes what's needed)
- **Do NOT add `import Combine`** — forbidden by project rules
- **Do NOT create a second `AVAudioEngine` instance** — the point of this extraction is to have ONE engine. Currently `SoundFontNotePlayer` owns it; after this story, `SoundFontEngine` owns it

### Previous story learnings (from epic 45)

- `nonisolated init` pattern needed for `Sendable` value types constructed off main actor — `SoundFontEngine` is a class, so default `@MainActor` init is fine
- Minimal protocols, no doc comments listing future conforming types
- Code review of 45.2 removed `Comparable` from `RhythmOffset` — don't assume types need conformances not in AC
- Follow existing file patterns: `Core/Audio/` directory, test directory mirrors source

### Project Structure Notes

New files:
- `Peach/Core/Audio/SoundFontEngine.swift` — new class
- `PeachTests/Core/Audio/SoundFontEngineTests.swift` — new tests

No modifications to existing files in this story (or minimal — see "extraction vs standalone" note above).

Existing `Core/Audio/` directory: `NotePlayer.swift`, `PlaybackHandle.swift`, `SoundFontNotePlayer.swift`, `SoundFontPlaybackHandle.swift`, `SoundFontLibrary.swift`, `SF2PresetParser.swift`, `SoundSourceProvider.swift`, `AudioSessionInterruptionMonitor.swift`.

### References

- [Source: docs/planning-artifacts/epics.md#Epic 46, Story 46.1]
- [Source: docs/planning-artifacts/architecture.md#Layer 1: SoundFontEngine]
- [Source: docs/planning-artifacts/architecture.md#Layer 2: SoundFontNotePlayer Refactoring]
- [Source: docs/project-context.md#AVAudioEngine — SoundFontNotePlayer ownership]
- [Source: docs/project-context.md#Testing Rules — Swift Testing, struct-based suites]
- [Source: docs/project-context.md#File Placement — Core/Audio/]
- [Source: Peach/Core/Audio/SoundFontNotePlayer.swift — current implementation to extract from]
- [Source: Peach/Core/Audio/SoundFontPlaybackHandle.swift — needs engine access after extraction]
- [Source: docs/implementation-artifacts/45-4-rhythmprofile-protocol.md — previous story]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
