# Story 9.2: Rethink Profile Display and Progress Tracking

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to see my pitch discrimination progress as a threshold convergence chart over time,
So that I can see meaningful evidence that training is working, reflecting that pitch discrimination is one unified skill rather than many per-note skills.

## Acceptance Criteria

1. **Given** the Profile Screen with training data
   **When** it is displayed
   **Then** it shows a time-series chart where:
   - The X-axis represents time (comparison timestamps)
   - The Y-axis represents detection threshold in cents (lower = better)
   - Individual comparisons appear as small dots
   - A rolling mean line shows the overall trend
   - A rolling standard deviation band surrounds the mean line
   **And** the per-note confidence band and piano keyboard are removed from the Profile Screen

2. **Given** the time-series chart with more data than fits on screen
   **When** the user swipes horizontally
   **Then** the chart scrolls to reveal earlier or later data
   **And** the chart defaults to showing the most recent data (right edge)

3. **Given** the time-series chart
   **When** the user pinches to zoom
   **Then** the time axis scales (expanding or compressing the visible time range)
   **And** the chart remains scrollable after zooming

4. **Given** the time-series chart with data points
   **When** the user taps on or near a data point
   **Then** a popup appears showing:
   - Date and time of the comparison
   - The cent difference
   - The note name (derived from MIDI note)
   - Whether the answer was correct or incorrect
   **And** the popup dismisses when the user taps elsewhere

5. **Given** the Profile Screen with no training data (cold start)
   **When** it is displayed
   **Then** the chart area shows an empty state
   **And** the text "Start training to build your profile" appears

6. **Given** the Start Screen
   **When** the Profile Preview is displayed with training data
   **Then** it shows a simplified sparkline of the rolling mean (no dots, no labels, no axes)
   **And** the piano keyboard is removed from the preview
   **And** it remains tappable to navigate to the full Profile Screen

7. **Given** SummaryStatisticsView on the Profile Screen
   **When** displayed with training data
   **Then** it continues to show overall mean, standard deviation, and trend indicator
   **And** its behavior is unchanged from the current implementation

8. **Given** the full test suite
   **When** all tests are run
   **Then** all tests pass
   **And** new tests verify timeline data preparation, rolling statistics computation, and interaction behavior
   **And** removed visualization tests (confidence band, piano keyboard) are cleaned up

## Tasks / Subtasks

