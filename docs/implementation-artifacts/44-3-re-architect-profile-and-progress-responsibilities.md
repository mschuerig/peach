# Story 44.3: Re-Architect Profile and Progress Responsibilities

Status: done

## Story

As a **developer**,
I want PerceptualProfile to own all per-mode statistical state (Welford, EWMA, trend) and ProgressTimeline to be a pure presentation layer that reads from the profile,
So that domain truth lives in one place, storage coupling is removed, and both types have clear single responsibilities.

## Acceptance Criteria

1. **Given** PerceptualProfile currently tracks only 2 aggregates (comparison, matching), **when** the refactoring is complete, **then** it tracks 4 independent modes (`unisonPitchComparison`, `intervalPitchComparison`, `unisonMatching`, `intervalMatching`) with per-mode Welford statistics, EWMA, and trend — matching the modes ProgressTimeline currently tracks.

2. **Given** ProgressTimeline currently duplicates Welford's algorithm in its `ModeState`, **when** the refactoring is complete, **then** a single shared `ModeStatistics` value type (containing `WelfordAccumulator`, EWMA, trend, and time-ordered metrics) is used by PerceptualProfile, and ProgressTimeline contains no statistical computation of its own.

3. **Given** ProgressTimeline currently conforms to `PitchComparisonObserver` and `PitchMatchingObserver`, **when** the refactoring is complete, **then** only PerceptualProfile conforms to those observer protocols. ProgressTimeline is no longer registered as an observer and receives no training events directly.

4. **Given** ProgressTimeline currently takes `[PitchComparisonRecord]` and `[PitchMatchingRecord]` in its `rebuild()` method and `TrainingMode.extractMetrics()` filters storage records directly, **when** the refactoring is complete, **then** neither PerceptualProfile nor ProgressTimeline imports or references storage record types. Record-to-metric mapping lives in the app composition layer.

5. **Given** ProgressTimeline currently owns time bucketing, EWMA queries, trend queries, and state queries, **when** the refactoring is complete, **then** ProgressTimeline retains only time bucketing / chart formatting (`buckets(for:)`, `allGranularityBuckets(for:)`, `subBuckets(for:)`) and delegates `currentEWMA(for:)`, `trend(for:)`, `state(for:)`, and `recordCount(for:)` to PerceptualProfile.

6. **Given** PerceptualProfile currently exposes `comparisonMean` and `matchingMean` as flat aggregates, **when** the refactoring is complete, **then** `PitchComparisonProfile` exposes `comparisonMean(for: DirectedInterval) -> Cents?` (per-mode, not aggregate), `PitchMatchingProfile` retains `matchingMean`, `matchingStdDev`, `matchingSampleCount`, and the dead methods `updateComparison`, `updateMatching` and aggregate `comparisonStdDev` are removed. `resetComparison()` and `resetMatching()` are removed in favor of `resetAll()`. `ModeStatistics` is renamed to `TrainingModeStatistics`.

7. **Given** all existing tests for ProgressTimeline, PerceptualProfile, ProfileScreen, ProgressChartView, strategies, and data import, **when** they are run after the refactoring, **then** all tests pass — no behavioral changes to user-visible functionality.

## Tasks / Subtasks

