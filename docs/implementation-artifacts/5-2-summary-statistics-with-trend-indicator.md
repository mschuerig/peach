# Story 5.2: Summary Statistics with Trend Indicator

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to see my mean detection threshold, standard deviation, and whether I'm improving,
so that I have factual confirmation that training is working.

## Acceptance Criteria

1. **Given** the Profile Screen with training data **When** summary statistics are displayed **Then** they show the arithmetic mean of detectable cent differences over the current training range **And** the standard deviation of detectable cent differences **And** a trend indicator (improving/stable/declining) presented as an understated directional signal

2. **Given** the Profile Screen with no training data (cold start) **When** summary statistics are displayed **Then** dashes or "—" appear instead of numbers **And** the trend indicator is hidden

3. **Given** the PerceptualProfile **When** summary statistics are computed **Then** they are derived from stored per-answer data (FR26)

## Tasks / Subtasks

- [x] Task 1: Create `SummaryStatisticsView` component (AC: 1, 2)
  - [x] 1.1 Create `Peach/Profile/SummaryStatisticsView.swift` — displays mean, stdDev, and trend
  - [x] 1.2 Compute mean from `PerceptualProfile` using `abs(stats.mean)` per trained note (avoids signed cancellation) — same logic as accessibility summary in `ProfileScreen.swift:88`
  - [x] 1.3 Compute stdDev from `abs(mean)` per trained note (spread of detection thresholds)
  - [x] 1.4 Display values as formatted cent values (e.g., "32 cents", "±14 cents")
  - [x] 1.5 Cold start: show "—" for mean and stdDev when `profile.overallMean == nil`

- [x] Task 2: Implement trend computation (AC: 1, 3)
  - [x] 2.1 Create `Peach/Core/Profile/TrendAnalyzer.swift` — `@Observable @MainActor` class
  - [x] 2.2 Define `Trend` enum: `.improving`, `.stable`, `.declining`
  - [x] 2.3 Compute trend from `[ComparisonRecord]` by comparing mean `abs(note2CentOffset)` of the recent half of records vs. the earlier half (chronological split)
  - [x] 2.4 Define threshold for classification: >5% decrease → improving, >5% increase → declining, else stable
  - [x] 2.5 Require minimum record count (e.g., ≥20 records) before showing any trend; return nil otherwise
  - [x] 2.6 Conform to `ComparisonObserver` for incremental updates during training
  - [x] 2.7 Store all absolute offsets and recompute trend on each update (simple full-recompute approach)

- [x] Task 3: Display trend indicator (AC: 1, 2)
  - [x] 3.1 Show trend as an understated SF Symbol arrow: `arrow.down.right` (improving — threshold going down), `arrow.right` (stable), `arrow.up.right` (declining — threshold going up)
  - [x] 3.2 Use system semantic colors: `.secondary` for all trend states (understated per UX spec, NOT green/red)
  - [x] 3.3 Hide trend indicator when no data or insufficient data (cold start, < 20 records)

- [x] Task 4: Integrate into ProfileScreen (AC: 1, 2)
  - [x] 4.1 Add `SummaryStatisticsView` below the visualization (between chart and keyboard, or below keyboard)
  - [x] 4.2 Inject `TrendAnalyzer` via SwiftUI environment
  - [x] 4.3 Ensure statistics are visible in both trained and cold start states
  - [x] 4.4 Update previews to include statistics with various data states

- [x] Task 5: Wire up in PeachApp.swift (AC: 3)
  - [x] 5.1 Create `TrendAnalyzer` in `PeachApp.init()`, compute from existing records
  - [x] 5.2 Add to SwiftUI environment via `.environment(\.trendAnalyzer, trendAnalyzer)`
  - [x] 5.3 Add `TrendAnalyzer` to the `observers` array in TrainingSession init for incremental updates

- [x] Task 6: Accessibility (AC: 1, 2)
  - [x] 6.1 Add VoiceOver labels: "Mean detection threshold: 32 cents" / "Standard deviation: 14 cents" / "Trend: improving"
  - [x] 6.2 Cold start: accessible label "No training data yet"
  - [x] 6.3 Ensure Dynamic Type scaling for all text

