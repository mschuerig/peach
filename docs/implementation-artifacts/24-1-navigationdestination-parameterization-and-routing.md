# Story 24.1: NavigationDestination Parameterization and Routing

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want the navigation system to route interval training modes to the existing training screens with the correct interval parameters,
So that tapping an interval button launches the same screen with the interval context passed through.

## Acceptance Criteria

### AC 1: Rename `.training` to `.comparison(intervals:)`
**Given** `NavigationDestination` has a `.training` case
**When** it is renamed to `.comparison(intervals: Set<Interval>)`
**Then** all existing navigation to comparison training uses `.comparison(intervals: [.prime])`

### AC 2: Parameterize `.pitchMatching` with intervals
**Given** `NavigationDestination` has a `.pitchMatching` case
**When** it gains an `intervals` parameter as `.pitchMatching(intervals: Set<Interval>)`
**Then** all existing navigation to pitch matching uses `.pitchMatching(intervals: [.prime])`

### AC 3: ComparisonScreen routing with intervals
**Given** the destination handler in `ContentView`
**When** routing `.comparison(let intervals)`
**Then** `ComparisonScreen(intervals: intervals)` is created
**And** the screen calls `session.start(intervals: intervals)`

### AC 4: PitchMatchingScreen routing with intervals
**Given** the destination handler routing `.pitchMatching(let intervals)`
**When** navigating
**Then** `PitchMatchingScreen(intervals: intervals)` is created
**And** the screen calls `session.start(intervals: intervals)`

### AC 5: Hashable conformance preserved
**Given** `NavigationDestination` conforms to `Hashable`
**When** `Set<Interval>` is a parameter
**Then** the enum remains `Hashable` (since `Interval` is `Hashable`)

## Tasks / Subtasks

- [x] Task 1: Parameterize `NavigationDestination` enum (AC: 1, 2, 5)
  - [x] Rename `.training` to `.comparison(intervals: Set<Interval>)`
  - [x] Add `intervals: Set<Interval>` parameter to `.pitchMatching`
  - [x] Verify `Hashable` conformance compiles (Interval is already Hashable)
- [x] Task 2: Update session `start()` to accept intervals parameter (AC: 3, 4)
  - [x] Add `intervals: Set<Interval>` parameter to `ComparisonSession.start(intervals:)`
  - [x] Add `intervals: Set<Interval>` parameter to `PitchMatchingSession.start(intervals:)`
  - [x] Update `TrainingSession` protocol if `start()` is defined there
  - [x] Sessions use passed intervals instead of reading from `userSettings.intervals`
- [x] Task 3: Update `ComparisonScreen` to accept and pass intervals (AC: 3)
  - [x] Add `intervals: Set<Interval>` init parameter to `ComparisonScreen`
  - [x] Pass intervals to `comparisonSession.start(intervals: intervals)` in `.onAppear`
- [x] Task 4: Update `PitchMatchingScreen` to accept and pass intervals (AC: 4)
  - [x] Add `intervals: Set<Interval>` init parameter to `PitchMatchingScreen`
  - [x] Pass intervals to `pitchMatchingSession.start(intervals: intervals)` in `.onAppear`
- [x] Task 5: Update destination handler routing (AC: 3, 4)
  - [x] Update `ContentView` or `StartScreen` `.navigationDestination` handler
  - [x] Route `.comparison(let intervals)` → `ComparisonScreen(intervals: intervals)`
  - [x] Route `.pitchMatching(let intervals)` → `PitchMatchingScreen(intervals: intervals)`
- [x] Task 6: Update all existing NavigationLink call sites (AC: 1, 2)
  - [x] Replace `.training` → `.comparison(intervals: [.prime])` in StartScreen
  - [x] Replace `.pitchMatching` → `.pitchMatching(intervals: [.prime])` in StartScreen
