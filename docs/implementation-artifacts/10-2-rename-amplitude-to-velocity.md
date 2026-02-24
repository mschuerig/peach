# Story 10.2: Rename Amplitude to Velocity

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want the existing "amplitude" parameter renamed to "velocity" with proper MIDI velocity typing (UInt8, 0-127) throughout the codebase,
So that the audio API correctly reflects what it actually controls and makes room for a true amplitude (loudness) parameter.

## Acceptance Criteria

1. **Given** the `NotePlayer` protocol declares `play(frequency:duration:amplitude:)` with amplitude as `Double` (0.0-1.0), **When** the refactoring is applied, **Then** the protocol signature becomes `play(frequency:duration:velocity:)` with velocity as `UInt8` (0-127).

2. **Given** `SoundFontNotePlayer` contains a `midiVelocity(forAmplitude:)` conversion helper, **When** the refactoring is applied, **Then** the helper is removed and velocity is passed directly to `sampler.startNote(_:withVelocity:onChannel:)`.

3. **Given** `SoundFontNotePlayer` validates amplitude in the range 0.0-1.0 and throws `AudioError.invalidAmplitude`, **When** the refactoring is applied, **Then** validation checks velocity in the range 0-127 and the error case is renamed to `AudioError.invalidVelocity`.

4. **Given** `TrainingSession` holds a private constant `amplitude: Double = 0.5`, **When** the refactoring is applied, **Then** it holds a velocity constant of type `UInt8` with the equivalent MIDI value (63).

5. **Given** `MockNotePlayer` tracks `lastAmplitude` and `playHistory` with amplitude fields, **When** the refactoring is applied, **Then** these are renamed to `lastVelocity` and the history tuple uses `velocity: UInt8`.

6. **Given** all existing tests pass before the refactoring, **When** the refactoring is complete, **Then** all existing tests pass with updated parameter names and types, and no audible behavior changes (NFR1).

## Tasks / Subtasks

