# Story 38.5: Start Screen Sparkline and Training Screen Summary

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **user**,
I want a quick glance at my progress on the Start Screen and a text summary during training,
So that I feel encouraged without navigating to the full Profile Screen.

## Acceptance Criteria

1. **Given** the Start Screen, **When** the user has training data for one or more modes, **Then** a small sparkline appears for each trained mode (tiny EWMA line, no axes or labels) **And** the sparkline is tinted green if improving, amber if stable, subtle gray if declining **And** the current EWMA value appears beside it as small text (e.g., "8.2c").

2. **Given** the Start Screen, **When** the user has no training data, **Then** no sparklines are shown.

3. **Given** a Training Screen (Comparison or Pitch Matching), **When** the user is in a training session for a mode with sufficient data (20+ records), **Then** a single-line text summary appears: "Current accuracy: X.X cents (improving/stable/declining)".

4. **Given** a Training Screen, **When** the user has fewer than 20 records for that mode, **Then** no accuracy summary is shown.

## Tasks / Subtasks

- [ ] Task 1: Create `ProgressSparklineView` (AC: #1, #2)
  - [ ] 1.1 Create `Peach/Start/ProgressSparklineView.swift` — a thin view parameterized by `TrainingMode`
  - [ ] 1.2 Read `@Environment(\.progressTimeline)` for `state(for:)`, `buckets(for:)`, `currentEWMA(for:)`, `trend(for:)`
  - [ ] 1.3 If `state` is `.noData` or `.coldStart` — render `EmptyView()` (sparkline hidden)
  - [ ] 1.4 If `state` is `.active` — render sparkline: a tiny SwiftUI `Path`/`Shape` connecting EWMA `mean` values from `buckets(for:)` with no axes, no labels, no band
  - [ ] 1.5 Tint sparkline stroke: `.green` if trend is `.improving`, `.orange` if `.stable`, `.secondary` if `.declining` or `nil`
  - [ ] 1.6 Show current EWMA value as small text beside the sparkline: `Text("8.2c")` using `formatEWMA()` + config `unitLabel` abbreviation
  - [ ] 1.7 Extract `sparklineColor(for:)` and `formatCompactEWMA(_:unitLabel:)` as `static` methods for unit testability
  - [ ] 1.8 Add VoiceOver accessibility label combining mode name, current value, and trend (e.g., "Hear & Compare – Single Notes: 8.2 cents, improving")

- [ ] Task 2: Integrate sparklines into `StartScreen` (AC: #1, #2)
  - [ ] 2.1 In `StartScreen.swift`, add `@Environment(\.progressTimeline) private var progressTimeline`
  - [ ] 2.2 Modify `trainingCard(_:systemImage:)` to accept a `TrainingMode` parameter
  - [ ] 2.3 Below the card's `Label`, add a `ProgressSparklineView(mode:)` — it self-hides when no data
  - [ ] 2.4 Verify sparklines render correctly in compact (landscape) and regular (portrait) layouts
  - [ ] 2.5 Ensure cards retain their current styling (`.regularMaterial`, `RoundedRectangle(cornerRadius: 12)`)

- [ ] Task 3: Add accuracy summary to `ComparisonScreen` (AC: #3, #4)
  - [ ] 3.1 In `ComparisonScreen.swift`, add `@Environment(\.progressTimeline) private var progressTimeline`
  - [ ] 3.2 Compute the `TrainingMode` from `intervals`: if `intervals == [.prime]` then `.unisonComparison`, else `.intervalComparison`
  - [ ] 3.3 If `progressTimeline.state(for: mode)` is `.active` and `trend` is not `nil` — show a single-line `Text` summary above or below the difficulty display: "Current accuracy: X.X cents (improving)"
  - [ ] 3.4 If state is `.noData` or `.coldStart` or `trend` is `nil` — show nothing (no summary)
  - [ ] 3.5 Extract `accuracySummaryText(ewma:trend:unitLabel:)` as a `static` method for testability
  - [ ] 3.6 Add VoiceOver accessibility label for the summary text

- [ ] Task 4: Add accuracy summary to `PitchMatchingScreen` (AC: #3, #4)
  - [ ] 4.1 In `PitchMatchingScreen.swift`, add `@Environment(\.progressTimeline) private var progressTimeline`
  - [ ] 4.2 Compute the `TrainingMode` from `intervals`: if `intervals == [.prime]` then `.unisonMatching`, else `.intervalMatching`
  - [ ] 4.3 Use same pattern as Task 3: show single-line `Text` summary when `.active` and trend available
  - [ ] 4.4 Extract same static helper (or duplicate the trivial static method — both screens own their own copy since cross-feature coupling is forbidden)

- [ ] Task 5: Add localization strings (AC: #1, #3)
  - [ ] 5.1 Add English+German localization for accuracy summary string (e.g., "Current accuracy: %@ %@ (%@)") via `bin/add-localization.py`
  - [ ] 5.2 Add English+German localization for sparkline accessibility label via `bin/add-localization.py`

- [ ] Task 6: Write tests (AC: #1, #2, #3, #4)
  - [ ] 6.1 Create `PeachTests/Start/ProgressSparklineViewTests.swift` — test static helpers: `sparklineColor(for:)` returns correct colors, `formatCompactEWMA(_:unitLabel:)` formats correctly
  - [ ] 6.2 Test sparkline accessibility text generation
  - [ ] 6.3 Create `PeachTests/Comparison/ComparisonAccuracySummaryTests.swift` — test `accuracySummaryText(ewma:trend:unitLabel:)` static method
  - [ ] 6.4 Create `PeachTests/PitchMatching/PitchMatchingAccuracySummaryTests.swift` — test same formatting logic
  - [ ] 6.5 Update `PeachTests/Start/StartScreenTests.swift` if needed for new environment dependency

- [ ] Task 7: Verify full test suite passes
  - [ ] 7.1 Run `bin/test.sh` — all tests pass

## Dev Notes

### Architecture & Design Decisions

**Sparkline uses SwiftUI `Path`, not Apple Charts:** The sparkline is a tiny EWMA line with no axes, labels, or band. Using `Charts` would be overkill and would add an `import Charts` to `Start/`. Instead, draw a simple `Path` connecting the `mean` values from `buckets(for:)`. Normalize Y values to the view height, X values to the view width.

**No shared view for accuracy summary:** The accuracy summary is a single `Text` view. Both `ComparisonScreen` and `PitchMatchingScreen` need it, but cross-feature coupling is forbidden. Each screen owns a trivial `static` helper method that formats the string. The duplication is minimal (one function) and avoids architectural violations.

**TrainingMode mapping from intervals parameter:**
```swift
// In ComparisonScreen:
private var trainingMode: TrainingMode {
    intervals == [.prime] ? .unisonComparison : .intervalComparison
}
// In PitchMatchingScreen:
private var trainingMode: TrainingMode {
    intervals == [.prime] ? .unisonMatching : .intervalMatching
}
```

**Sparkline card layout:** Each training card on StartScreen shows the sparkline inline, below the label. The sparkline is small (~40pt height, stretches to card width). When there's no data, `ProgressSparklineView` returns `EmptyView()` and the card renders as before.

### Data Flow

```
ProgressTimeline (via @Environment)
  |
  +-- StartScreen / ProgressSparklineView
  |     reads: state(for:), buckets(for:), currentEWMA(for:), trend(for:)
  |     shows: tiny EWMA line + "8.2c" text, tinted by trend
  |     hidden: .noData or .coldStart
  |
  +-- ComparisonScreen
  |     reads: state(for:), currentEWMA(for:), trend(for:)
  |     shows: "Current accuracy: 8.2 cents (improving)"
  |     hidden: state != .active or trend == nil
  |
  +-- PitchMatchingScreen
        reads: state(for:), currentEWMA(for:), trend(for:)
        shows: "Current accuracy: 8.2 cents (improving)"
        hidden: state != .active or trend == nil
```

### Sparkline Rendering

```swift
struct ProgressSparklineView: View {
    let mode: TrainingMode
    @Environment(\.progressTimeline) private var progressTimeline

    var body: some View {
        let state = progressTimeline.state(for: mode)
        switch state {
        case .noData, .coldStart:
            EmptyView()
        case .active:
            sparklineContent
        }
    }

    private var sparklineContent: some View {
        let buckets = progressTimeline.buckets(for: mode)
        let ewma = progressTimeline.currentEWMA(for: mode)
        let trend = progressTimeline.trend(for: mode)
        let config = mode.config

        return HStack(spacing: 6) {
            SparklinePath(values: buckets.map(\.mean))
                .stroke(Self.sparklineColor(for: trend), lineWidth: 1.5)
                .frame(width: 60, height: 24)
            if let ewma {
                Text(Self.formatCompactEWMA(ewma, unitLabel: config.unitLabel))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

**SparklinePath shape:**
```swift
private struct SparklinePath: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count >= 2 else { return Path() }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 1
        let range = max(maxVal - minVal, 0.1) // Avoid division by zero

        var path = Path()
        for (index, value) in values.enumerated() {
            let x = rect.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = rect.height * (1 - CGFloat((value - minVal) / range))
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
```

### Sparkline Colors

```swift
static func sparklineColor(for trend: Trend?) -> Color {
    switch trend {
    case .improving: .green
    case .stable: .orange
    case .declining: .secondary
    case nil: .secondary
    }
}
```

Note: "amber" in the UX spec maps to `.orange` in SwiftUI (same color used for declining in `ProgressChartView.trendColor()`). For sparklines, the spec says "amber if stable" and "subtle gray if declining" — this differs from the chart's color mapping where stable = `.secondary` (gray) and declining = `.orange`. Follow the sparkline-specific spec exactly.

### Accuracy Summary Text

```swift
// Same static method in both ComparisonScreen and PitchMatchingScreen
static func accuracySummaryText(ewma: Double, trend: Trend, unitLabel: String) -> String {
    let value = String(format: "%.1f", ewma)
    let trendText: String = switch trend {
    case .improving: String(localized: "improving")
    case .stable: String(localized: "stable")
    case .declining: String(localized: "declining")
    }
    return String(localized: "Current accuracy: \(value) \(unitLabel) (\(trendText))")
}
```

### TrainingMode ↔ Start Screen Card Mapping

| Start Screen Section | Card Label | NavigationDestination | TrainingMode |
|---|---|---|---|
| Single Notes | Hear & Compare | `.comparison(intervals: [.prime])` | `.unisonComparison` |
| Single Notes | Tune & Match | `.pitchMatching(intervals: [.prime])` | `.unisonMatching` |
| Intervals | Hear & Compare | `.comparison(intervals: selection)` | `.intervalComparison` |
| Intervals | Tune & Match | `.pitchMatching(intervals: selection)` | `.intervalMatching` |

### Existing Code Patterns to Follow

**Environment access:**
```swift
@Environment(\.progressTimeline) private var progressTimeline
```

**Trend label helpers (already exist in ProgressChartView, duplicate for use in training screens):**
```swift
static func trendLabel(_ trend: Trend) -> String {
    switch trend {
    case .improving: String(localized: "Improving")
    case .stable: String(localized: "Stable")
    case .declining: String(localized: "Declining")
    }
}
```

**Card styling (from StartScreen):**
```swift
.background(RoundedRectangle(cornerRadius: Self.cardCornerRadius).fill(.regularMaterial))
```

**Cold-start check:**
```swift
switch progressTimeline.state(for: mode) {
case .noData, .coldStart: EmptyView()
case .active: // show content
}
```

### What NOT To Do

- Do NOT import `Charts` in `Start/` files — sparklines use SwiftUI `Path`/`Shape`, not Apple Charts.
- Do NOT create a shared view in `Core/` — Core/ cannot import SwiftUI.
- Do NOT create a shared `Utils/` directory for the accuracy summary — duplicate the trivial static method.
- Do NOT add the accuracy summary to the `ProgressTimeline` API — keep views thin but the text formatting is a presentation concern, not a domain concern.
- Do NOT modify `ProgressTimeline.swift` or `TrainingModeConfig.swift` — all needed APIs already exist.
- Do NOT modify `PeachApp.swift` or `EnvironmentKeys.swift` — `progressTimeline` is already wired and available via environment.
- Do NOT create protocols for `ProgressSparklineView` — YAGNI.
- Do NOT use `ObservableObject`/`@Published` or `@EnvironmentObject` — use `@Observable` and `@Environment` with `@Entry`.

### Project Structure Notes

- New file: `Peach/Start/ProgressSparklineView.swift`
- New test file: `PeachTests/Start/ProgressSparklineViewTests.swift`
- New test file: `PeachTests/Comparison/ComparisonAccuracySummaryTests.swift`
- New test file: `PeachTests/PitchMatching/PitchMatchingAccuracySummaryTests.swift`
- Modified: `Peach/Start/StartScreen.swift` (add sparklines to training cards)
- Modified: `Peach/Comparison/ComparisonScreen.swift` (add accuracy summary)
- Modified: `Peach/PitchMatching/PitchMatchingScreen.swift` (add accuracy summary)
- Modified: `Peach/Resources/Localizable.xcstrings` (new strings)
- Modified: `PeachTests/Start/StartScreenTests.swift` (if environment dependency needs updating)

### References

- [Source: docs/implementation-artifacts/38-1-brainstorm-and-design-profile-visualization.md] — Approved UX concept: sparkline spec (tiny EWMA line, trend coloring, value text), training screen summary spec
- [Source: docs/implementation-artifacts/38-3-progresschartview-and-profile-screen-redesign.md] — ProgressChartView static helpers (trendSymbol, trendColor, trendLabel, formatEWMA), chart data flow patterns
- [Source: docs/planning-artifacts/epics.md#Story 38.5] — Story acceptance criteria and technical hints
- [Source: Peach/Start/StartScreen.swift] — Current StartScreen layout, card styling, section structure
- [Source: Peach/Comparison/ComparisonScreen.swift] — Current ComparisonScreen layout, intervals parameter
- [Source: Peach/PitchMatching/PitchMatchingScreen.swift] — Current PitchMatchingScreen layout, intervals parameter
- [Source: Peach/Core/Profile/ProgressTimeline.swift] — Public API: state(for:), buckets(for:), currentEWMA(for:), trend(for:), TrainingMode enum, TimeBucket struct, Trend enum
- [Source: Peach/Core/Profile/TrainingModeConfig.swift] — displayName, unitLabel, config(for:) static method
- [Source: Peach/Profile/ProgressChartView.swift] — Existing trend color/symbol/label helpers, formatEWMA static method
- [Source: docs/project-context.md] — Coding conventions, dependency direction rules, testing rules, localization workflow

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
