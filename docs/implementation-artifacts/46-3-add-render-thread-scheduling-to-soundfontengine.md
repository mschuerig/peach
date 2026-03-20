# Story 46.3: Add Render-Thread Scheduling to SoundFontEngine

Status: review

## Story

As a **developer**,
I want `SoundFontEngine` to support sample-accurate scheduled MIDI dispatch via an `AVAudioSourceNode` render callback,
So that rhythm patterns can be played with sub-millisecond timing precision (NFR-R1).

## Acceptance Criteria

1. **Given** `SoundFontEngine` with render-thread scheduling, **when** an `AVAudioSourceNode` is attached to the audio engine, **then** it serves as the master clock on the audio render thread, **and** the source node outputs silence (it exists purely for its render callback).

2. **Given** a schedule of MIDI events with absolute sample offsets, **when** a render cycle occurs, **then** the engine checks for events falling within the current buffer window, **and** dispatches them via `scheduleMIDIEventBlock` with the exact sample offset.

3. **Given** the audio session, **when** rhythm scheduling is active, **then** minimum buffer duration is configured to 5ms (0.005s) per FR96.

4. **Given** the scheduling mechanism, **when** tested with known event times, **then** scheduled vs. actual sample positions differ by no more than 0.01ms (NFR-R1).

## Tasks / Subtasks