- [ ] Task 1: Update `NotePlayer` protocol and `AudioError` enum (AC: #1, #3)
  - [ ] Rename `AudioError.invalidAmplitude` to `AudioError.invalidVelocity` in `Peach/Core/Audio/NotePlayer.swift`
  - [ ] Change protocol signature from `play(frequency: Double, duration: TimeInterval, amplitude: Double)` to `play(frequency: Double, duration: TimeInterval, velocity: UInt8)`
  - [ ] Update doc comments to reflect MIDI velocity semantics (0-127)

- [ ] Task 2: Update `SoundFontNotePlayer` implementation (AC: #1, #2, #3)
  - [ ] Change `play` signature to accept `velocity: UInt8`
  - [ ] Remove the `static func midiVelocity(forAmplitude:) -> UInt8` helper entirely
  - [ ] Replace amplitude validation `(0.0...1.0).contains(amplitude)` with velocity validation `(0...127).contains(velocity)` (note: velocity is UInt8 so lower bound 0 is always satisfied; validate upper bound and consider whether 0 should be rejected — MIDI velocity 0 = note-off)
  - [ ] Replace `AudioError.invalidAmplitude` throw with `AudioError.invalidVelocity`
  - [ ] Pass `velocity` directly to `sampler.startNote(midiNote, withVelocity: velocity, onChannel:)` (remove the `let velocity = Self.midiVelocity(forAmplitude: amplitude)` line)

- [ ] Task 3: Update `TrainingSession` (AC: #4)
  - [ ] Rename `private let amplitude: Double = 0.5` to `private let velocity: UInt8 = 63` (line 139)
  - [ ] Update both `notePlayer.play(...)` calls (lines 401 and 412) to pass `velocity: velocity` instead of `amplitude: amplitude`
  - [ ] Update the comment on line 138 from "Amplitude for note playback (0.0-1.0)" to "MIDI velocity for note playback (0-127)"

- [ ] Task 4: Update preview mock in `TrainingScreen.swift` (AC: #1)
  - [ ] Change `MockNotePlayerForPreview.play(frequency:duration:amplitude:)` signature to `play(frequency:duration:velocity:)` with `velocity: UInt8` (line 181)

- [ ] Task 5: Update `MockNotePlayer` (AC: #5)
  - [ ] Rename `lastAmplitude: Double?` to `lastVelocity: UInt8?` (line 12)
  - [ ] Change `playHistory` tuple from `(frequency: Double, duration: TimeInterval, amplitude: Double)` to `(frequency: Double, duration: TimeInterval, velocity: UInt8)` (line 13)
  - [ ] Update `play` method signature and body: `amplitude` param → `velocity: UInt8`, capture to `lastVelocity`, append to `playHistory` with `velocity:` (lines 34-39)
  - [ ] Update `reset()`: `lastAmplitude = nil` → `lastVelocity = nil` (line 67)

- [ ] Task 6: Update `SoundFontNotePlayerTests` (AC: #2, #3, #6)
  - [ ] Remove the 3 `midiVelocity(forAmplitude:)` tests entirely (the helper no longer exists):
    - `amplitude_half` (line 98-101)
    - `amplitude_full` (line 104-107)
    - `amplitude_zero_floorsAt1` (line 110-113)
  - [ ] Replace all `amplitude: 0.5` arguments in `play()` calls with `velocity: 63` (lines 37, 149, 219, 227, 235, 243)
  - [ ] Add new tests for velocity validation:
    - Velocity 0 behavior (note-off in MIDI — decide: reject with error or allow)
    - Velocity 127 is accepted
    - Velocity within range plays successfully

- [ ] Task 7: Update `TrainingSessionIntegrationTests` (AC: #6)
  - [ ] Rename test `passesCorrectAmplitude` to `passesCorrectVelocity` (line 43)
  - [ ] Change assertion from `f.mockPlayer.lastAmplitude == 0.5` to `f.mockPlayer.lastVelocity == 63` (line 50)
  - [ ] Update test description string to mention velocity

- [ ] Task 8: Update `FrequencyCalculationTests` (AC: #3, #6)
  - [ ] Change `AudioError.invalidAmplitude("test")` to `AudioError.invalidVelocity("test")` in `audioError_CasesExist` test (line 75)

- [ ] Task 9: Run full test suite and verify (AC: #6)
  - [ ] Run: `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] All tests must pass with zero failures
  - [ ] Verify no remaining references to "amplitude" in Swift files (grep check)

## Dev Notes

### This Is a Pure Rename/Retype Refactoring

**NFR1 compliance:** No audible behavior may change. The current `amplitude: 0.5` maps to `midiVelocity = 63` via `Int(0.5 * 127.0) = 63`. The new code passes `velocity: UInt8 = 63` directly. Same MIDI velocity reaches the sampler.

### Complete File Change Map (8 files)

| File | Type | Changes |
|---|---|---|
| `Peach/Core/Audio/NotePlayer.swift` | Protocol + enum | Rename error case, change parameter type |
| `Peach/Core/Audio/SoundFontNotePlayer.swift` | Implementation | Remove helper, change validation, pass velocity directly |
| `Peach/Training/TrainingSession.swift` | Orchestrator | Rename constant, update 2 play() calls |
| `Peach/Training/TrainingScreen.swift` | Preview mock | Update mock signature |
| `PeachTests/Training/MockNotePlayer.swift` | Test mock | Rename tracking properties, update signature |
| `PeachTests/Core/Audio/SoundFontNotePlayerTests.swift` | Tests | Remove 3 tests, update 6 play() calls, add velocity tests |
| `PeachTests/Training/TrainingSessionIntegrationTests.swift` | Tests | Rename 1 test, update 1 assertion |
| `PeachTests/Core/Audio/FrequencyCalculationTests.swift` | Tests | Update 1 error case reference |

### Velocity Validation Design Decision

The current code rejects `amplitude < 0.0` and `amplitude > 1.0`. For velocity (`UInt8`, range 0-127):
- **UInt8 naturally prevents negative values** — no lower-bound check needed
- **Upper bound 127** — UInt8 allows 0-255, but MIDI velocity is 0-127. Validate `velocity <= 127`
- **Velocity 0** — In MIDI, velocity 0 typically means "note off". The current code floors at velocity 1 (`max(1, ...)`). To maintain identical behavior, **reject velocity 0** with `AudioError.invalidVelocity` and document that valid range is 1-127. This preserves the current safety floor.

### Key Gotcha: `midiVelocity(forAmplitude:)` Is `static` and Called in Tests

The helper `SoundFontNotePlayer.midiVelocity(forAmplitude:)` is used in 3 tests (`SoundFontNotePlayerTests`). When the helper is deleted, these 3 tests must be **removed entirely** — not refactored. They test a conversion that no longer exists. New velocity validation tests replace them.

### Previous Story (10.1) Intelligence

Story 10.1 was research-only (no code changes). Key findings relevant to this story:
- `AVAudioUnitSampler.masterGain` (dB, -90.0 to +12.0) was chosen for true volume control in Story 10.3
- MIDI velocity and `masterGain` are **independent and multiplicative** — velocity controls timbre/dynamics, `masterGain` controls output gain
- This confirms the rename is semantically correct: the current "amplitude" parameter really does control MIDI velocity (timbre selection), not volume

### Naming After This Story

After this refactoring:
- `velocity: UInt8` = MIDI velocity (controls which SF2 sample layer fires + initial dynamic level)
- Future `amplitudeDB: Float` (Story 10.3) = output gain via `sampler.masterGain` (controls loudness)

### Project Structure Notes

- No new files created — all changes are renames within existing files
- No new dependencies or imports needed
- No changes to project structure, build settings, or localization
- `TrainingTestHelpers.swift` — no changes needed (doesn't reference amplitude directly)

### References

- [Source: docs/planning-artifacts/epics.md#Epic 10] — Story 10.2 acceptance criteria
- [Source: docs/implementation-artifacts/10-1-volume-control-findings.md] — masterGain research confirming velocity vs. amplitude semantics
- [Source: docs/implementation-artifacts/10-1-research-volume-control-in-avaudiounitsampler.md] — Previous story completion notes
- [Source: docs/project-context.md#AVAudioEngine] — SoundFontNotePlayer rules, NotePlayer protocol boundary
- [Source: docs/project-context.md#Testing Rules] — Swift Testing framework, mock contract, TDD workflow
- [Source: Peach/Core/Audio/NotePlayer.swift] — Current protocol with amplitude parameter
- [Source: Peach/Core/Audio/SoundFontNotePlayer.swift] — midiVelocity(forAmplitude:) helper to remove
- [Source: Peach/Training/TrainingSession.swift:139] — amplitude constant to rename
- [Source: PeachTests/Training/MockNotePlayer.swift] — Mock tracking properties to rename

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
