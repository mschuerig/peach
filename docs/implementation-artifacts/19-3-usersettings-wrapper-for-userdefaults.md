# Story 19.3: UserSettings Wrapper for UserDefaults

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want all `UserDefaults.standard` access encapsulated behind a `UserSettings` protocol with typed properties,
So that business logic is decoupled from the persistence singleton, type casting and default fallbacks are centralized, and tests can inject a mock instead of using override parameters.

## Acceptance Criteria

1. **`UserSettings` protocol defined** -- A protocol exposing typed read-only properties for all user-configurable settings: `noteRangeMin: MIDINote`, `noteRangeMax: MIDINote`, `noteDuration: TimeInterval`, `referencePitch: Double`, `soundSource: String`, `varyLoudness: Double`, `naturalVsMechanical: Double`. Lives in `Peach/Settings/`.

2. **`AppUserSettings` implementation** -- A concrete implementation that reads from `UserDefaults.standard` internally, providing defaults from `SettingsKeys`. Registered once in `PeachApp.swift`.

3. **Dependency injection replaces singleton access** -- `ComparisonSession`, `PitchMatchingSession`, and `SoundFontNotePlayer` accept a `UserSettings` parameter in their initializers instead of accessing `UserDefaults.standard` directly.

4. **Override parameters removed** -- `settingsOverride: TrainingSettings?`, `noteDurationOverride: TimeInterval?`, and `varyLoudnessOverride: Double?` are removed from session initializers. Tests inject a `MockUserSettings` instead.

5. **`MockUserSettings` for tests** -- A mock conforming to `UserSettings` with mutable properties, used by all tests that previously relied on overrides or `UserDefaults.standard` manipulation.

6. **`@AppStorage` in `SettingsScreen` unchanged** -- `SettingsScreen` continues to use `@AppStorage` which writes to the same `UserDefaults` backing store. `AppUserSettings` reads those values. No changes needed to `SettingsScreen`.

7. **No `REVIEW:` comment on `ComparisonSession.swift:68`** -- The code review comment about UserDefaults direct access is resolved and removed.

8. **All existing tests pass** -- Full test suite passes with zero regressions. Tests that previously set `UserDefaults.standard` directly for settings now use `MockUserSettings`.

## Tasks / Subtasks

