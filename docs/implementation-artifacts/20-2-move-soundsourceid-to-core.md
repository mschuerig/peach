# Story 20.2: Move SoundSourceID to Core/Audio/

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want `SoundSourceID` moved from `Settings/` to `Core/Audio/`,
So that `SoundFontNotePlayer` no longer depends on the Settings module, and audio domain types are co-located.

## Acceptance Criteria

1. **`SoundSourceID.swift` lives in `Core/Audio/`** -- The file `Peach/Settings/SoundSourceID.swift` is moved to `Peach/Core/Audio/SoundSourceID.swift`. The original file no longer exists.

2. **`SoundSourceIDTests.swift` lives in test mirror** -- `PeachTests/Settings/SoundSourceIDTests.swift` is moved to `PeachTests/Core/Audio/SoundSourceIDTests.swift`.

3. **No Core/ file references any type defined in Settings/** -- After the move, `SoundFontNotePlayer` resolves `SoundSourceID` from within `Core/Audio/`. The `UserSettings` protocol (in `Settings/`) references `SoundSourceID` from `Core/Audio/` -- this is the correct dependency direction (Settings depends on Core, not the reverse).

4. **Zero code changes required** -- Single-module app; types resolved by name.

5. **All existing tests pass** -- Full test suite passes with zero regressions.

## Tasks / Subtasks

- [x] Task 1: Move production file (AC: #1)
  - [x] `git mv Peach/Settings/SoundSourceID.swift Peach/Core/Audio/SoundSourceID.swift`

- [x] Task 2: Move test file (AC: #2)
  - [x] `git mv PeachTests/Settings/SoundSourceIDTests.swift PeachTests/Core/Audio/SoundSourceIDTests.swift`

- [x] Task 3: Verify dependency direction (AC: #3)
  - [x] Confirm no Core/ file references any type in Settings/ except the `UserSettings` protocol (which is a protocol boundary, not a concrete dependency)

- [x] Task 4: Run full test suite (AC: #4, #5)
  - [x] `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [x] All tests pass, zero regressions

## Dev Notes

### Critical Design Decisions

- **`SoundSourceID` is a domain value type** -- It encodes a sound source tag (`"sf2:{bank}:{program}"`). It is consumed by `SoundFontNotePlayer` (Core/Audio/) and exposed through the `UserSettings` protocol (Settings/). Since the consumer is in Core/ and it has no Settings-specific logic, it belongs in Core/Audio/.
- **`UserSettings` protocol stays in Settings/** -- The protocol defines what settings are available. It references `SoundSourceID`, `NoteDuration`, `MIDINote`, `Frequency`, and `UnitInterval`. After this move, `UserSettings` depends on Core/ types only -- the correct direction.

### Architecture & Integration

**Moved files (content unchanged):**
- `Peach/Settings/SoundSourceID.swift` -> `Peach/Core/Audio/SoundSourceID.swift`
- `PeachTests/Settings/SoundSourceIDTests.swift` -> `PeachTests/Core/Audio/SoundSourceIDTests.swift`

**No modified files.**

### Existing Code to Reference

- **`SoundSourceID.swift`** -- Pure value type, ~30 lines, parses `"sf2:{bank}:{program}"` tag. [Source: Peach/Settings/SoundSourceID.swift]
- **`SoundFontNotePlayer.swift`** -- Uses `SoundSourceID` via `userSettings.soundSource`. [Source: Peach/Core/Audio/SoundFontNotePlayer.swift]
- **`UserSettings.swift`** -- Protocol exposing `var soundSource: SoundSourceID`. [Source: Peach/Settings/UserSettings.swift]

### Testing Approach

- **No new tests** -- Pure file move.
- **Run full suite** to confirm type resolution.

### Risk Assessment

- **Extremely low risk** -- Same rationale as Story 20.1.

### Git Intelligence

Commit message: `Implement story 20.2: Move SoundSourceID to Core/Audio/`

### References

- [Source: docs/planning-artifacts/epics.md -- Epic 20]
- [Source: Peach/Core/Audio/SoundFontNotePlayer.swift -- Consumer of SoundSourceID]

## Dev Agent Record

### Implementation Notes

- Pure file move via `git mv` — no code changes required
- `SoundSourceID.swift` moved from `Settings/` to `Core/Audio/` alongside its consumer `SoundFontNotePlayer`
- Test mirror maintained: `SoundSourceIDTests.swift` moved to `PeachTests/Core/Audio/`
- Verified dependency direction: no Core/ file references Settings/ types. `UserSettings` protocol in Settings/ references `SoundSourceID` from Core/ — correct direction
- 588 tests passed, 0 failures

## File List

- `Peach/Settings/SoundSourceID.swift` → `Peach/Core/Audio/SoundSourceID.swift` (moved)
- `PeachTests/Settings/SoundSourceIDTests.swift` → `PeachTests/Core/Audio/SoundSourceIDTests.swift` (moved)
- `docs/implementation-artifacts/sprint-status.yaml` (modified — status updated)
- `docs/implementation-artifacts/20-2-move-soundsourceid-to-core.md` (modified — task tracking)

## Change Log

- 2026-02-27: Story created from Epic 20 adversarial dependency review.
- 2026-02-27: Implementation complete — moved SoundSourceID and tests to Core/Audio/, all 588 tests pass.
