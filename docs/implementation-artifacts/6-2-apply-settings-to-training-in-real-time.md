# Story 6.2: Apply Settings to Training in Real Time

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want my setting changes to take effect immediately on the next comparison,
so that I can feel the difference and find my preferred configuration.

## Acceptance Criteria

1. Given the user has changed the Natural vs. Mechanical slider, when the next comparison is selected, then the `AdaptiveNoteStrategy` uses the updated balance ratio
2. Given the user has changed the note range bounds, when the next comparison is selected, then the `AdaptiveNoteStrategy` only selects notes within the new range
3. Given the user has changed the note duration, when the next note is played, then the `NotePlayer` uses the updated duration
4. Given the user has changed the reference pitch, when the next note is played, then frequencies are derived from the new reference pitch
5. Given settings are persisted, when the app is restarted, then all settings retain their last configured values and training uses the persisted settings
6. Given the settings integration, when unit tests are run, then the flow from settings change to TrainingSession reading updated values to effect on next comparison/note is verified

## Tasks / Subtasks

- [x] Task 1: Make TrainingSession read settings from @AppStorage at comparison time (AC: #1, #2, #3, #4, #5)
  - [x] Replace `private let settings: TrainingSettings` with a computed property or on-demand construction that reads current @AppStorage values each time `playNextComparison()` is called
  - [x] Replace `private let noteDuration: TimeInterval = 1.0` with a dynamic read from `@AppStorage("noteDuration")`
  - [x] Pass the live `referencePitch` from settings to `comparison.note1Frequency(referencePitch:)` and `comparison.note2Frequency(referencePitch:)` in `playNextComparison()`
  - [x] Ensure `amplitude` (0.5) and `feedbackDuration` (0.4s) remain hardcoded constants (not user-configurable)
- [x] Task 2: Wire @AppStorage reads into TrainingSession (AC: #1, #2, #3, #4)
  - [x] Add `@AppStorage` properties to TrainingSession for all 6 settings keys (using `SettingsKeys` constants and defaults)
  - [x] Build a fresh `TrainingSettings` from the @AppStorage values at the call site in `playNextComparison()` — this ensures every comparison picks up the latest user settings
  - [x] Read `noteDuration` from the @AppStorage property instead of the hardcoded constant
  - [x] Read `referencePitch` from the @AppStorage property and pass to frequency calculation calls
- [x] Task 3: Update PeachApp initialization (AC: #5)
  - [x] Remove the `settings:` parameter from the `TrainingSession` initializer call in `PeachApp.init()` (TrainingSession now reads @AppStorage directly — no external settings injection needed for production)
  - [x] Keep the `settings:` parameter in the `TrainingSession.init()` signature as an optional override for test injection (default `nil` means "read from @AppStorage")
- [x] Task 4: Update TrainingSession.init() to support both modes (AC: #6)
  - [x] Add an optional `settingsOverride: TrainingSettings?` parameter (default `nil`)
  - [x] When `settingsOverride` is non-nil, use it for all comparisons (test mode — deterministic settings)
  - [x] When `settingsOverride` is nil, read from @AppStorage on each comparison (production mode — live settings)
  - [x] Similarly, add an optional `noteDurationOverride: TimeInterval?` parameter for test determinism
- [x] Task 5: Write tests (AC: #6)
  - [x] Test that TrainingSession with `settingsOverride` uses the override values (existing test pattern preserved)
  - [x] Test that changing @AppStorage values changes the `TrainingSettings` built by TrainingSession (integration test using `UserDefaults.standard`)
  - [x] Test that `noteDuration` from @AppStorage is passed to NotePlayer (verify via mock)
  - [x] Test that `referencePitch` from @AppStorage is passed to frequency calculation (verify via mock or output frequency comparison)
  - [x] Test that settings persist across simulated app restart (write to UserDefaults, create new TrainingSession, verify values)

## Dev Notes

### Architecture & Patterns

- **Direct UserDefaults reads in @Observable class:** `@AppStorage` property wrapper conflicts with `@Observable` macro (both synthesize `_propertyName` backing storage), so TrainingSession uses direct `UserDefaults.standard.object(forKey:)` reads in computed properties instead. Changes from the Settings Screen are immediately visible to TrainingSession on its next read.
- **No notification mechanism needed:** Since TrainingSession reads settings at the start of each comparison (in `playNextComparison()`), there is no need for `NotificationCenter`, Combine, or any observer pattern. The natural polling cadence of the training loop (one read per comparison) provides real-time application.
- **Settings flow after this story:**
  ```
  SettingsScreen (@AppStorage) → UserDefaults ← TrainingSession (UserDefaults.standard)
                                                  ↓
                                         TrainingSettings (fresh each comparison)
                                                  ↓
                                         AdaptiveNoteStrategy.nextComparison()
                                         NotePlayer.play(duration:)
                                         FrequencyCalculation.frequency(referencePitch:)
  ```
- **Test injection preserved:** The `settingsOverride` pattern allows tests to inject deterministic settings without touching UserDefaults, maintaining the existing mock-based test architecture.

### Settings → Component Mapping

| Setting | @AppStorage Key | Consumed By | How Applied |
|---------|----------------|-------------|-------------|
| Natural vs. Mechanical | `"naturalVsMechanical"` | `AdaptiveNoteStrategy` via `TrainingSettings.naturalVsMechanical` | Controls nearby vs. weak spot ratio in `nextComparison()` |
| Note Range Lower | `"noteRangeMin"` | `AdaptiveNoteStrategy` via `TrainingSettings.noteRangeMin` | Filters MIDI notes in comparison selection |
| Note Range Upper | `"noteRangeMax"` | `AdaptiveNoteStrategy` via `TrainingSettings.noteRangeMax` | Filters MIDI notes in comparison selection |
| Note Duration | `"noteDuration"` | `TrainingSession` → `NotePlayer.play(duration:)` | Controls audio playback duration |
| Reference Pitch | `"referencePitch"` | `TrainingSession` → `Comparison.noteXFrequency(referencePitch:)` → `FrequencyCalculation` | Derives Hz from MIDI note |
| Sound Source | `"soundSource"` | Not consumed yet (MVP: sine only) | Future: select NotePlayer implementation |

### Key Code Changes

**TrainingSession.swift — before (hardcoded):**
```swift
private let settings: TrainingSettings          // line 106: stale, never updated
private let noteDuration: TimeInterval = 1.0    // line 109: hardcoded

// In playNextComparison():
let comparison = strategy.nextComparison(profile: profile, settings: settings, ...)  // stale settings
let freq1 = try comparison.note1Frequency()     // line 316: default 440Hz
try await notePlayer.play(frequency: freq1, duration: noteDuration, ...)  // hardcoded 1.0s
```

**TrainingSession.swift — after (live UserDefaults reads):**
```swift
// Optional overrides for testing
private let settingsOverride: TrainingSettings?
private let noteDurationOverride: TimeInterval?

// Build live settings from UserDefaults on each comparison (or use override for tests)
private var currentSettings: TrainingSettings {
    if let override = settingsOverride { return override }
    let defaults = UserDefaults.standard
    return TrainingSettings(
        noteRangeMin: defaults.object(forKey: SettingsKeys.noteRangeMin) as? Int ?? SettingsKeys.defaultNoteRangeMin,
        noteRangeMax: defaults.object(forKey: SettingsKeys.noteRangeMax) as? Int ?? SettingsKeys.defaultNoteRangeMax,
        naturalVsMechanical: defaults.object(forKey: SettingsKeys.naturalVsMechanical) as? Double ?? SettingsKeys.defaultNaturalVsMechanical,
        referencePitch: defaults.object(forKey: SettingsKeys.referencePitch) as? Double ?? SettingsKeys.defaultReferencePitch
    )
}

private var currentNoteDuration: TimeInterval {
    noteDurationOverride ?? (UserDefaults.standard.object(forKey: SettingsKeys.noteDuration) as? Double ?? SettingsKeys.defaultNoteDuration)
}

// In playNextComparison():
let settings = currentSettings
let noteDuration = currentNoteDuration
let comparison = strategy.nextComparison(profile: profile, settings: settings, ...)
let freq1 = try comparison.note1Frequency(referencePitch: settings.referencePitch)
let freq2 = try comparison.note2Frequency(referencePitch: settings.referencePitch)
try await notePlayer.play(frequency: freq1, duration: noteDuration, ...)
```

### What NOT To Change

- **AdaptiveNoteStrategy:** No changes needed. It already receives `TrainingSettings` as a parameter on each call — once TrainingSession passes live settings, the strategy automatically uses them.
- **NextNoteStrategy protocol:** No changes needed. Interface is already correct.
- **Comparison struct:** No changes needed. `note1Frequency(referencePitch:)` and `note2Frequency(referencePitch:)` already accept the parameter — just pass it.
- **FrequencyCalculation:** No changes needed. Already accepts `referencePitch` parameter.
- **SineWaveNotePlayer:** No changes needed. Already accepts `duration` parameter.
- **SettingsScreen:** No changes needed. It already writes to @AppStorage correctly.
- **SettingsKeys:** No changes needed. Keys and defaults are already defined.

### Risks & Edge Cases

- **Settings changed mid-comparison:** If the user somehow changed settings while notes are playing (impossible in practice — Settings Screen stops training), the change would only take effect on the *next* comparison. This is correct behavior per FR36: "applies immediately to subsequent comparisons."
- **Note range excludes all trained notes:** If the user narrows the range to exclude all notes with training data, AdaptiveNoteStrategy falls back to random selection within the new range (cold start behavior). This is correct.
- **@AppStorage thread safety:** `@AppStorage` reads from `UserDefaults.standard` which is thread-safe. Since TrainingSession is `@MainActor`, all reads happen on the main thread — no concurrency concerns.

### Project Structure Notes

- Primary changes in `Peach/Training/TrainingSession.swift` — no new files needed
- Tests in `PeachTests/Training/TrainingSessionTests.swift` — extend existing test file
- No changes to `Peach/Settings/`, `Peach/Core/Algorithm/`, `Peach/Core/Audio/`, or `Peach/App/`
- Follows existing feature-based organization pattern

### References

- [Source: docs/planning-artifacts/epics.md#Story 6.2] — BDD acceptance criteria
- [Source: docs/planning-artifacts/prd.md#FR36] — "System applies setting changes immediately to subsequent comparisons"
- [Source: docs/planning-artifacts/prd.md#FR30-FR35] — Individual settings functional requirements
- [Source: docs/planning-artifacts/architecture.md#Data Architecture] — @AppStorage for settings persistence
- [Source: Peach/Training/TrainingSession.swift:104-115] — Current hardcoded settings (lines to replace)
- [Source: Peach/Training/TrainingSession.swift:306-309] — Strategy call site (pass live settings)
- [Source: Peach/Training/TrainingSession.swift:316-317] — Frequency calculation (pass referencePitch)
- [Source: Peach/Training/TrainingSession.swift:323-334] — NotePlayer.play() calls (pass live duration)
- [Source: Peach/Core/Algorithm/NextNoteStrategy.swift:36-40] — Protocol already accepts TrainingSettings parameter
- [Source: Peach/Core/Algorithm/NextNoteStrategy.swift:54-109] — TrainingSettings struct definition and defaults
- [Source: Peach/Training/Comparison.swift:32-48] — note1Frequency/note2Frequency already accept referencePitch parameter
- [Source: Peach/Core/Audio/FrequencyCalculation.swift:59-74] — Already accepts referencePitch parameter
- [Source: Peach/Settings/SettingsKeys.swift:1-39] — @AppStorage key constants and defaults
- [Source: Peach/App/PeachApp.swift:50-55] — TrainingSession initialization (remove settings: parameter)
- [Source: docs/implementation-artifacts/6-1-settings-screen-with-all-configuration-options.md] — Previous story: Settings Screen implementation details

### Previous Story Learnings (6.1)

- `@AppStorage` keys defined in `SettingsKeys.swift` with static constants — reuse these exact same keys in TrainingSession
- Default values in SettingsKeys match `TrainingSettings` defaults — consistency verified by tests
- `PerceptualProfile.reset()` and `TrendAnalyzer.reset()` exist for data reset — not needed here but confirms @Observable pattern
- `TrainingDataStore.deleteAll()` was added in 6.1 code review — atomic operation pattern
- Pattern: implementation commit, then code review fixes commit
- 227 total tests pass — maintain zero regressions

### Git Intelligence

Recent commits (Story 6.1 completion):
- `2187c44` — Code review fixes for Story 6.1: atomic reset, extract range logic, fix tests
- `3aba032` — Implement story 6.1: Settings Screen with All Configuration Options
- `4aad36a` — Add story 6.1: Settings Screen with All Configuration Options

Pattern: story creation commit → implementation commit → code review fixes commit. Swift Testing framework (`@Test`, `#expect()`). All 227 tests currently pass.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- `@AppStorage` inside `@Observable` class causes `invalid redeclaration of synthesized property` errors — both `@Observable` macro and `@AppStorage` property wrapper synthesize `_propertyName` backing storage. Resolved by switching to direct `UserDefaults.standard` reads in computed properties instead of `@AppStorage` property declarations.
- Swift Testing runs tests in parallel by default, causing UserDefaults-based tests to interfere with each other. Resolved by placing UserDefaults integration tests in a separate `@Suite(.serialized)` to ensure sequential execution.

### Completion Notes List

- **Task 1-2:** Replaced hardcoded `private let settings: TrainingSettings` and `private let noteDuration: TimeInterval = 1.0` with `currentSettings` and `currentNoteDuration` computed properties that read live values from `UserDefaults.standard` on each comparison. Used `@ObservationIgnored`-free approach: direct `UserDefaults.standard.object(forKey:)` reads in computed properties to avoid `@Observable` macro conflicts.
- **Task 3:** PeachApp.init() already did not pass `settings:` (used default), so no change needed. The old `settings:` parameter was replaced by `settingsOverride:` in Task 4.
- **Task 4:** Added `settingsOverride: TrainingSettings? = nil` and `noteDurationOverride: TimeInterval? = nil` parameters to `TrainingSession.init()`. When non-nil, overrides are used (deterministic test mode). When nil, reads from UserDefaults (production mode).
- **Task 5:** Added 6 new tests: `settingsOverrideUsesOverrideValues`, `noteDurationOverrideTakesPrecedence`, `userDefaultsChangesAffectSettings`, `noteDurationFromUserDefaultsPassedToPlayer`, `referencePitchFromUserDefaultsAffectsFrequency`, `settingsPersistAcrossRestart`. Updated existing `strategyReceivesCorrectSettings` test to use `settingsOverride:` parameter. UserDefaults tests placed in serialized suite for isolation.
- **Refactoring:** Updated `makeTrainingSession()` test helper to use `settingsOverride: TrainingSettings()` and `noteDurationOverride: 1.0` for deterministic behavior in existing tests (prevents UserDefaults pollution from new tests).
- **All 233 tests pass** (227 existing + 6 new, zero regressions).

### Code Review Fixes

- Cached `currentNoteDuration` per comparison in `playNextComparison()` for consistency with `currentSettings` caching pattern — prevents theoretical mid-comparison duration mismatch
- Added `settingsChangedMidTrainingTakeEffect` test verifying that UserDefaults changes between comparisons are picked up on the next comparison (the core "real-time" promise)
- Fixed Dev Notes "Architecture & Patterns" section: corrected @AppStorage/@Observable claim to reflect actual approach (direct UserDefaults reads), updated code examples and flow diagram
- Removed stale "Epic 6 will..." docstrings from `Comparison.swift` and `NextNoteStrategy.swift`
- **All 234 tests pass** (227 existing + 7 new, zero regressions).

### Change Log

- 2026-02-17: Implemented Story 6.2 — TrainingSession reads settings from UserDefaults on each comparison, enabling real-time settings application. Added settingsOverride/noteDurationOverride for test injection. 6 new tests. 233 total tests pass.
- 2026-02-17: Code review fixes — cached noteDuration per comparison, added mid-training settings change test, fixed stale docs. 234 total tests pass.

### File List

- Peach/Training/TrainingSession.swift (modified)
- Peach/Training/Comparison.swift (modified)
- Peach/Core/Algorithm/NextNoteStrategy.swift (modified)
- PeachTests/Training/TrainingSessionTests.swift (modified)
- docs/implementation-artifacts/6-2-apply-settings-to-training-in-real-time.md (modified)
- docs/implementation-artifacts/sprint-status.yaml (modified)