- [x] Task 7: Tests (AC: all)
  - [x] 7.1 Test `TrendAnalyzer` trend computation with known record sets (improving, stable, declining)
  - [x] 7.2 Test `TrendAnalyzer` cold start (empty records → nil trend)
  - [x] 7.3 Test `TrendAnalyzer` insufficient data (< 20 records → nil trend)
  - [x] 7.4 Test `TrendAnalyzer` incremental update via `ComparisonObserver`
  - [x] 7.5 Test summary statistics computation (mean abs threshold, stdDev)
  - [x] 7.6 Test cold start display (dashes, hidden trend)
  - [x] 7.7 Test environment key for `TrendAnalyzer`

## Dev Notes

### Architecture & Patterns

- **Summary statistics (mean, stdDev)** are derived directly from `PerceptualProfile` at display time — no separate computation needed. The profile is `@Observable @MainActor`, so SwiftUI views update automatically when the profile changes during training.
- **Trend computation** requires temporal data (timestamps) that `PerceptualProfile`'s Welford algorithm discards. A separate `TrendAnalyzer` class is needed to track chronological performance changes.
- **`TrendAnalyzer` follows the `ComparisonObserver` pattern** already established in the codebase (see `TrainingDataStore`, `PerceptualProfile`, `HapticFeedbackManager`). It receives every completed comparison and updates trend state incrementally.
- **Views are thin**: `SummaryStatisticsView` reads from `PerceptualProfile` (for mean/stdDev) and `TrendAnalyzer` (for trend direction). No business logic in the view.

### Critical: Signed Mean Issue