- [ ] Task 1: Create ThresholdTimeline service (AC: #1, #7)
  - [ ] 1.1 Create `ThresholdTimeline` as `@Observable @MainActor final class` in `Core/Profile/`
  - [ ] 1.2 Define `TimelineDataPoint` struct: `timestamp: Date`, `centDifference: Double`, `isCorrect: Bool`, `note1: Int`
  - [ ] 1.3 Conform to `ComparisonObserver` — append new points on each completed comparison
  - [ ] 1.4 Implement `load(from records: [ComparisonRecord])` for startup loading (same pattern as `PerceptualProfile`)
  - [ ] 1.5 Implement `rollingMean(windowSize:)` and `rollingStdDev(windowSize:)` — return `[(Date, Double)]` arrays for chart consumption
  - [ ] 1.6 Use expanding window for early data (< windowSize points); default window size = 20
  - [ ] 1.7 Add `EnvironmentKey` and `EnvironmentValues` extension; wire in `PeachApp.swift` as observer + environment value
  - [ ] 1.8 Write unit tests: rolling mean/stddev computation, expanding window behavior, empty state, single point, incremental update

- [ ] Task 2: Create ThresholdTimelineView chart (AC: #1, #5)
  - [ ] 2.1 Create `ThresholdTimelineView` in `Profile/`
  - [ ] 2.2 Render SwiftUI `Chart` with three layers:
    - `AreaMark` for stddev band (rolling mean +/- rolling stddev, system tint at 0.2 opacity)
    - `LineMark` for rolling mean (system tint, 2pt line weight)
    - `PointMark` for individual comparisons (small dots, `.secondary` color, 3pt)
  - [ ] 2.3 X-axis: `.value("Time", point.timestamp)` — date axis with automatic formatting
  - [ ] 2.4 Y-axis: cents, normal orientation (lower = better, trend going down = improvement)
  - [ ] 2.5 Cold start state: show centered "Start training to build your profile" text when no data

- [ ] Task 3: Add scroll and zoom (AC: #2, #3)
  - [ ] 3.1 Add `.chartScrollableAxes(.horizontal)` to the Chart
  - [ ] 3.2 Add `.chartXVisibleDomain(length:)` to control initial visible range
  - [ ] 3.3 Use `@State` to track zoom scale, apply `MagnifyGesture` to adjust the visible domain length
  - [ ] 3.4 Default scroll position: anchor to trailing edge (most recent data)
  - [ ] 3.5 Clamp zoom: minimum = show all data, maximum = ~20 comparisons visible

- [ ] Task 4: Add tap-for-details popup (AC: #4)
  - [ ] 4.1 Add `.chartOverlay` with `SpatialTapGesture`
  - [ ] 4.2 On tap, use `ChartProxy.value(atX:)` to find the nearest `TimelineDataPoint`
  - [ ] 4.3 Show a popover/overlay anchored near the tapped point with: formatted date/time, note name (use `FrequencyCalculation` MIDI-to-name), cent difference, correct/incorrect indicator
  - [ ] 4.4 Dismiss on tap outside the popup
  - [ ] 4.5 Style the popup with stock SwiftUI (`.background(.regularMaterial)`, rounded corners)

- [ ] Task 5: Update ProfileScreen (AC: #1, #5, #7)
  - [ ] 5.1 Remove `ConfidenceBandView` and `PianoKeyboardView` from the layout
  - [ ] 5.2 Add `ThresholdTimelineView` reading from `@Environment(\.thresholdTimeline)`
  - [ ] 5.3 Keep `SummaryStatisticsView` below the chart (unchanged)
  - [ ] 5.4 Update cold start state to show `ThresholdTimelineView`'s empty state
  - [ ] 5.5 Update accessibility summary: "Threshold timeline showing [N] comparisons over [date range]. Current average: [X] cents."

- [ ] Task 6: Update ProfilePreviewView (AC: #6)
  - [ ] 6.1 Replace confidence band + keyboard with a compact `Chart` showing only the rolling mean `LineMark`
  - [ ] 6.2 No axes, no labels, no grid — just the sparkline shape
  - [ ] 6.3 Height ~45pt (same as current preview)
  - [ ] 6.4 Cold start: render empty/flat — intentionally minimal
  - [ ] 6.5 Keep `NavigationLink` to `ProfileScreen`
  - [ ] 6.6 Update accessibility label: "Your training progress. Tap to view details." (with threshold if data exists)

- [ ] Task 7: Remove unused visualization code (AC: #1, #6)
  - [ ] 7.1 Delete `Peach/Profile/ConfidenceBandView.swift`
  - [ ] 7.2 Delete `Peach/Profile/PianoKeyboardView.swift`
  - [ ] 7.3 Delete `PeachTests/Profile/ConfidenceBandDataTests.swift` (if exists)
  - [ ] 7.4 Delete `PeachTests/Profile/PianoKeyboardLayoutTests.swift` (if exists)
  - [ ] 7.5 Verify no remaining references to deleted types

- [ ] Task 8: Update localization (AC: #1, #4, #5, #6)
  - [ ] 8.1 Add localized strings for: detail popup labels, updated accessibility summaries, empty state text (if changed)
  - [ ] 8.2 Remove localized strings that referenced the confidence band or piano keyboard (if any)
  - [ ] 8.3 Provide German translations for all new strings

- [ ] Task 9: Run full test suite and verify (AC: #8)
  - [ ] 9.1 Run `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] 9.2 Confirm zero failures
  - [ ] 9.3 Confirm no stale references to removed files

## Dev Notes

### Background and Rationale

Story 9.1 established that pitch discrimination is one unified skill with a roughly uniform threshold across the frequency range (Hawkey et al. 2004, Irvine et al. 2000). KazezNoteStrategy is now the default, using a single continuous difficulty chain with random note selection.

The current Profile Screen shows a **per-note confidence band over a piano keyboard** — this visualization implies that per-note differences are meaningful, when in reality they are mostly data collection artifacts. A **threshold convergence chart over time** is:
- More honest: shows the one thing that actually changes (overall threshold)
- More motivating: the user sees a line trending downward over days/weeks
- More scientifically sound: aligned with perceptual learning literature

See `docs/brainstorming/brainstorming-session-2026-02-24.md` for the full research basis.

### Technical Requirements

**ThresholdTimeline service pattern:**
- Follows the exact same pattern as `PerceptualProfile` and `TrendAnalyzer`: `@Observable @MainActor final class`, conforms to `ComparisonObserver`, loaded from `ComparisonRecord` array at startup, updated incrementally
- Stores `[TimelineDataPoint]` sorted chronologically — each point holds timestamp, `abs(note2CentOffset)`, isCorrect, note1 MIDI number
- Rolling statistics use a sliding window (default 20 comparisons). For < 20 points, use expanding window (all available data)
- Rolling mean: arithmetic mean of centDifference over window
- Rolling stdDev: sample standard deviation over window (returns 0 for window size 1)

**Chart rendering with Swift Charts:**
- Three chart layers rendered in order (back to front): AreaMark (stddev band) → LineMark (rolling mean) → PointMark (individual dots)
- Use `.chartScrollableAxes(.horizontal)` for native horizontal scrolling
- Use `.chartXVisibleDomain(length:)` to set initial visible range — suggest last ~100 comparisons or last 7 days, whichever is smaller
- `MagnifyGesture` modifies the visible domain length via `@State` scale factor
- `.chartOverlay` with `SpatialTapGesture` for point selection; use `proxy.value(atX:as:)` to map tap location to `Date`, then find nearest point

**Detail popup:**
- Anchored near the tapped point, not centered on screen
- Shows: formatted timestamp (`DateFormatter` with date+time), note name from MIDI (use existing note name logic or `FrequencyCalculation`), cent difference formatted as `"X.X cents"`, correct/incorrect with SF Symbol (checkmark/xmark)
- Styled with `.background(.regularMaterial)` and rounded corners — stock SwiftUI
- Dismissed by tapping outside or tapping the chart again

**What stays unchanged:**
- `PerceptualProfile` — still collects per-note data, still provides `overallMean` for KazezNoteStrategy cold start
- `TrendAnalyzer` — still provides the trend arrow for `SummaryStatisticsView`
- `SummaryStatisticsView` — same three stats (mean, stddev, trend), same computation from `PerceptualProfile`
- `TrainingSession` — no changes needed
- `ComparisonRecord` — no schema changes; timestamp field already provides the X-axis data

### Architecture Compliance

- **New service follows observer pattern**: `ThresholdTimeline` conforms to `ComparisonObserver`, same as `PerceptualProfile` and `TrendAnalyzer`. Added to observer array in `PeachApp.swift`. [Source: docs/project-context.md — "Observer pattern"]
- **Composition root**: `ThresholdTimeline` instantiated in `PeachApp.swift`, injected via `@Environment` with custom `EnvironmentKey`. [Source: docs/project-context.md — "Composition Root"]
- **Views only interact with services via environment**: `ProfileScreen` reads `ThresholdTimeline` from environment, never accesses `TrainingDataStore` directly. [Source: docs/project-context.md — "Views are thin"]
- **Protocol boundary preserved**: `ThresholdTimeline` receives data through `ComparisonObserver` protocol, doesn't directly query `TrainingDataStore`. [Source: docs/project-context.md — "TrainingDataStore is the sole data accessor"]
- **@Observable, not ObservableObject**: `ThresholdTimeline` uses `@Observable` macro. [Source: docs/project-context.md — "Never Do This"]

### Library & Framework Requirements

- **Swift Charts** (first-party, already in use) — `PointMark`, `LineMark`, `AreaMark`, `.chartScrollableAxes`, `.chartXVisibleDomain`, `.chartOverlay`
- **SwiftUI `MagnifyGesture`** (first-party) — for pinch-to-zoom
- **No new dependencies** — all capabilities are first-party iOS 26 frameworks

### File Structure Requirements

**New files:**
```
Peach/Core/Profile/ThresholdTimeline.swift              # Service: timeline data + rolling stats
Peach/Profile/ThresholdTimelineView.swift                # View: time-series chart with scroll/zoom/tap
PeachTests/Core/Profile/ThresholdTimelineTests.swift     # Tests: rolling stats, loading, incremental update
```

**Modified files:**
```
Peach/Profile/ProfileScreen.swift                        # Replace visualization, update layout + accessibility
Peach/Start/ProfilePreviewView.swift                     # Replace with sparkline
Peach/App/PeachApp.swift                                 # Wire ThresholdTimeline as observer + environment
Peach/Resources/Localizable.xcstrings                    # New strings, remove unused
```

**Deleted files:**
```
Peach/Profile/ConfidenceBandView.swift                   # Replaced by ThresholdTimelineView
Peach/Profile/PianoKeyboardView.swift                    # No longer used
PeachTests/Profile/ConfidenceBandDataTests.swift         # Tests for removed component (if exists)
PeachTests/Profile/PianoKeyboardLayoutTests.swift        # Tests for removed component (if exists)
```

### Testing Requirements

- **New tests** (`ThresholdTimelineTests.swift`):
  - Rolling mean with exact window: verify correct arithmetic mean over sliding window
  - Rolling stddev with exact window: verify sample standard deviation
  - Expanding window for < windowSize points: verify all available points used
  - Empty state: verify nil/empty returns
  - Single point: verify mean = that point, stddev = 0
  - Incremental update via `ComparisonObserver`: verify new point appended and rolling stats updated
  - Load from `ComparisonRecord` array: verify chronological ordering preserved, centDifference = abs(offset)
- **Removed tests**: Delete test files for `ConfidenceBandData` and `PianoKeyboardLayout`
- **Updated tests**: `ProfileScreen` layout tests (if any) — update for new chart component
- **Unchanged tests**: `PerceptualProfileTests`, `TrendAnalyzerTests`, `SummaryStatisticsViewTests`, `TrainingSessionTests`, all algorithm tests
- **All tests `@MainActor async`** per project testing rules
- **Struct-based test suites** with factory methods, no `setUp/tearDown`

### Previous Story Intelligence

**From story 9.1 (most recent, same epic):**
- `PeachApp.swift` wires services in `init()` — this is where `ThresholdTimeline` gets added to the observer array and injected into the environment
- `ComparisonObserver` protocol pattern is established — `PerceptualProfile` and `TrendAnalyzer` both conform; `ThresholdTimeline` follows the same pattern
- `PerceptualProfile.overallMean` is used by `KazezNoteStrategy` for cold start — must not be disrupted
- `TrendAnalyzer` provides `Trend` enum to `SummaryStatisticsView` — stays as-is
- The brainstorming session (`docs/brainstorming/brainstorming-session-2026-02-24.md`) provides the research rationale for this entire epic

**From story 5.1 (original profile visualization):**
- `ProfileScreen` currently uses `ConfidenceBandView` + `PianoKeyboardView` — both being replaced
- `ConfidenceBandData.prepare(from:midiRange:)` computes per-note data points — no longer needed
- `SummaryStatisticsView.computeStats(from:midiRange:)` computes mean/stddev from per-note profile — this stays
- Layout methods `confidenceBandMinHeight()` and `keyboardHeight()` — replaced by timeline chart sizing
- `PerceptualProfileKey` environment key defined in `ProfileScreen.swift` — stays (still used for SummaryStatisticsView)

**From story 5.3 (profile preview):**
- `ProfilePreviewView` reuses the same data pipeline as `ProfileScreen` — will now reuse `ThresholdTimeline` instead
- Preview height ~45pt with keyboard ~25pt — new sparkline can use full ~70pt or stay at 45pt
- `NavigationLink` wrapper — stays unchanged
- Accessibility: "Your pitch profile. Tap to view details." — update wording to "Your training progress."

### Git Intelligence

Recent commits show clean patterns:
- Story 9.1 (`0c06be0`, `855f825`): Modified `PeachApp.swift` for strategy swap, clean one-line changes in composition root
- Story 8.3 (`4391637`): Removed `SineWaveNotePlayer` and `RoutingNotePlayer` — established pattern for cleanly removing unused components and their tests
- All commits follow: implement → code review findings → next story
- Test suite consistently passes before each commit

### Project Structure Notes

- `ThresholdTimeline.swift` goes in `Core/Profile/` alongside `PerceptualProfile.swift` and `TrendAnalyzer.swift` — same domain
- `ThresholdTimelineView.swift` goes in `Profile/` alongside `ProfileScreen.swift` and `SummaryStatisticsView.swift` — same feature
- Tests mirror source: `PeachTests/Core/Profile/ThresholdTimelineTests.swift`
- Deletion of `ConfidenceBandView.swift` and `PianoKeyboardView.swift` follows the precedent set in story 8.3 (removing unused components cleanly)

### References

- [Source: docs/brainstorming/brainstorming-session-2026-02-24.md] — Research rationale for unified-skill model
- [Source: docs/project-context.md] — Architecture rules, testing conventions, observer pattern, composition root
- [Source: docs/implementation-artifacts/9-1-promote-kazeznotestrategy-to-default.md] — Previous story learnings, PeachApp wiring
- [Source: Peach/Profile/ProfileScreen.swift] — Current profile layout to replace
- [Source: Peach/Profile/ConfidenceBandView.swift] — Component being removed
- [Source: Peach/Profile/PianoKeyboardView.swift] — Component being removed
- [Source: Peach/Start/ProfilePreviewView.swift] — Preview to update
- [Source: Peach/Core/Profile/PerceptualProfile.swift] — Stays unchanged, still provides overallMean
- [Source: Peach/Core/Profile/TrendAnalyzer.swift] — Stays unchanged, still provides trend arrow
- [Source: Peach/Profile/SummaryStatisticsView.swift] — Stays unchanged
- [Source: Peach/App/PeachApp.swift] — Composition root where ThresholdTimeline gets wired
- [Source: Peach/Core/Data/ComparisonRecord.swift] — Data source: timestamp + note2CentOffset + isCorrect + note1

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