- [x] Task 1: Add `AVAudioSourceNode` to the audio graph (AC: #1)
  - [x] Add a `private let sourceNode: AVAudioSourceNode` to `SoundFontEngine`
  - [x] Initialize `sourceNode` with a render callback that reads from an internal event schedule and outputs silence
  - [x] Attach and connect `sourceNode` to `engine.mainMixerNode` in `init`
  - [x] The source node's format must match the engine's output sample rate (use `engine.outputNode.outputFormat(forBus: 0).sampleRate`)
  - [x] Verify engine still starts and all existing immediate dispatch continues to work

- [x] Task 2: Implement the render-thread event schedule (AC: #2)
  - [x] Define a `ScheduledMIDIEvent` struct (sample offset `Int64`, MIDI note `UInt8`, velocity `UInt8`, channel `UInt8`, event type note-on/note-off) — must be `Sendable` and trivially copyable for render-thread safety
  - [x] Add an internal schedule buffer (e.g., lock-free ring buffer or `os_unfair_lock`-protected array) that the render callback reads
  - [x] Add `scheduleEvents(_ events: [ScheduledMIDIEvent])` method to load a batch of pre-computed events — sets the schedule and resets the sample counter
  - [x] Add `clearSchedule()` method to cancel all pending events
  - [x] The render callback tracks cumulative sample position via `frameCount` accumulation
  - [x] Each render cycle: check for events with `sampleOffset` falling within `[currentSample, currentSample + frameCount)`, dispatch each via `scheduleMIDIEventBlock` on the `AVAudioUnitSampler`'s `auAudioUnit` with the exact intra-buffer offset
  - [x] No allocations or locks in the render callback hot path — all data must be pre-allocated (NFR-R2/FR94)

- [x] Task 3: Configure minimum audio buffer duration (AC: #3)
  - [x] Add `configureForRhythmScheduling()` method that calls `AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)`
  - [x] Call this when scheduling is activated, not unconditionally at init (pitch training doesn't need 5ms buffers)
  - [x] Add `restoreDefaultBufferDuration()` that resets to the system default when scheduling is deactivated

- [x] Task 4: Write tests for scheduling accuracy (AC: #4)
  - [x] Test: events scheduled at known sample offsets are dispatched within the correct render buffer window
  - [x] Test: multiple events within a single buffer are all dispatched
  - [x] Test: events spanning multiple buffers are dispatched in correct order
  - [x] Test: `clearSchedule()` prevents remaining events from firing
  - [x] Test: `scheduleEvents` replaces any existing schedule
  - [x] Test: existing immediate dispatch (`startNote`, `stopNote`, `sendPitchBend`) still works after source node is added
  - [x] Test: engine initialization with source node succeeds

- [x] Task 5: Verify no regressions (AC: #1, #2, #3, #4)
  - [x] `bin/build.sh` — zero errors, zero warnings
  - [x] `bin/test.sh` — full suite passes, zero regressions
  - [x] All existing `SoundFontEngineTests`, `SoundFontNotePlayerTests`, and `SoundFontPresetStressTests` pass unchanged

## Dev Notes

### This story adds scheduled dispatch alongside existing immediate dispatch

`SoundFontEngine` currently has only immediate MIDI dispatch (`startNote`, `stopNote`, `sendPitchBend`) called from the main thread. This story adds a parallel scheduling path via `AVAudioSourceNode` render callback. Both paths coexist — pitch training continues to use immediate dispatch unchanged.

### AVAudioSourceNode render callback architecture

The `AVAudioSourceNode` is initialized with a render block that:
1. Receives `(isSilence, timestamp, frameCount, outputData)` parameters
2. Sets `isSilence.pointee = true` — the node produces no audible output
3. Fills `outputData` buffers with zeros (required even when silent)
4. Reads the current schedule and dispatches any events in the current buffer window

The render block runs on the audio render thread (real-time priority). It must:
- **Never allocate memory** (no `Array.append`, no `String` creation)
- **Never acquire contended locks** (use `os_unfair_lock` or atomic operations only)
- **Never call Objective-C methods** that might allocate (no `NSLog`, no `print`)

### scheduleMIDIEventBlock access

`AVAudioUnitSampler` inherits from `AVAudioUnitMIDIInstrument` which inherits from `AVAudioUnit`. The `scheduleMIDIEventBlock` is accessed via `sampler.auAudioUnit.scheduleMIDIEventBlock`. This block has the signature:

```swift
typealias AUScheduleMIDIEventBlock = (AUEventSampleTime, UInt8, Int, UnsafePointer<UInt8>) -> Void
// (eventSampleTime, cable, length, midiBytes)
```

For a note-on: `midiBytes = [0x90 | channel, note, velocity]` (3 bytes)
For a note-off: `midiBytes = [0x80 | channel, note, 0]` (3 bytes)

The `eventSampleTime` is `AUEventSampleTimeImmediate` for immediate dispatch, or an absolute sample time for scheduled dispatch. Within a render callback, use `timestamp.mSampleTime + intraBufferOffset` for the absolute time.

### Thread-safety for the event schedule

The schedule is written from the main thread (`scheduleEvents`, `clearSchedule`) and read from the render thread. Use one of:
- `os_unfair_lock` around the schedule array (fast, acceptable for render thread if lock is never contended)
- Atomic swap of a pre-allocated buffer pointer (lock-free, optimal)

The preferred approach: double-buffering with atomic pointer swap. Prepare the new schedule on the main thread, atomically swap the pointer. The render thread reads from the current pointer without locking.

### Audio graph topology after this story

```
AVAudioSourceNode (silence, render clock)
    ↓ (connect to mainMixerNode)
AVAudioUnitSampler (melodic)
    ↓ (connect to mainMixerNode)
AVAudioEngine.mainMixerNode
    ↓
System audio output
```

Both `sourceNode` and `sampler` connect to the main mixer. The source node's render callback dispatches MIDI events to the sampler's `auAudioUnit` via `scheduleMIDIEventBlock`.

### Sample rate and timing

At 48kHz (typical iOS sample rate):
- 1 sample = 0.0208ms
- NFR-R1 requires jitter < 0.01ms = ~0.48 samples
- Since events are dispatched at exact sample positions, jitter is effectively 0 (limited only by buffer callback granularity)
- 5ms buffer at 48kHz = 240 samples per callback

### What NOT to do

- **Do NOT add percussion sampler** — that is story 46.4
- **Do NOT add `RhythmPattern` type** — that is story 46.4
- **Do NOT create `RhythmPlayer` protocol** — that is story 46.4
- **Do NOT modify `NotePlayer` or `PlaybackHandle` protocols** — unchanged
- **Do NOT modify `SoundFontNotePlayer`** — it continues to use immediate dispatch
- **Do NOT use `DispatchQueue` or `Thread`** — use `AVAudioSourceNode` render callback
- **Do NOT use Combine** — forbidden
- **Do NOT add explicit `@MainActor`** — redundant with default isolation
- **Do NOT use XCTest** — Swift Testing only
- **Do NOT allocate in the render callback** — real-time thread, no heap operations

### ScheduledMIDIEvent design

Keep this minimal — just what the render callback needs:

```swift
struct ScheduledMIDIEvent: Sendable {
    let sampleOffset: Int64    // absolute offset from schedule start
    let midiStatus: UInt8      // 0x90 = note-on, 0x80 = note-off
    let midiNote: UInt8        // MIDI note number 0-127
    let velocity: UInt8        // 0-127
}
```

This is intentionally raw `UInt8` — domain types (`MIDINote`, `MIDIVelocity`) are not `nonisolated` and shouldn't be used on the render thread. The conversion from domain types happens in `scheduleEvents()` on the main thread.

### Testing render-thread scheduling

Testing exact sample-level timing on a real `AVAudioEngine` is difficult because:
- Render callbacks run asynchronously on the audio thread
- Buffer sizes vary between hardware and simulator
- `scheduleMIDIEventBlock` has no observable output in unit tests

Practical testing approach:
1. Test the schedule logic in isolation — extract the "which events fire in this buffer window" logic to a pure `nonisolated` function that can be tested deterministically
2. Integration test: schedule events, play them, verify no crashes
3. The actual timing precision is validated by the on-device POC (story 46.5)

### Previous story (46.2) learnings

- `SoundFontEngine.sampler` is a `let` property — its `auAudioUnit` is accessible for `scheduleMIDIEventBlock`
- Engine init creates `AVAudioEngine`, attaches sampler, connects to mixer, starts engine, loads preset — the source node must be attached/connected in the same init sequence
- `SoundFontEngine` uses `nonisolated static` for constants — the `ScheduledMIDIEvent` struct and schedule-scanning logic should also be `nonisolated`
- All engine tests use `TestSoundFont.makeLibrary()` and `SoundSourceTag` — new tests follow the same factory pattern
- MIDI channel is `private nonisolated static let channel: UInt8 = 0` — the scheduled events use this same channel

### Project Structure Notes

Modified files:
- `Peach/Core/Audio/SoundFontEngine.swift` — add `AVAudioSourceNode`, render callback, schedule management, buffer configuration

New files: none expected (all changes within `SoundFontEngine.swift`)

Test files:
- `PeachTests/Core/Audio/SoundFontEngineTests.swift` — add scheduling tests

### References

- [Source: docs/planning-artifacts/epics.md#Epic 46, Story 46.3]
- [Source: docs/planning-artifacts/architecture.md#Layer 1: SoundFontEngine — render-thread scheduling]
- [Source: docs/planning-artifacts/rhythm-training-spec.md#Audio Timing & Playback Model]
- [Source: docs/planning-artifacts/epics.md#NFR-R1, NFR-R2, NFR-R3]
- [Source: Peach/Core/Audio/SoundFontEngine.swift — current implementation to extend]
- [Source: PeachTests/Core/Audio/SoundFontEngineTests.swift — test file to extend]
- [Source: docs/implementation-artifacts/46-2-refactor-soundfontnoteplayer-to-delegate-to-soundfontengine.md — previous story]
- [Source: docs/project-context.md#AVAudioEngine]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None

### Completion Notes List

- Used `OSAllocatedUnfairLock<ScheduleData>` with `withLockIfAvailable` (try-lock) on the render thread for real-time safety — never blocks the audio pipeline
- `ScheduleData` is `nonisolated` and `@unchecked Sendable` to work correctly with default MainActor isolation and `@Sendable` closures
- Pre-allocated `UnsafeMutablePointer<ScheduledMIDIEvent>` buffer (capacity 4096) — zero heap allocations on the render thread
- `@preconcurrency import AVFoundation` to handle non-Sendable AVFAudio types in `@Sendable` contexts
- Extracted `scanSchedule()` as a `nonisolated static` pure function for deterministic unit testing of the schedule-scanning logic
- `AUEventSampleTime` read from `timestamp` before entering the lock closure to avoid capturing non-Sendable `UnsafePointer<AudioTimeStamp>`

### File List

- `Peach/Core/Audio/SoundFontEngine.swift` — Added `ScheduledMIDIEvent`, `ScheduleData`, `AVAudioSourceNode` render callback, `scheduleEvents()`, `clearSchedule()`, `scheduledEventCount`, `configureForRhythmScheduling()`, `restoreDefaultBufferDuration()`, `scanSchedule()`
- `PeachTests/Core/Audio/SoundFontEngineTests.swift` — Added 9 tests for schedule scanning, schedule management, immediate dispatch after source node, and integration
