# Story 22.2: Domain Type Documentation and API Cleanup

Status: done

## Story

As a **developer maintaining the audio domain layer**,
I want class-level documentation on all 6 audio domain types and explicit parameters on all frequency conversion methods,
So that the API is self-documenting, tuning assumptions are visible at every call site, and there is exactly one path from MIDI note to Hz.

## Acceptance Criteria

1. **Documentation added** -- All 6 domain types (`MIDINote`, `Interval`, `Frequency`, `Pitch`, `TuningSystem`, `Cents`) have `///` doc comments explaining role, relationships, and design decisions.

2. **`MIDINote.frequency()` removed** -- The convenience method is deleted. All callers use `Pitch(note:cents:).frequency(referencePitch:)` explicitly.

3. **No implicit defaults on frequency methods** -- `Pitch.frequency(referencePitch:)`, `Pitch.init(frequency:referencePitch:)`, `Comparison.note1Frequency(referencePitch:)`, `Comparison.note2Frequency(referencePitch:)`, and `TrainingSettings.init(referencePitch:)` require explicit parameters.

4. **All tests pass** -- Full test suite passes with no behavioral changes.

5. **project-context.md updated** -- MIDI-to-Hz conversion guidance reflects the new API.

## Tasks / Subtasks

- [x] Task 1: Add class-level documentation to 6 domain types
- [x] Task 2: Remove `MIDINote.frequency()` method and update 4 test callers
- [x] Task 3: Remove parameter defaults from `Pitch.frequency()`, `Pitch.init(frequency:)`, `Comparison.note1Frequency()`, `Comparison.note2Frequency()`, `TrainingSettings.init(referencePitch:)`
- [x] Task 4: Update all test callers to pass explicit parameters (18 call sites across 7 test files)
- [x] Task 5: Update `project-context.md` line 81

## Dev Notes

### Files Modified

**Production (10):**
- `Peach/Core/Audio/MIDINote.swift` — docs + removed `frequency()` method
- `Peach/Core/Audio/Interval.swift` — docs
- `Peach/Core/Audio/Frequency.swift` — docs
- `Peach/Core/Audio/Pitch.swift` — docs + removed 2 defaults
- `Peach/Core/Audio/TuningSystem.swift` — docs
- `Peach/Core/Audio/Cents.swift` — docs
- `Peach/Core/Training/Comparison.swift` — removed 2 defaults, `referencePitch` param changed from `Double` to `Frequency`
- `Peach/Core/Algorithm/NextComparisonStrategy.swift` — removed `TrainingSettings.init(referencePitch:)` default, `referencePitch` changed from `Double` to `Frequency`
- `Peach/Comparison/ComparisonSession.swift` — removed `.rawValue` unwrap on `userSettings.referencePitch`
- `Peach/PitchMatching/PitchMatchingSession.swift` — removed `.rawValue` unwrap and `Frequency(...)` wrapping

**Tests (8):**
- `PeachTests/Core/Audio/MIDINoteTests.swift` — 4 calls updated to use Pitch explicitly
- `PeachTests/Core/Audio/PitchTests.swift` — 2 calls updated with explicit `.concert440`
- `PeachTests/Core/Training/ComparisonTests.swift` — 5 calls updated with `.concert440`
- `PeachTests/Core/Algorithm/KazezNoteStrategyTests.swift` — all `TrainingSettings(...)` calls use `.concert440`
- `PeachTests/Settings/SettingsTests.swift` — uses `.concert440`, compares via `.rawValue`
- `PeachTests/Comparison/ComparisonSessionResetTests.swift` — 2 calls use `.concert440`
- `PeachTests/Comparison/ComparisonSessionIntegrationTests.swift` — 1 call uses `.concert440`
- `PeachTests/PitchMatching/PitchMatchingSessionTests.swift` — 9 calls use `.concert440`

**Docs (2):**
- `docs/project-context.md` — updated MIDI-to-Hz conversion guidance
- `docs/implementation-artifacts/22-2-domain-type-documentation-and-api-cleanup.md` — this file

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Change Log

- 2026-02-28: Implemented story 22.2