- [x] Task 7: Update all tests — 146 `.start()` call sites across 13 test files (AC: 1-5)
  - [x] Update ComparisonSession tests (8 files, ~80 calls): `start()` → `start(intervals: [.prime])`
  - [x] Update PitchMatchingSession tests (1 file, ~53 calls): `start()` → `start(intervals: [.prime])`
  - [x] Update TrainingSession protocol tests (1 file, ~7 calls)
  - [x] Update ComparisonScreenFeedbackTests (1 file, ~5 calls)
  - [x] Add new test: `start(intervals: [.perfectFifth])` verifies sessionIntervals
  - [x] Add new test: `start(intervals: [.prime, .perfectFifth])` with multiple intervals
  - [x] Run full test suite

## Dev Notes

### Developer Context — Critical Implementation Intelligence

This story parameterizes the navigation system so that interval training modes can route to the same screens with different interval sets. It is a prerequisite for Story 24.2 (Start Screen four training buttons). After this story, the navigation infrastructure supports any interval set — Story 24.2 simply adds the interval buttons.

**What this story changes:**
- `NavigationDestination` enum: from flat cases to parameterized cases with `intervals: Set<Interval>`
- Screen constructors: accept `intervals` parameter
- Session `start()`: accept `intervals` parameter (overrides `userSettings.intervals`)
- All existing call sites: pass `[.prime]` to preserve current unison behavior