The `PerceptualProfile.overallMean` uses **signed** cent values (Welford's algorithm tracks directional bias). This means the mean can be near 0 even with large cent differences due to directional cancellation (higher/lower offsets cancel out).

**For display, compute mean using `abs(stats.mean)` per trained note** — the same approach used by the accessibility summary in `ProfileScreen.swift:88`:
```swift
let trainedNotes = midiRange.filter { profile.statsForNote($0).isTrained }
let mean = trainedNotes.map { abs(profile.statsForNote($0).mean) }.reduce(0.0, +) / Double(trainedNotes.count)
```

There is a known hotfix (`hotfix-investigate-signed-mean`, status: `ready-for-dev`) that may change `PerceptualProfile` to use absolute values. Until then, always use `abs()` when displaying thresholds.

### Trend Computation Approach

**Algorithm:**
1. Take all `ComparisonRecord`s sorted by timestamp (already sorted by `fetchAll()`)
2. Split into two halves: earlier and later
3. Compute mean `abs(note2CentOffset)` for each half
4. Compare:
   - Recent mean < baseline mean by >5% → `.improving` (user detects smaller differences now)
   - Recent mean > baseline mean by >5% → `.declining`
   - Otherwise → `.stable`
5. Minimum 20 total records required; return `nil` if fewer

**Why this approach:**
- Uses raw per-comparison data (FR26 requires "derived from stored per-answer data")
- `abs(note2CentOffset)` = the actual difficulty level presented for that comparison
- Simple, understandable, robust. No complex rolling windows or statistical tests needed for MVP
- The 5% threshold prevents noise from triggering false trend signals

**Incremental update strategy:**
- Store running sums and counts for both halves
- When a new comparison arrives, add to "recent" bucket and potentially shift the split point
- Or simpler: store full running stats and recompute split periodically (128 notes × cheap math = trivial)

### Display Design

Per the UX spec, the trend indicator should be an **"understated directional signal"** — not celebratory, not alarming:

- **Layout:** Horizontal row below the visualization chart. Mean on left, StdDev center, trend right. Or a compact `VStack` arrangement.
- **Typography:** `.caption` or `.footnote` for labels, `.title3` or `.headline` for values. System fonts only.
- **Colors:** All `.secondary` color for text and trend arrow. NO green/red coding (that's reserved for the feedback indicator only). The trend arrow is a gentle signal, not a judgment.
- **Trend arrows:** SF Symbols `arrow.down.right` (improving — threshold going down is good), `arrow.right` (stable), `arrow.up.right` (declining — threshold going up). Diagonal arrows are gentler than straight up/down.
- **Cold start:** "—" for values. Trend arrow hidden entirely (not "no data" — just absent).

### Previous Story (5.1) Learnings

- **Y-axis inversion**: improvement = lower cents = closer to keyboard. The summary stats should match this mental model — "lower is better" for the mean.
- **Absolute values**: The accessibility summary already uses `abs(stats.mean)` per note. Reuse this pattern.
- **Environment key pattern**: Follow the `PerceptualProfileKey` pattern in `ProfileScreen.swift:119-135` for the new `TrendAnalyzerKey`.
- **Chart and keyboard are separate views**: `SummaryStatisticsView` should be a separate composable view placed in the `ProfileScreen` layout.
- **ConfidenceBandView uses logarithmic Y-axis**: The chart's visual range may not match the numerical statistics. The numbers in summary stats are linear (actual cents), while the chart is log-scaled. This is fine — they complement each other.

### Git Intelligence

Recent commits show:
- Story 5.1 was implemented and reviewed (c13910f, e033d9f)
- Code review fixes aligned chart to keyboard and fixed accessibility summary (c13910f)
- Hotfixes for algorithm convergence are in flight (Kazez coefficient tuning, chain-based convergence)
- The `hotfix-investigate-signed-mean` is `ready-for-dev` but not yet implemented — work around it with `abs()`

### Project Structure Notes

**New files:**
- `Peach/Profile/SummaryStatisticsView.swift` — new: statistics display component
- `Peach/Core/Profile/TrendAnalyzer.swift` — new: trend computation + observer
- `PeachTests/Profile/TrendAnalyzerTests.swift` — new: tests for trend computation
- `PeachTests/Profile/SummaryStatisticsTests.swift` — new: tests for statistics display

**Modified files:**
- `Peach/Profile/ProfileScreen.swift` — add `SummaryStatisticsView` to layout
- `Peach/App/PeachApp.swift` — create `TrendAnalyzer`, inject into environment + observers
- `Peach/Resources/Localizable.xcstrings` — add string entries for statistics labels

**Existing file locations (do NOT move):**
- `Peach/Core/Profile/PerceptualProfile.swift` — data source for mean/stdDev (read only, do NOT modify)
- `Peach/Core/Data/ComparisonRecord.swift` — record model with `note2CentOffset` and `timestamp`
- `Peach/Core/Data/TrainingDataStore.swift` — provides `fetchAll()` for startup loading
- `Peach/Training/ComparisonObserver.swift` — observer protocol for `TrendAnalyzer` to conform to
- `Peach/Profile/ConfidenceBandView.swift` — existing chart (do NOT modify)
- `Peach/Profile/PianoKeyboardView.swift` — existing keyboard (do NOT modify)

### References

- [Source: docs/planning-artifacts/epics.md#Story 5.2] — acceptance criteria and user story
- [Source: docs/planning-artifacts/prd.md#FR24] — "arithmetic mean and standard deviation of detectable cent differences"
- [Source: docs/planning-artifacts/prd.md#FR25] — "summary statistics as a trend (improving/stable/declining)"
- [Source: docs/planning-artifacts/prd.md#FR26] — "System computes the perceptual profile from stored per-answer data"
- [Source: docs/planning-artifacts/architecture.md#Profile Computation] — "Computed on-the-fly for MVP"
- [Source: docs/planning-artifacts/architecture.md#Data Flow] — "Profile Screen reads PerceptualProfile for visualization and summary statistics"
- [Source: docs/planning-artifacts/architecture.md#Service Boundaries] — "PerceptualProfile: pure computation"
- [Source: docs/planning-artifacts/ux-design-specification.md#Emotional Design Principles] — "quiet confidence", "understated directional signal"
- [Source: docs/planning-artifacts/ux-design-specification.md#Empty States] — "dashes or '—' instead of numbers, trend hidden"
- [Source: docs/planning-artifacts/ux-design-specification.md#Custom Components > Perceptual Profile Visualization] — display context for statistics
- [Source: Peach/Profile/ProfileScreen.swift:88] — abs() per-note mean pattern for display
- [Source: Peach/Core/Profile/PerceptualProfile.swift:96-118] — overallMean/overallStdDev implementation
- [Source: Peach/Core/Data/ComparisonRecord.swift] — record model with timestamp for trend computation
- [Source: Peach/Training/ComparisonObserver.swift] — observer protocol for TrendAnalyzer
- [Source: Peach/App/PeachApp.swift:27-34] — startup record loading pattern to follow
- [Source: docs/implementation-artifacts/5-1-profile-screen-with-perceptual-profile-visualization.md] — previous story learnings

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None — implementation proceeded without blockers.

### Completion Notes List

- **Task 1:** Created `SummaryStatisticsView` with `computeStats()` using `abs(stats.mean)` per trained note to avoid signed cancellation. Formats mean as "N cents" and stdDev as "±N cents". Cold start shows "—" dashes.
- **Task 2:** Created `TrendAnalyzer` as `@Observable @MainActor` class with `Trend` enum (.improving/.stable/.declining). Splits records chronologically, compares mean abs(centOffset) of halves. >5% change threshold. Minimum 20 records required. Conforms to `ComparisonObserver` for incremental updates.
- **Task 3:** Trend displayed as understated SF Symbol arrows (arrow.down.right/arrow.right/arrow.up.right) in `.secondary` color. Hidden when no data or <20 records.
- **Task 4:** Integrated `SummaryStatisticsView` into `ProfileScreen` below the keyboard in both trained and cold start states. Existing previews automatically include it.
- **Task 5:** Wired `TrendAnalyzer` in `PeachApp.init()` — created from existing records, injected into SwiftUI environment, added to observers array.
- **Task 6:** VoiceOver labels added: "Mean detection threshold: N cents", "Standard deviation: N cents", "Trend: improving/stable/declining". Cold start: "No training data yet". Dynamic Type scaling enabled.
- **Task 7:** 19 tests total — 7 in SummaryStatisticsTests (mean computation, stdDev, formatting, cold start) and 12 in TrendAnalyzerTests (improving/stable/declining/boundary, minimum records, incremental update, environment key).

### File List

**New files:**
- `Peach/Profile/SummaryStatisticsView.swift`
- `Peach/Core/Profile/TrendAnalyzer.swift`
- `PeachTests/Profile/TrendAnalyzerTests.swift`
- `PeachTests/Profile/SummaryStatisticsTests.swift`

**Modified files:**
- `Peach/Profile/ProfileScreen.swift`
- `Peach/App/PeachApp.swift`
- `Peach/Resources/Localizable.xcstrings`
- `docs/implementation-artifacts/sprint-status.yaml`
- `docs/implementation-artifacts/5-2-summary-statistics-with-trend-indicator.md`

## Change Log

- 2026-02-17: Implemented Story 5.2 — Summary Statistics with Trend Indicator. Added `SummaryStatisticsView` displaying mean, stdDev, and trend direction. Created `TrendAnalyzer` with `ComparisonObserver` conformance for incremental updates. 19 new tests covering all acceptance criteria.
- 2026-02-17: Code review fixes — Fixed empty string `""` polluting Localizable.xcstrings (M2). Added TrendAnalyzer with data to previews so trend arrow is visible (M4). Fixed singular "1 cent" vs plural "cents" formatting (M5). Simplified redundant sign computation in TrendAnalyzer.comparisonCompleted (L1). Removed test-only formatMean/formatStdDev overloads (L2). Added trendSymbol SF Symbol mapping test (L3). Updated task 2.7 description to match implementation (M3). Added Localizable.xcstrings to File List (M1). 20 tests total.
