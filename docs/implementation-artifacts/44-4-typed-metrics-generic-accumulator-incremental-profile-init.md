# Story 44.4: Typed Metrics, Generic Accumulator, and Incremental Profile Init

Status: ready-for-dev

## Story

As a **developer**,
I want MetricPoint to carry typed measurement data, WelfordAccumulator to be generic over measurement type, and PerceptualProfile to initialize incrementally via a closure-based builder,
So that domain typing is preserved through the statistical pipeline, the accumulator is reusable for future measurement types (including 2D), and profile initialization doesn't require loading all records into memory at once.

## Acceptance Criteria

1. **Given** MetricPoint currently stores a bare `Double` value, **when** the refactoring is complete, **then** MetricPoint carries a typed measurement (e.g., `Cents` for pitch comparisons) rather than an erased `Double`, and the type information is preserved through the statistical pipeline.

2. **Given** WelfordAccumulator currently operates on `Double` with `Cents`-specific accessors (`centsMean`, `centsStdDev`) baked in, **when** the refactoring is complete, **then** WelfordAccumulator is generic over measurement type, the statistical algorithm is separated from domain units, and `Cents`-specific accessors are removed from the accumulator itself.

3. **Given** PerceptualProfile currently requires `rebuild(metrics: [TrainingMode: [MetricPoint]])` which loads all records into a dictionary, **when** the refactoring is complete, **then** `rebuild` is removed; PerceptualProfile offers a closure-based initializer where the closure receives an accumulator proxy with a single `addPoint` method, and derived computations (EWMA, trend) run once after the closure completes.

4. **Given** PeachApp.loadPerceptualProfile currently fetches all records, maps them, and passes the full dictionary to `rebuild`, **when** the refactoring is complete, **then** PeachApp uses the closure-based initializer, streaming records through MetricPointMapper into the proxy without materializing the full dataset.

5. **Given** the closure-based initializer receives a proxy parameter, **when** the closure executes, **then** the proxy is a separate type with only an `addPoint` method — not the profile itself — because the profile is not yet fully initialized during the closure.

6. **Given** all existing tests, **when** they are run after the refactoring, **then** all tests pass — no behavioral changes to user-visible functionality.

## Tasks / Subtasks