**What this story does NOT change:**
- No new UI buttons (that's Story 24.2)
- No changes to the training loop, feedback, or comparison logic
- No changes to data recording, observers, or profile
- No changes to `AppUserSettings.intervals` property

### Technical Requirements

**NavigationDestination parameterization:**

Current (`Peach/App/NavigationDestination.swift:1-10`):
```swift
enum NavigationDestination: Hashable {
    case training
    case pitchMatching
    case settings
    case profile
}
```

Target:
```swift
enum NavigationDestination: Hashable {
    case comparison(intervals: Set<Interval>)
    case pitchMatching(intervals: Set<Interval>)
    case settings
    case profile
}
```

Key detail: `Interval` already conforms to `Hashable` (it's an `Int`-backed enum), and `Set<Interval>` is `Hashable` by default in Swift when `Element: Hashable`. So the enum remains `Hashable` without any manual conformance.

**Session `start()` signature change:**

Both `ComparisonSession.start()` and `PitchMatchingSession.start()` currently read `userSettings.intervals` in their `start()` method. This story changes them to accept intervals as a parameter:

```swift
// ComparisonSession — current (line ~105):
func start() {
    precondition(!userSettings.intervals.isEmpty, "intervals must not be empty")
    sessionIntervals = userSettings.intervals
    ...
}

// Target:
func start(intervals: Set<Interval>) {
    precondition(!intervals.isEmpty, "intervals must not be empty")
    sessionIntervals = intervals
    ...
}
```

Same pattern for `PitchMatchingSession.start()` (line ~81).

**TrainingSession protocol update:** The `TrainingSession` protocol was updated in Story 23.3 to include `start()`. It needs to be updated to `start(intervals: Set<Interval>)`.

**Important: `userSettings.intervals` still exists** but is no longer read by the sessions' `start()` method. It remains available for potential future use (e.g., default interval set in settings UI). The `AppUserSettings.intervals` hardcoded return of `[.perfectFifth]` can stay as-is — it's no longer on the critical path.

### Architecture Compliance

**Required patterns from architecture document:**

1. **NavigationDestination enum for type-safe routing** — no string-based navigation [Source: docs/project-context.md#Framework-Specific Rules]
2. **Rename `.training` → `.comparison`** — aligns with v0.2 session/screen renames done in Epic 11 [Source: docs/planning-artifacts/architecture.md#Navigation & Start Screen]
3. **Screen reuse, not duplication** — same ComparisonScreen/PitchMatchingScreen, just parameterized [Source: docs/planning-artifacts/ux-design-specification.md#Key Design Decisions]
4. **Composition root wiring** — `PeachApp.swift` is the single dependency graph source of truth; screens get sessions via `@Environment` [Source: docs/project-context.md#Composition Root]
5. **No cross-feature coupling** — `Start/` is exempt from the cross-feature rule as it's the navigation router [Source: docs/project-context.md#Dependency Direction Rules]

**Architecture code pattern for destination handler** [Source: docs/planning-artifacts/architecture.md line ~1306]:
```swift
.navigationDestination(for: NavigationDestination.self) { destination in
    switch destination {
    case .comparison(let intervals):
        ComparisonScreen(intervals: intervals)
    case .pitchMatching(let intervals):
        PitchMatchingScreen(intervals: intervals)
    case .settings:
        SettingsScreen()
    case .profile:
        ProfileScreen()
    }
}
```

### Library/Framework Requirements

- **SwiftUI `NavigationStack`** — value-based routing with `.navigationDestination(for:)`, already in use
- **No new dependencies** — zero third-party packages
- **Swift 6.2** — default MainActor isolation; `Set<Interval>` is `Sendable` because `Interval` is `Sendable` (Int-backed enum)
- **`Interval` enum** — defined in `Peach/Core/Audio/Interval.swift`, already `Hashable`, `Comparable`, `Sendable`, `CaseIterable`, `Codable`

### File Structure — Files to Modify

| File | Change | Why |
|------|--------|-----|
| `Peach/App/NavigationDestination.swift` | Rename `.training` → `.comparison(intervals:)`, add `intervals` to `.pitchMatching` | Core enum change |
| `Peach/App/ContentView.swift` | Update destination handler switch cases | Routing |
| `Peach/Start/StartScreen.swift` | Update `NavigationLink` values from `.training` → `.comparison(intervals: [.prime])` and `.pitchMatching` → `.pitchMatching(intervals: [.prime])` | Call site update |
| `Peach/Comparison/ComparisonScreen.swift` | Add `intervals: Set<Interval>` init parameter, pass to `session.start(intervals:)` | Screen parameterization |
| `Peach/PitchMatching/PitchMatchingScreen.swift` | Add `intervals: Set<Interval>` init parameter, pass to `session.start(intervals:)` | Screen parameterization |
| `Peach/Comparison/ComparisonSession.swift` | Change `start()` → `start(intervals: Set<Interval>)` | Session API |
| `Peach/PitchMatching/PitchMatchingSession.swift` | Change `start()` → `start(intervals: Set<Interval>)` | Session API |
| `Peach/Core/Training/TrainingSession.swift` | Update `start()` protocol requirement if present | Protocol update |
| `PeachTests/Comparison/ComparisonSessionTests.swift` | Update 18 `start()` → `start(intervals: [.prime])` | Test updates |
| `PeachTests/Comparison/ComparisonSessionLifecycleTests.swift` | Update 13 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionIntegrationTests.swift` | Update 11 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionAudioInterruptionTests.swift` | Update 11 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionDifficultyTests.swift` | Update 7 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionFeedbackTests.swift` | Update 6 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionLoudnessTests.swift` | Update 6 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonScreenFeedbackTests.swift` | Update 5 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionUserDefaultsTests.swift` | Update 4 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionSettingsTests.swift` | Update 4 `start()` calls | Test updates |
| `PeachTests/Comparison/ComparisonSessionResetTests.swift` | Update 1 `start()` call | Test updates |
| `PeachTests/PitchMatching/PitchMatchingSessionTests.swift` | Update 53 `start()` → `start(intervals: [.prime])` | Test updates |
| `PeachTests/Core/TrainingSessionTests.swift` | Update 7 `start()` calls, update protocol test | Test updates |

**Files NOT to modify:**
- `Peach/Settings/UserSettings.swift` — `intervals` property stays
- `Peach/Settings/AppUserSettings.swift` — hardcoded `[.perfectFifth]` stays (no longer on critical path)
- `Peach/App/PeachApp.swift` — no composition root changes needed (sessions already injected via environment)
- `Peach/App/EnvironmentKeys.swift` — no new environment entries

**Note on `StartScreen.swift` destination handler:** The destination handler (`.navigationDestination(for:)`) currently appears in `StartScreen.swift` (lines 72-83), NOT in `ContentView.swift`. The architecture doc says `ContentView`, but the actual codebase has it in `StartScreen`. Follow the codebase — update in `StartScreen.swift`.

### Testing Requirements

**TDD approach — write failing tests first:**

1. **NavigationDestination tests** — verify `.comparison(intervals:)` and `.pitchMatching(intervals:)` are `Hashable`:
   - Two destinations with same intervals are equal
   - Two destinations with different intervals are not equal
   - Can be used as NavigationStack path values

2. **ComparisonSession tests** — update `start()` calls:
   - All existing tests pass `start(intervals: [.prime])` — preserves unison behavior
   - New test: `start(intervals: [.perfectFifth])` sets `sessionIntervals` correctly
   - New test: `start(intervals: [.prime, .perfectFifth])` works with multiple intervals
   - Empty intervals precondition: verify crash/precondition failure

3. **PitchMatchingSession tests** — mirror ComparisonSession pattern:
   - All existing tests pass `start(intervals: [.prime])` — preserves unison behavior
   - New test: `start(intervals: [.perfectFifth])` sets `sessionIntervals` correctly

4. **No UI tests needed** — UI doesn't change visually (same two buttons, same screens)

**Test execution:** `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`

### Previous Story Intelligence (Epic 23)

**From Story 23.2 (ComparisonSession interval parameterization):**
- `start()` already stores `sessionIntervals = userSettings.intervals` and `sessionTuningSystem = userSettings.tuningSystem`
- `currentInterval` observable property already exists, updated each comparison
- `isIntervalMode` computed property: `currentInterval != nil && currentInterval != .prime`
- Strategy operates in logical world only — no tuning system parameter
- `MockUserSettings` defaults to `intervals: [.prime]`, `tuningSystem: .equalTemperament`

**From Story 23.3 (PitchMatchingSession interval parameterization):**
- Mirrors 23.2 pattern exactly
- `start()` stores `sessionIntervals` and `sessionTuningSystem`
- Critical: `referenceFrequency` uses target note frequency (not reference note), enabling correct slider behavior for intervals
- `TrainingSession` protocol gained `start()` method — needs updating to `start(intervals:)`

**From Story 23.4 (Training screen interval label):**
- `displayName` property on `Interval` already implemented
- Conditional interval label already on both screens (`if comparisonSession.isIntervalMode`)
- All 14 localization entries already added
- Parameterized test pattern: use `@Test(arguments: Interval.allCases)` for interval-related tests

**Key learning:** `tuningSystem` should continue to come from `userSettings` (not from navigation). Only `intervals` needs to be navigation-parameterized. The tuning system is a global preference, not a per-mode setting.

### Git Intelligence

Recent commits (all Epic 23 interval work):
```
c233a51 Fix code review findings for story 23.4 and mark done
c2661fc Implement story 23.4: Training Screen Interval Label and Observer Verification
df1f03f Fix code review findings for story 23.3 and mark done
6c3d844 Implement story 23.3: PitchMatchingSession Start Rename, Interval Support, and Protocol Update
782e38a Fix code review findings for story 23.2 and mark done
e5cd431 Implement story 23.2: ComparisonSession Start Rename and Strategy Interval Support
```

**Pattern:** Each story was implemented then code-reviewed. Code review findings led to follow-up commits. Expect similar pattern for this story.

### Project Structure Notes

- All changes align with existing project structure
- No new files needed — only modifications to existing files
- `NavigationDestination.swift` stays in `App/` directory
- Screen files stay in their feature directories
- No new environment keys needed
- No cross-feature coupling introduced (Start/ is exempt as navigation router)

### References

- [Source: docs/planning-artifacts/epics.md#Epic 24, Story 24.1] — Story definition and ACs
- [Source: docs/planning-artifacts/architecture.md#Navigation & Start Screen] — NavigationDestination parameterization pattern
- [Source: docs/planning-artifacts/architecture.md#v0.3 Implementation Sequence] — Steps 11-12 cover this story
- [Source: docs/planning-artifacts/ux-design-specification.md#Interval Training — UX Design Amendment (v0.3)] — Start Screen button layout spec
- [Source: docs/project-context.md#Framework-Specific Rules] — NavigationDestination enum for type-safe routing
- [Source: docs/project-context.md#Composition Root] — PeachApp.swift wiring rules
- [Source: docs/implementation-artifacts/23-2-comparisonsession-and-strategy-interval-parameterization.md] — Session start() and interval patterns
- [Source: docs/implementation-artifacts/23-3-pitchmatchingsession-interval-parameterization.md] — PitchMatchingSession start() pattern

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None — clean implementation with no blockers.

### Completion Notes List

- Renamed `NavigationDestination.training` to `.comparison(intervals: Set<Interval>)` and added `intervals` parameter to `.pitchMatching`
- Updated `TrainingSession` protocol: `start()` → `start(intervals: Set<Interval>)`
- Updated `ComparisonSession.start()` and `PitchMatchingSession.start()` to accept intervals parameter directly instead of reading from `userSettings.intervals`
- Added `intervals: Set<Interval>` init parameter to both `ComparisonScreen` and `PitchMatchingScreen`
- Updated destination handler in `StartScreen.swift` to pass intervals through routing
- Updated all NavigationLink call sites to pass `[.prime]` preserving existing unison behavior
- Updated 146 `.start()` calls across 13 test files to use `start(intervals: [.prime])`
- Fixed 9 interval-specific tests that needed `start(intervals: [.perfectFifth])` instead of `[.prime]`
- Added new NavigationDestination Hashable tests for different intervals
- Added new `start(intervals: [.perfectFifth])` and `start(intervals: [.prime, .perfectFifth])` tests for both sessions
- All 701 tests pass, 0 failures
- Dependency check passes

### File List

- `Peach/App/NavigationDestination.swift` — Renamed `.training` → `.comparison(intervals:)`, added `intervals` to `.pitchMatching`
- `Peach/Core/TrainingSession.swift` — Updated `start()` → `start(intervals: Set<Interval>)` in protocol
- `Peach/Comparison/ComparisonSession.swift` — Updated `start()` → `start(intervals: Set<Interval>)`
- `Peach/PitchMatching/PitchMatchingSession.swift` — Updated `start()` → `start(intervals: Set<Interval>)`
- `Peach/Comparison/ComparisonScreen.swift` — Added `intervals: Set<Interval>` init parameter, pass to session
- `Peach/PitchMatching/PitchMatchingScreen.swift` — Added `intervals: Set<Interval>` init parameter, pass to session
- `Peach/Start/StartScreen.swift` — Updated destination handler and NavigationLink call sites
- `PeachTests/Start/StartScreenTests.swift` — Updated NavigationDestination tests, added interval equality tests
- `PeachTests/Comparison/ComparisonSessionTests.swift` — Updated start() calls, fixed interval tests, added new tests
- `PeachTests/Comparison/ComparisonSessionLifecycleTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionIntegrationTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionAudioInterruptionTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionDifficultyTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionFeedbackTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionLoudnessTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonScreenFeedbackTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionUserDefaultsTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionSettingsTests.swift` — Updated start() calls
- `PeachTests/Comparison/ComparisonSessionResetTests.swift` — Updated start() call
- `PeachTests/PitchMatching/PitchMatchingSessionTests.swift` — Updated start() calls, fixed interval tests, added new tests
- `PeachTests/Core/TrainingSessionTests.swift` — Updated start() calls for protocol tests

### Change Log

- 2026-03-01: Implemented story 24.1 — parameterized NavigationDestination and session start() with intervals
