# Story 20.3: Move NoteDuration to Core/Audio/

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want `NoteDuration` moved from `Settings/` to `Core/Audio/`,
So that all audio domain value types are co-located in `Core/Audio/`, the `UserSettings` protocol references only `Core/` types, and no Core/ consumer depends on Settings/.

## Acceptance Criteria

1. **`NoteDuration.swift` lives in `Core/Audio/`** -- `Peach/Settings/NoteDuration.swift` is moved to `Peach/Core/Audio/NoteDuration.swift`. The original file no longer exists in `Peach/Settings/`.

2. **`NoteDurationTests.swift` lives in test mirror** -- `PeachTests/Settings/NoteDurationTests.swift` is moved to `PeachTests/Core/Audio/NoteDurationTests.swift`.

3. **`UserSettings` protocol references only Core/ types** -- After the move, every type in the `UserSettings` protocol signature (`SoundSourceID`, `NoteDuration`, `MIDINote`, `Frequency`, `UnitInterval`) is defined in `Core/`. The dependency direction is correct: Settings/ depends on Core/, not the reverse.

4. **Zero code changes required** -- Single-module app; types resolved by name, not directory path.

5. **All existing tests pass** -- Full test suite passes with zero regressions and zero code changes.

## Tasks / Subtasks

- [x] Task 1: Move production file (AC: #1)
  - [x] `git mv Peach/Settings/NoteDuration.swift Peach/Core/Audio/NoteDuration.swift`

- [x] Task 2: Move test file (AC: #2)
  - [x] `git mv PeachTests/Settings/NoteDurationTests.swift PeachTests/Core/Audio/NoteDurationTests.swift`

- [x] Task 3: Verify dependency direction (AC: #3)
  - [x] Confirm all types in `UserSettings` protocol are now defined in `Core/`
  - [x] Confirm no Core/ file references any type defined in Settings/

- [x] Task 4: Run full test suite (AC: #4, #5)
  - [x] `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [x] All tests pass, zero regressions, zero code changes

## Dev Notes

### Critical Design Decisions

- **`NoteDuration` is a domain value type** -- It represents note duration in seconds (0.3–3.0 range) with clamping validation. It is structurally identical to other audio domain types already in `Core/Audio/` (`MIDINote`, `Frequency`, `Cents`, `AmplitudeDB`, `MIDIVelocity`, `SoundSourceID`). It has no Settings-specific logic.
- **This completes the story 20.1 oversight** -- Story 20.1 moved shared domain types to `Core/Training/` but missed `NoteDuration` in `Settings/`. Story 20.2 moved `SoundSourceID` from `Settings/` to `Core/Audio/`. This story completes the pattern by moving the last remaining domain type out of `Settings/`.
- **After this move, `UserSettings` protocol depends only on Core/ types** -- `SoundSourceID` (Core/Audio/), `NoteDuration` (Core/Audio/), `MIDINote` (Core/Audio/), `Frequency` (Core/Audio/), `UnitInterval` (Core/). The dependency direction is fully correct: Settings/ → Core/.

### Architecture & Integration

**Moved files (content unchanged):**
- `Peach/Settings/NoteDuration.swift` → `Peach/Core/Audio/NoteDuration.swift`
- `PeachTests/Settings/NoteDurationTests.swift` → `PeachTests/Core/Audio/NoteDurationTests.swift`

**No modified files.** All consumers reference `NoteDuration` by name only.

### Existing Code to Reference

- **`NoteDuration.swift`** -- Pure value type, ~33 lines. `struct NoteDuration: Hashable, Comparable, Sendable` with `rawValue: Double`, clamping init, `ExpressibleByFloatLiteral`, `ExpressibleByIntegerLiteral`. Uses `clamped(to:)` utility. [Source: Peach/Core/Audio/NoteDuration.swift]
- **`UserSettings.swift`** -- Protocol exposing `var noteDuration: NoteDuration`. After this move, all types in the protocol signature live in Core/. [Source: Peach/Settings/UserSettings.swift]
- **`ComparisonSession.swift`** -- Reads `currentNoteDuration` computed property (delegates to `userSettings.noteDuration`). [Source: Peach/Comparison/ComparisonSession.swift]
- **`PitchMatchingSession.swift`** -- Reads `currentNoteDuration` computed property (delegates to `userSettings.noteDuration`). [Source: Peach/PitchMatching/PitchMatchingSession.swift]
- **`AppUserSettings.swift`** -- Implementation of `UserSettings`, reads `noteDuration` from `UserDefaults`. [Source: Peach/Settings/AppUserSettings.swift]
- **`SoundSourceID.swift`** -- Analogous type already moved to `Core/Audio/` in story 20.2. Follow the exact same move pattern. [Source: Peach/Core/Audio/SoundSourceID.swift]

### Previous Story Intelligence

Story 20.2 (Move SoundSourceID to Core/Audio/) is the direct precedent:
- Pure `git mv` for production file and test file — zero code changes
- Xcode objectVersion 77 file-system-synchronized groups handle the move automatically
- Single-module app resolves types by name, not directory path
- 588 tests passed with zero regressions
- Code review found only informational items (L-level)

### Testing Approach

- **No new tests** -- Pure file move with no behavioral change.
- **Run full suite** to confirm the compiler resolves `NoteDuration` at its new path.
- Existing `NoteDurationTests.swift` (7 tests: construction, clamping, literals, comparable, hashable) moves alongside the production file.

### Risk Assessment

- **Extremely low risk** -- Identical pattern to stories 20.1 and 20.2, both completed successfully with zero issues. Single-module app means file location does not affect compilation.

### Project Structure Notes

- `Core/Audio/` already contains: `MIDINote.swift`, `Frequency.swift`, `Cents.swift`, `AmplitudeDB.swift`, `MIDIVelocity.swift`, `SoundSourceID.swift`, `SoundFontNotePlayer.swift`, `SF2PresetParser.swift`, `NotePlayer.swift`, `PlaybackHandle.swift`, `FrequencyCalculation.swift`
- Adding `NoteDuration.swift` co-locates it with the other audio domain value types
- `PeachTests/Core/Audio/` already contains `SoundSourceIDTests.swift` (moved in 20.2)

### References

- [Source: docs/planning-artifacts/epics.md -- Epic 20: Right Direction — Dependency Inversion Cleanup]
- [Source: docs/implementation-artifacts/20-2-move-soundsourceid-to-core.md -- Analogous SoundSourceID move]
- [Source: docs/project-context.md -- File Placement decision tree: "Protocol or service used across features → Core/{subdomain}/"]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

No issues encountered.

### Completion Notes List

- Moved `NoteDuration.swift` from `Peach/Settings/` to `Peach/Core/Audio/` via `git mv` — zero code changes
- Moved `NoteDurationTests.swift` from `PeachTests/Settings/` to `PeachTests/Core/Audio/` via `git mv`
- Verified all 5 types in `UserSettings` protocol signature (`MIDINote`, `NoteDuration`, `Frequency`, `SoundSourceID`, `UnitInterval`) now live in `Core/`
- Confirmed no `Core/` file has code dependencies on `Settings/` types (one comment reference only)
- Full test suite passed — zero regressions, zero code changes

### File List

- `Peach/Settings/NoteDuration.swift` → `Peach/Core/Audio/NoteDuration.swift` (moved)
- `PeachTests/Settings/NoteDurationTests.swift` → `PeachTests/Core/Audio/NoteDurationTests.swift` (moved)
- `docs/implementation-artifacts/20-3-move-noteduration-to-core-audio.md` (updated)
- `docs/implementation-artifacts/sprint-status.yaml` (updated)

## Senior Developer Review (AI)

**Reviewer:** Michael (via Claude Opus 4.6) on 2026-02-27
**Outcome:** Approved — 0 High, 0 Medium, 3 Low (2 fixed, 1 informational)

### Findings

- **L-1 (Fixed):** `NoteDuration.validRange` had internal access but was never referenced outside the file. Made `private` per project rules.
- **L-2 (Fixed):** Stale source path `[Source: Peach/Settings/NoteDuration.swift]` in "Existing Code to Reference" section updated to post-move path.
- **L-3 (Informational):** `NoteDuration` lacks `Codable` unlike sibling `MIDINote`. Intentional — persists via `@AppStorage` as raw `Double`, not via Codable. No action needed.

### Verification

- All 5 Acceptance Criteria validated against actual implementation
- All 4 tasks verified as genuinely complete
- Git diff confirms pure rename (100% similarity) with zero code changes
- File List matches git reality — 0 discrepancies
- Full test suite passes after `private` fix

## Change Log

- 2026-02-27: Implemented story 20.3 — moved NoteDuration.swift and NoteDurationTests.swift from Settings/ to Core/Audio/, completing the domain type co-location pattern started in stories 20.1 and 20.2
- 2026-02-27: Code review passed — 0 High, 0 Medium, 3 Low (2 fixed, 1 informational). Marked done.