- [ ] Task 1: Create `UserSettings` protocol (AC: #1)
  - [ ] Create `Peach/Settings/UserSettings.swift`
  - [ ] Define typed read-only properties for all settings
  - [ ] Properties use Value Object types from Story 19.2 where appropriate (`MIDINote` for note ranges)

- [ ] Task 2: Create `AppUserSettings` implementation (AC: #2)
  - [ ] Create `Peach/Settings/AppUserSettings.swift`
  - [ ] Read from `UserDefaults.standard` internally with type casting and default fallbacks
  - [ ] Centralize the `object(forKey:) as? T ?? default` pattern that's currently duplicated in 3 files
  - [ ] Make it `@Observable` so SwiftUI environment can observe changes (or keep as plain class — design decision)

- [ ] Task 3: Create `MockUserSettings` for tests (AC: #5)
  - [ ] Create `PeachTests/Mocks/MockUserSettings.swift` (or alongside existing mocks)
  - [ ] All properties are `var` for test manipulation
  - [ ] Provide sensible defaults matching `SettingsKeys` defaults

- [ ] Task 4: Inject `UserSettings` into `ComparisonSession` (AC: #3, #4, #7)
  - [ ] Add `userSettings: UserSettings` parameter to `ComparisonSession.init()`
  - [ ] Replace `currentSettings` computed property: read from `userSettings` instead of `UserDefaults.standard`
  - [ ] Replace `currentNoteDuration` computed property: read from `userSettings.noteDuration`
  - [ ] Replace `currentVaryLoudness` computed property: read from `userSettings.varyLoudness`
  - [ ] Remove `settingsOverride`, `noteDurationOverride`, `varyLoudnessOverride` parameters
  - [ ] Remove `REVIEW:` comment at line 68

- [ ] Task 5: Inject `UserSettings` into `PitchMatchingSession` (AC: #3, #4)
  - [ ] Add `userSettings: UserSettings` parameter to `PitchMatchingSession.init()`
  - [ ] Replace `currentSettings` computed property: read from `userSettings`
  - [ ] Replace `currentNoteDuration` computed property: read from `userSettings.noteDuration`
  - [ ] Remove `settingsOverride` and `noteDurationOverride` parameters

- [ ] Task 6: Inject `UserSettings` into `SoundFontNotePlayer` (AC: #3)
  - [ ] Add `userSettings: UserSettings` parameter to `SoundFontNotePlayer.init()`
  - [ ] Replace `UserDefaults.standard.string(forKey: SettingsKeys.soundSource)` with `userSettings.soundSource`
  - [ ] This was previously untestable for preset selection — now it is

- [ ] Task 7: Wire `AppUserSettings` in `PeachApp.swift` (AC: #2, #3)
  - [ ] Create `AppUserSettings()` instance in `PeachApp.init()`
  - [ ] Pass to `ComparisonSession`, `PitchMatchingSession`, and `SoundFontNotePlayer`

- [ ] Task 8: Update all test factories and mocks (AC: #4, #5, #8)
  - [ ] Update `makeComparisonSession()` factory: replace override parameters with `userSettings: MockUserSettings`
  - [ ] Update `makePitchMatchingSession()` factory: replace override parameters with `userSettings: MockUserSettings`
  - [ ] Update `ComparisonSessionUserDefaultsTests` — replace `UserDefaults.standard.set()` calls with `MockUserSettings` property manipulation
  - [ ] Update `ComparisonSessionLoudnessTests` — replace `varyLoudnessOverride` with `mockSettings.varyLoudness = X`
  - [ ] Update all other test files that used override parameters
  - [ ] Update preview mocks in `ComparisonScreen.swift` and `PitchMatchingScreen.swift`

- [ ] Task 9: Run full test suite and verify (AC: #8)
  - [ ] Run `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] All tests pass, zero regressions
  - [ ] No direct `UserDefaults.standard` access remains outside `AppUserSettings`

## Dev Notes

### Critical Design Decisions

- **Protocol, not concrete class** -- `UserSettings` is a protocol so tests can inject `MockUserSettings`. This eliminates the current workaround of override parameters while maintaining testability.
- **Live reads, not cached** -- `AppUserSettings` reads from `UserDefaults` on each property access, matching the current behavior where `currentSettings` is computed fresh each comparison. `@AppStorage` writes take effect immediately.
- **`SoundFontNotePlayer` gains testability** -- Currently the only component without any override mechanism for its `soundSource` setting. After this story, tests can control which preset is selected.
- **`UserDefaults.standard.set()` in tests disappears** -- `ComparisonSessionUserDefaultsTests` currently pollutes global state by calling `UserDefaults.standard.set()`. With `MockUserSettings`, tests use `mockSettings.noteRangeMin = MIDINote(50)` instead. This eliminates the need for `cleanUpSettingsDefaults()` teardown.
- **Keep `@AppStorage` in `SettingsScreen`** -- The SwiftUI view continues to write settings via `@AppStorage`. `AppUserSettings` reads from the same `UserDefaults.standard` store. No conflict because settings are only written by the Settings UI and only read by sessions/player.

### Architecture & Integration

**New files:**
- `Peach/Settings/UserSettings.swift` (protocol)
- `Peach/Settings/AppUserSettings.swift` (implementation)
- `PeachTests/Mocks/MockUserSettings.swift` (test mock)

**Modified production files:**
- `Peach/Comparison/ComparisonSession.swift` — new init parameter, remove overrides, remove REVIEW comment
- `Peach/PitchMatching/PitchMatchingSession.swift` — new init parameter, remove overrides
- `Peach/Core/Audio/SoundFontNotePlayer.swift` — new init parameter, replace UserDefaults access
- `Peach/App/PeachApp.swift` — create and inject `AppUserSettings`
- `Peach/Comparison/ComparisonScreen.swift` — update preview mock session construction
- `Peach/PitchMatching/PitchMatchingScreen.swift` — update preview mock session construction

**Modified test files:**
- `PeachTests/Comparison/ComparisonTestHelpers.swift` — factory now takes `MockUserSettings`
- `PeachTests/Comparison/ComparisonSessionUserDefaultsTests.swift` — replace UserDefaults manipulation
- `PeachTests/Comparison/ComparisonSessionLoudnessTests.swift` — replace varyLoudnessOverride
- `PeachTests/PitchMatching/PitchMatchingTestHelpers.swift` — factory now takes `MockUserSettings`
- All other test files that construct sessions

### Implementation Pattern

```swift
// Protocol:
protocol UserSettings {
    var noteRangeMin: MIDINote { get }
    var noteRangeMax: MIDINote { get }
    var noteDuration: TimeInterval { get }
    var referencePitch: Double { get }
    var soundSource: String { get }
    var varyLoudness: Double { get }
    var naturalVsMechanical: Double { get }
}

// Production implementation:
final class AppUserSettings: UserSettings {
    var noteRangeMin: MIDINote {
        MIDINote(UserDefaults.standard.object(forKey: SettingsKeys.noteRangeMin) as? Int ?? SettingsKeys.defaultNoteRangeMin)
    }
    // ... same for all properties
}

// Test mock:
final class MockUserSettings: UserSettings {
    var noteRangeMin: MIDINote = MIDINote(SettingsKeys.defaultNoteRangeMin)
    var noteRangeMax: MIDINote = MIDINote(SettingsKeys.defaultNoteRangeMax)
    var noteDuration: TimeInterval = SettingsKeys.defaultNoteDuration
    // ... all mutable with defaults
}

// Session construction:
let session = ComparisonSession(
    notePlayer: notePlayer,
    strategy: strategy,
    profile: profile,
    observers: observers,
    userSettings: appUserSettings  // replaces settingsOverride + noteDurationOverride + varyLoudnessOverride
)
```

### Existing Code to Reference (DO NOT MODIFY unless specified)

- **`ComparisonSession.swift:68-146`** -- Current UserDefaults access pattern with REVIEW comment. [Source: Peach/Comparison/ComparisonSession.swift]
- **`PitchMatchingSession.swift:147-159`** -- Duplicated UserDefaults pattern. [Source: Peach/PitchMatching/PitchMatchingSession.swift]
- **`SoundFontNotePlayer.swift:95`** -- Sound source UserDefaults read without override. [Source: Peach/Core/Audio/SoundFontNotePlayer.swift]
- **`SettingsKeys.swift`** -- All key names and defaults. [Source: Peach/Settings/SettingsKeys.swift]
- **`ComparisonTestHelpers.swift`** -- Current factory pattern with overrides. [Source: PeachTests/Comparison/ComparisonTestHelpers.swift]

### Testing Approach

- **No new test file for UserSettings itself** -- The protocol is trivial. `MockUserSettings` is tested implicitly through all session tests.
- **Existing test rewrite:** `ComparisonSessionUserDefaultsTests` becomes cleaner — instead of `UserDefaults.standard.set(50, forKey:)` + `cleanUpSettingsDefaults()`, use `mockSettings.noteRangeMin = 50`.
- **Existing test rewrite:** `ComparisonSessionLoudnessTests` uses `mockSettings.varyLoudness = 1.0` instead of `varyLoudnessOverride: 1.0`.
- **Verify no `UserDefaults.standard` remains** outside `AppUserSettings` in production code after completion.

### Previous Story Learnings (from 19.2)

- **Value Object types available** -- `MIDINote`, `Cents`, etc. are now defined (from Story 19.2). `UserSettings.noteRangeMin` returns `MIDINote`, not raw `Int`.
- **Mock contract** -- Follow project mock conventions: mutable properties, sensible defaults, no extra tracking needed for a settings mock.

### Git Intelligence

Commit message: `Implement story 19.3: UserSettings wrapper for UserDefaults`

### Project Structure Notes

- `UserSettings.swift` and `AppUserSettings.swift` go in `Peach/Settings/` alongside `SettingsKeys.swift`
- `MockUserSettings.swift` goes in test mock directory (check existing mock locations)
- No new directories needed

### References

- [Source: docs/project-context.md -- Protocol-first design, Composition root]
- [Source: Peach/Comparison/ComparisonSession.swift:68 -- REVIEW comment to resolve]
- [Source: Peach/Settings/SettingsKeys.swift -- Key names and defaults]
- [Source: PeachTests/Comparison/ComparisonTestHelpers.swift -- Current factory pattern]
- [Source: docs/implementation-artifacts/19-2-value-objects-for-domain-primitives.md -- Prerequisite story]

## Change Log

- 2026-02-26: Story created by BMAD create-story workflow from Epic 19 code review plan.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