- [x] Task 1: Extract `ModeStatistics` and shared `WelfordAccumulator` (AC: #2)
  - [x] Extract `WelfordAccumulator` from PerceptualProfile's private struct into a shared internal type at `Core/Profile/WelfordAccumulator.swift`
  - [x] Create `ModeStatistics` value type at `Core/Profile/ModeStatistics.swift` containing: `WelfordAccumulator`, EWMA (`Double?`), trend (`Trend?`), time-ordered `[MetricPoint]`, and `addPoint(_:config:)` with EWMA/trend recomputation — extracted from ProgressTimeline's `ModeState`
  - [x] Create `MetricPoint` as a shared type (timestamp + value) at `Core/Profile/MetricPoint.swift`
  - [x] Write tests for `ModeStatistics`: Welford correctness, EWMA computation, trend detection
  - [x] Run `bin/test.sh` to confirm

- [x] Task 2: Expand PerceptualProfile to be mode-aware (AC: #1, #6)
  - [x] Replace the two `WelfordAccumulator` fields with `[TrainingMode: ModeStatistics]`
  - [x] Add per-mode query API: `statistics(for: TrainingMode) -> ModeStatistics?`, `hasData(for: TrainingMode) -> Bool`, `trend(for: TrainingMode) -> Trend?`, `currentEWMA(for: TrainingMode) -> Double?`, `recordCount(for: TrainingMode) -> Int`
  - [x] Preserve backward-compatible aggregate accessors: `comparisonMean` derives from unison+interval comparison modes combined, `matchingMean` from unison+interval matching modes combined (weighted by sample count)
  - [x] Update `PitchComparisonProfile` and `PitchMatchingProfile` protocols if needed — existing strategy consumers must keep working
  - [x] Update observer conformances to dispatch to the correct `TrainingMode` based on interval (unison vs interval)
  - [x] Update `resetComparison()` to reset both comparison modes, `resetMatching()` to reset both matching modes
  - [x] Add `rebuild(metrics: [TrainingMode: [MetricPoint]])` method for cold-start loading
  - [x] Update existing PerceptualProfile tests; add new tests for per-mode queries
  - [x] Run `bin/test.sh` to confirm

- [x] Task 3: Create record-to-metric mapper in app layer (AC: #4)
  - [x] Create `MetricPointMapper` (enum with static methods) at `App/MetricPointMapper.swift`
  - [x] Move `TrainingMode.extractMetrics(pitchComparisonRecords:pitchMatchingRecords:)` logic into the mapper
  - [x] Move `TrainingMode.metric(from: CompletedPitchComparison)` and `metric(from: CompletedPitchMatching)` logic into the mapper
  - [x] Update `PeachApp` cold-start to use mapper: records → `[TrainingMode: [MetricPoint]]` → `profile.rebuild(metrics:)`
  - [x] Update `TrainingDataTransferService` import path to use mapper
  - [x] Remove `extractMetrics` and `metric(from:)` methods from `TrainingMode` (deferred to Task 4 — ProgressTimeline still uses them)
  - [x] Run `bin/test.sh` to confirm

- [x] Task 4: Slim ProgressTimeline to pure presentation (AC: #3, #5)
  - [x] Add `PerceptualProfile` as an init dependency of ProgressTimeline
  - [x] Delegate `state(for:)`, `currentEWMA(for:)`, `trend(for:)`, `recordCount(for:)` to the profile
  - [x] Read `profile.statistics(for:)?.metrics` for bucketing instead of maintaining internal `ModeState`
  - [x] Remove `ModeState`, `MetricPoint` (now shared), `addMetric`, `buildModeState`, `rebuild`, `reset` from ProgressTimeline
  - [x] Remove `PitchComparisonObserver` and `PitchMatchingObserver` conformances from ProgressTimeline
  - [x] Remove `Resettable` conformance from ProgressTimeline (profile handles reset)
  - [x] Remove ProgressTimeline from observer registration in `PeachApp`
  - [x] Update `PeachApp` to pass profile into ProgressTimeline init
  - [x] Update ProgressTimeline tests to construct with a profile
  - [x] Run `bin/test.sh` to confirm

- [x] Task 5: Clean up TrainingMode and verify environment injection (AC: #4, #7)
  - [x] Remove storage-record-related imports from `TrainingMode` if any remain
  - [x] Verify environment injection still works: `ProfileScreen`, `ProgressChartView`, `ChartImageRenderer`, `ExportChartView` all read from ProgressTimeline which now delegates to profile
  - [x] Run `bin/build.sh` — zero errors, zero warnings
  - [x] Run `bin/test.sh` — all tests pass

## Dev Notes

### Problem diagnosis

ProgressTimeline (565 lines) has absorbed nearly all responsibilities that should belong to PerceptualProfile (123 lines). It directly couples to storage records, duplicates Welford's algorithm, owns EWMA/trend computation, and acts as a parallel observer — while PerceptualProfile is reduced to a thin wrapper around two flat accumulators with no mode awareness.

### Architecture after refactoring

```
Training Sessions
    │
    ▼ observer notification
[TrainingDataStore, PerceptualProfile, HapticFeedbackManager]
                         │
                         │ @Observable
                         ▼
                  ProgressTimeline (reads profile, formats for charts)
```

**PerceptualProfile** becomes the single source of truth:
- Owns `[TrainingMode: ModeStatistics]` — 4 independent mode trackers
- Conforms to observer protocols — single observer chain
- Provides per-mode queries (statistics, trend, EWMA, state)
- Backward-compatible aggregate accessors for strategies
- `rebuild(metrics:)` takes domain-level `[TrainingMode: [MetricPoint]]`, not records

**ProgressTimeline** becomes a presentation layer:
- Takes `PerceptualProfile` as init dependency
- Only owns time bucketing: session/day/month zone assignment, sub-bucket drill-down
- Delegates all statistical queries to profile
- No observer conformances, no rebuild, no reset, no Welford

**ModeStatistics** is the shared statistical engine:
- Contains `WelfordAccumulator`, EWMA, trend, time-ordered metrics
- `addPoint(_:config:)` for incremental updates
- Used by PerceptualProfile, tested independently

**MetricPointMapper** lives in the app layer:
- Converts `PitchComparisonRecord` / `PitchMatchingRecord` → `[TrainingMode: [MetricPoint]]`
- Neither profile nor timeline imports storage record types

### Backward compatibility for strategies

`KazezNoteStrategy` and `NextPitchComparisonStrategy` consume `comparisonMean` via `PitchComparisonProfile`. The aggregate accessors must continue to work. Derive them by combining the relevant mode statistics:

```swift
var comparisonMean: Cents? {
    let unison = modes[.unisonPitchComparison]
    let interval = modes[.intervalPitchComparison]
    // weighted mean across both modes
}
```

### ProgressTimeline bucketing reads from profile

The three bucketing methods (`assignBuckets`, `assignMultiGranularityBuckets`, `assignSubBuckets`) currently operate on `ModeState.allMetrics`. After refactoring, they read `profile.statistics(for: mode)?.metrics` instead. The bucketing algorithms themselves are unchanged.

### Migration order matters

Tasks must be done in order (1 → 2 → 3 → 4 → 5). Each task is independently testable — existing tests pass at each step.

### Anti-patterns to avoid

- **Do NOT add RhythmProfile conformance** — that's Epic 45+ work
- **Do NOT rename PerceptualProfile** — protocol-agnostic name is correct
- **Do NOT change bucketing algorithms** — only move where data is read from
- **Do NOT change EWMA half-life, session gap, or trend thresholds** — behavioral parity is required
- **Do NOT make ModeStatistics a class** — it should be a value type for predictable mutation semantics inside the dictionary

### References

- [Source: docs/planning-artifacts/epics.md — Epic 44, Stories 44.1–44.2]
- [Source: docs/planning-artifacts/architecture.md — v0.4 Amendment, "Prerequisite Refactorings"]
- [Source: docs/project-context.md — Domain types everywhere, Code Style, File Placement]
- [Source: Peach/Core/Profile/ProgressTimeline.swift — current 565-line implementation]
- [Source: Peach/Core/Profile/PerceptualProfile.swift — current 123-line implementation]

## Post-Review Fixes

Code review (adversarial 3-layer review + manual findings) identified 8 patch items, all applied:

1. **Removed dead protocol methods**: `updateComparison` from `PitchComparisonProfile`, `updateMatching` from `PitchMatchingProfile` — zero production callers, mutations happen through observer protocols
2. **Removed semantically wrong aggregate**: `comparisonMean` property combined unison + interval mode data via weighted mean — meaningless across independent training modes. Replaced with `comparisonMean(for: DirectedInterval) -> Cents?` which queries the correct mode
3. **Removed `comparisonStdDev`**: zero production callers, removed from protocol and implementation
4. **Removed `resetComparison()` / `resetMatching()`**: zero production callers, only `resetAll()` retained
5. **Removed `weightedMean` / `weightedStdDev` helpers**: supported the removed aggregates
6. **Renamed `ModeStatistics` → `TrainingModeStatistics`**: avoids ambiguity with unrelated statistics concepts
7. **Deleted dead `MetricPointMapper.metricPoint(from:)` overloads**: zero callers
8. **Restructured `MetricPointMapper.extractMetrics`**: iterates `TrainingMode.allCases` with switch for extensibility
9. **Fixed indentation**: `ResettableTests.swift` line 25

Updated `KazezNoteStrategy` (sole production consumer) to use `profile.comparisonMean(for: interval)`. Updated 15 test files. All 1078 tests pass.

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6

### Debug Log References

### Completion Notes List

- Task 1: Extracted `WelfordAccumulator` into shared type with `populationStdDev`; created `MetricPoint` as shared type; created `ModeStatistics` value type with Welford, EWMA, trend, and time-ordered metrics
- Task 2: Expanded `PerceptualProfile` to use `[TrainingMode: ModeStatistics]`, added per-mode query API, backward-compatible aggregate accessors via Chan's parallel algorithm, observer conformances dispatch to correct mode based on interval
- Task 3: Created `MetricPointMapper` in app layer; updated `PeachApp` cold-start and `TrainingDataTransferService` import path to use mapper
- Task 4: Slimmed `ProgressTimeline` from ~565 lines to ~330 lines; now a pure presentation layer that reads from `PerceptualProfile`; removed observer conformances, `Resettable`, `rebuild`, `reset`, `ModeState`; updated all test files to construct timelines via profile
- Task 5: Verified no storage-record imports remain in `TrainingMode` or `ProgressTimeline`; confirmed environment injection chain works for all consuming views; build succeeds with zero warnings; all 1086 tests pass

### File List

New files:
- Peach/Core/Profile/WelfordAccumulator.swift
- Peach/Core/Profile/MetricPoint.swift
- Peach/Core/Profile/ModeStatistics.swift
- Peach/App/MetricPointMapper.swift
- PeachTests/Core/Profile/ModeStatisticsTests.swift

Modified files:
- Peach/Core/Profile/PerceptualProfile.swift (rewritten: mode-aware with [TrainingMode: ModeStatistics])
- Peach/Core/Profile/ProgressTimeline.swift (rewritten: pure presentation layer, delegates to profile)
- Peach/App/PeachApp.swift (updated composition root: MetricPointMapper, profile-first init)
- Peach/App/EnvironmentKeys.swift (ProgressTimeline default uses profile)
- Peach/Profile/ProfileScreen.swift (preview updated to use profile-based timeline)
- PeachTests/Core/Profile/PerceptualProfileTests.swift (rewritten for per-mode API)
- PeachTests/Core/Profile/ProgressTimelineTests.swift (rewritten: profile-based construction)
- PeachTests/PitchComparison/PitchComparisonSessionResetTests.swift (profile-based reset test)
- PeachTests/Core/Training/ResettableTests.swift (removed ProgressTimeline Resettable test)
- PeachTests/Settings/TrainingDataImportActionTests.swift (removed progressTimeline param)
- PeachTests/Settings/SettingsTests.swift (profile-based reset test)
- PeachTests/Profile/ExportChartViewTests.swift (profile-based timeline construction)
- PeachTests/Profile/ProfileScreenLayoutTests.swift (profile-based timeline construction)
- PeachTests/Profile/ProgressChartViewTests.swift (profile-based timeline construction)