- [ ] Task 1: Create `WelfordMeasurement` protocol and make `WelfordAccumulator` generic (AC: #2)
  - [ ] Create `WelfordMeasurement` protocol in `Core/Profile/WelfordAccumulator.swift` with `var statisticalValue: Double { get }` and `init(statisticalValue: Double)`, conforming to `Sendable`
  - [ ] Add `WelfordMeasurement` conformance for `Cents` via extension in `Core/Profile/WelfordAccumulator.swift` — map `rawValue` ↔ `statisticalValue`
  - [ ] Make `WelfordAccumulator` generic: `struct WelfordAccumulator<Measurement: WelfordMeasurement>`
  - [ ] `update(_ value: Measurement)` — extracts `.statisticalValue` for internal math
  - [ ] Replace `centsMean` / `centsStdDev` with `var typedMean: Measurement?` and `var typedStdDev: Measurement?` that wrap via `Measurement(statisticalValue:)`
  - [ ] Keep raw accessors: `mean: Double` (read-only), `count: Int`, `populationStdDev: Double?`
  - [ ] Update `WelfordAccumulatorTests` for generic API — test with `Cents` measurement type
  - [ ] Run `bin/test.sh` to confirm

- [ ] Task 2: Make `MetricPoint` generic (AC: #1)
  - [ ] Change to `struct MetricPoint<Measurement: WelfordMeasurement>` with `let value: Measurement`
  - [ ] Add `var statisticalValue: Double { value.statisticalValue }` convenience
  - [ ] Update all call sites that construct `MetricPoint` to use `Cents` type parameter
  - [ ] Run `bin/test.sh` to confirm

- [ ] Task 3: Update `TrainingModeStatistics` for concrete generic types (AC: #1, #2)
  - [ ] Change field types to `WelfordAccumulator<Cents>` and `[MetricPoint<Cents>]`
  - [ ] Update `addPoint` signature to accept `MetricPoint<Cents>`
  - [ ] Update `rebuild(from:config:)` to accept `[MetricPoint<Cents>]`
  - [ ] EWMA computation: use `metric.statisticalValue` instead of `metric.value`
  - [ ] Trend computation: use `latest.statisticalValue` instead of `latest.value`
  - [ ] Update `TrainingModeStatisticsTests` (`ModeStatisticsTests.swift`)
  - [ ] Run `bin/test.sh` to confirm

- [ ] Task 4: Create closure-based `PerceptualProfile` initializer with `Builder` proxy (AC: #3, #5)
  - [ ] Create nested `struct Builder` inside `PerceptualProfile` with:
    - `func addPoint(_ point: MetricPoint<Cents>, for mode: TrainingMode)` — appends to internal `[TrainingMode: [MetricPoint<Cents>]]` and updates `WelfordAccumulator<Cents>` per mode (no EWMA/trend)
  - [ ] Add `init(build: (Builder) -> Void)` — creates Builder, calls closure, then finalizes: sorts metrics by timestamp per mode, computes EWMA + trend once per mode
  - [ ] Add `func replaceAll(from builder: Builder)` for in-place profile refresh (used by `onDataChanged` after import — must keep same `@Observable` instance)
  - [ ] Remove `rebuild(metrics:)` method
  - [ ] Keep `init()` for empty cold-start (observer-incremental usage, test setup)
  - [ ] Run `bin/test.sh` to confirm

- [ ] Task 5: Update `MetricPointMapper` and `PeachApp` for streaming init (AC: #4)
  - [ ] Add streaming methods to `MetricPointMapper`:
    - `static func feedPitchComparisons(_ records: [PitchComparisonRecord], into builder: PerceptualProfile.Builder)`
    - `static func feedPitchMatchings(_ records: [PitchMatchingRecord], into builder: PerceptualProfile.Builder)`
  - [ ] Update `PeachApp.loadPerceptualProfile` to use `PerceptualProfile(build:)`
  - [ ] Update `onDataChanged` closure in `TrainingDataTransferService` init to use `PerceptualProfile.Builder` + `profile.replaceAll(from:)`
  - [ ] Remove `extractMetrics` if fully replaced, or keep if any caller still needs it
  - [ ] Run `bin/test.sh` to confirm

- [ ] Task 6: Migrate all remaining callers and final verification (AC: #6)
  - [ ] Update `ProfileScreen.swift` preview to use `PerceptualProfile(build:)`
  - [ ] Update all test files that call `profile.rebuild(metrics:)` — replace with `PerceptualProfile(build:)`:
    - `PerceptualProfileTests.swift`
    - `ProgressTimelineTests.swift`
    - `ExportChartViewTests.swift`
    - `ProfileScreenLayoutTests.swift`
    - `ProgressChartViewTests.swift`
    - `PitchComparisonSessionResetTests.swift`
    - `PitchComparisonSessionIntegrationTests.swift`
    - `TrainingDataImportActionTests.swift`
    - `SettingsTests.swift`
  - [ ] Run `bin/build.sh` — zero errors, zero warnings
  - [ ] Run `bin/test.sh` — all tests pass

## Dev Notes

### Current state (after story 44.3)

- `MetricPoint` — `struct { timestamp: Date, value: Double }` at `Core/Profile/MetricPoint.swift`
- `WelfordAccumulator` — non-generic, `Double`-only, has `centsMean`/`centsStdDev` baked in at `Core/Profile/WelfordAccumulator.swift`
- `TrainingModeStatistics` — uses `WelfordAccumulator` + `[MetricPoint]` at `Core/Profile/TrainingModeStatistics.swift`
- `PerceptualProfile` — `rebuild(metrics: [TrainingMode: [MetricPoint]])` at `Core/Profile/PerceptualProfile.swift`
- `MetricPointMapper.extractMetrics` — returns `[TrainingMode: [MetricPoint]]` at `App/MetricPointMapper.swift`
- `PeachApp.loadPerceptualProfile` — fetches all records → `MetricPointMapper.extractMetrics` → `profile.rebuild(metrics:)`

### Design decisions

**WelfordMeasurement protocol** — bridges domain types to `Double` for internal math:
```swift
protocol WelfordMeasurement: Sendable {
    var statisticalValue: Double { get }
    init(statisticalValue: Double)
}
```
`Cents` conforms by mapping `rawValue` ↔ `statisticalValue`. Future `RhythmOffset` (Epic 45+) will also conform.

**TrainingModeStatistics stays non-generic** — all 4 current modes measure in `Cents`. Making it generic would force type erasure in `PerceptualProfile.modes` dictionary (all values must be same type). Instead, use concrete `WelfordAccumulator<Cents>` and `[MetricPoint<Cents>]`. When rhythm modes arrive, they will use their own statistics type with `WelfordAccumulator<RhythmOffset>`.

**Builder proxy** — accumulates raw data during the closure: Welford updates + metric point storage per mode. EWMA and trend are NOT computed during accumulation — they run once after the closure returns. This is both more efficient (no redundant recomputation per point) and semantically correct (profile is not yet fully initialized during the closure).

**`replaceAll(from:)` for import** — `onDataChanged` in `TrainingDataTransferService` must update the same `@Observable` instance so SwiftUI views react. It cannot replace the profile reference. The pattern:
```swift
let builder = PerceptualProfile.Builder()
MetricPointMapper.feedPitchComparisons(comparisons, into: builder)
MetricPointMapper.feedPitchMatchings(matchings, into: builder)
profile.replaceAll(from: builder)
```
`replaceAll` finalizes the builder (sort, EWMA, trend) then replaces internal `modes` dictionary.

### WelfordAccumulator raw accessor preservation

After generics, `PerceptualProfile.comparisonMean(for:)` still accesses `stats.welford.mean` (raw `Double`) — this accessor is preserved. The new `typedMean`/`typedStdDev` return `Measurement?` for callers that want typed results. The `matchingStdDev` aggregate computation currently uses `stats.welford.centsStdDev` — change to `stats.welford.typedStdDev` (returns `Cents?` since the accumulator is `WelfordAccumulator<Cents>`).

### WelfordMeasurement conformance file placement

The `Cents` conformance extension goes in `Core/Profile/WelfordAccumulator.swift`, not `Core/Music/Cents.swift`. Dependency direction: Profile knows Music types, Music does not know Profile. Importing `Cents` in the Profile layer is fine (Music → Profile direction); adding Profile protocol conformance inside Music would invert the dependency.

### Callers of `rebuild(metrics:)` — complete list

**Production (3 call sites):**
- `PeachApp.swift:163` — `loadPerceptualProfile` → `PerceptualProfile(build:)`
- `PeachApp.swift:65` — `onDataChanged` closure → `profile.replaceAll(from:)`
- `ProfileScreen.swift:125` — preview helper → `PerceptualProfile(build:)`

**Tests (11 call sites):**
- `PerceptualProfileTests.swift:187`
- `ProgressTimelineTests.swift:22, 439`
- `ExportChartViewTests.swift:15`
- `ProfileScreenLayoutTests.swift:19`
- `ProgressChartViewTests.swift:589`
- `PitchComparisonSessionResetTests.swift:109`
- `PitchComparisonSessionIntegrationTests.swift:195`
- `TrainingDataImportActionTests.swift:35, 139`
- `SettingsTests.swift:372`

### Migration order matters

Tasks must be done in order (1 → 2 → 3 → 4 → 5 → 6). Each task builds on the previous. After tasks 1–3, the generic types are in place. Task 4 adds the builder pattern. Task 5 updates the composition root. Task 6 migrates remaining callers.

### Previous story intelligence (44.3)

Story 44.3 re-architected PerceptualProfile as the single source of truth for per-mode statistics. Key learnings:
- `TrainingModeStatistics` (renamed from `ModeStatistics`) is the per-mode statistical engine — it already has `addPoint` and `rebuild` methods
- `MetricPointMapper` was created in the app layer to decouple storage records from domain types
- The `modes` dictionary pattern `[TrainingMode: TrainingModeStatistics]` was established — this story preserves it
- `ProgressTimeline` is now a pure presentation layer reading from the profile — no changes expected in this story
- The code review removed dead methods (`updateComparison`, `updateMatching`, `resetComparison`, `resetMatching`, `comparisonStdDev`) and renamed `ModeStatistics` → `TrainingModeStatistics`

### Anti-patterns to avoid

- **Do NOT make `TrainingModeStatistics` generic** — stays concrete with `Cents`
- **Do NOT add rhythm types** — Epic 45+ work
- **Do NOT change EWMA, trend, or bucketing algorithms** — behavioral parity required
- **Do NOT make `PerceptualProfile` generic** — concrete class, concrete mode storage
- **Do NOT remove `init()` (empty cold start)** — needed for observer-incremental usage and tests
- **Do NOT compute EWMA/trend inside Builder** — computed once after closure returns
- **Do NOT replace the profile instance in `onDataChanged`** — must keep same `@Observable` reference for SwiftUI reactivity; use `replaceAll(from:)` instead

### Project Structure Notes

All files stay in current locations — no new files, no new directories:
- `Core/Profile/WelfordAccumulator.swift` — add protocol, make generic, add `Cents` conformance
- `Core/Profile/MetricPoint.swift` — make generic
- `Core/Profile/TrainingModeStatistics.swift` — concrete `Cents`-typed fields
- `Core/Profile/PerceptualProfile.swift` — add `Builder`, `init(build:)`, `replaceAll(from:)`, remove `rebuild(metrics:)`
- `App/MetricPointMapper.swift` — add streaming feed methods
- `App/PeachApp.swift` — use builder-based init

### References

- [Source: docs/planning-artifacts/epics.md — Epic 44, Story 44.4]
- [Source: docs/planning-artifacts/architecture.md — v0.4 Amendment, "Prerequisite Refactorings"]
- [Source: docs/project-context.md — Domain types everywhere, File Placement, Dependency Direction Rules]
- [Source: Peach/Core/Profile/WelfordAccumulator.swift — current non-generic implementation]
- [Source: Peach/Core/Profile/MetricPoint.swift — current Double-based implementation]
- [Source: Peach/Core/Profile/TrainingModeStatistics.swift — current per-mode statistics]
- [Source: Peach/Core/Profile/PerceptualProfile.swift — current rebuild(metrics:) approach]
- [Source: Peach/App/MetricPointMapper.swift — current dictionary-based extraction]
- [Source: Peach/App/PeachApp.swift — current loadPerceptualProfile and onDataChanged flows]
- [Source: docs/implementation-artifacts/44-3-re-architect-profile-and-progress-responsibilities.md — previous story]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
