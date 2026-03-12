# Story 41.7: Help Button with Tip Reset

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a returning user,
I want a "?" button in the Profile screen navigation bar that replays all chart help tips,
so that I can re-read the explanations whenever I need a refresher.

## Design Change from Original Epic

**CRITICAL:** The original epic described a "?" button on **each progress card header**. This has been changed:

- **NOT** a button on each card's headline row
- **ONE** button in the **navigation bar trailing area**, styled as a pill — exactly the same placement and style as the help button on the training screens (PitchComparisonScreen, PitchMatchingScreen)
- Uses `questionmark.circle` SF Symbol in a toolbar button, matching the existing pattern

## Acceptance Criteria

1. **Given** the Profile screen navigation bar, **When** the screen renders, **Then** a "?" button is visible in the trailing toolbar area, matching the training screen help button placement

2. **Given** the user wants to review chart explanations, **When** the user taps the "?" button, **Then** a help sheet opens showing all five chart explanations (TipKit runtime reset is not feasible — see Dev Agent Record)

3. **Given** the "?" button, **When** VoiceOver is active, **Then** the button has an accessibility label "Help"

## Tasks / Subtasks

- [x] Task 1: Add toolbar help button to ProfileScreen (AC: #1)
  - [x] Add `@State private var` flag (if needed) for managing tip reset
  - [x] Add `.toolbar { ToolbarItem(placement: .navigationBarTrailing) }` with `questionmark.circle` button
  - [x] Style must match training screens exactly — `Label("Help", systemImage: "questionmark.circle")` inside a `Button`
- [x] Task 2: Implement help sheet on tap (AC: #2 — revised)
  - [x] On button tap, open help sheet with all five chart explanations via `HelpContentView`
  - [x] Reuse existing localized strings from ChartTips (already translated EN+DE)
  - [x] TipKit runtime reset not feasible — see Dev Agent Record for investigation details
- [x] Task 3: Accessibility (AC: #3)
  - [x] Button uses `Label("Help", systemImage: "questionmark.circle")` — VoiceOver reads "Help"
  - [x] Restored screen-level accessibility summary on ScrollView content (moved from outer view during review)
- [x] Task 4: Localization
  - [x] Add "Chart Help" / "Diagramm-Hilfe" to Localizable.xcstrings for sheet title
- [x] Task 5: Manual verification
  - [x] Verify button appears in nav bar trailing position
  - [x] Verify tapping opens help sheet with all five chart explanations
  - [x] Verify VoiceOver reads "Help" on button
  - [x] Run `bin/test.sh` — all existing tests must pass
  - [x] Run `bin/build.sh` — no warnings or errors

## Dev Notes

### Critical Design Decision

The help button lives in **ProfileScreen's navigation toolbar**, NOT in ProgressChartView's headline row. This is consistent with:
1. The user's explicit instruction to match the training screen pattern
2. The 41.6 review decision that moved TipGroup to ProfileScreen (tips are screen-level, not card-level)

### Existing Pattern to Follow

The training screens (PitchComparisonScreen, PitchMatchingScreen, SettingsScreen) all use the same toolbar help button pattern:

```swift
// From PitchComparisonScreen.swift:109-116
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button {
            // action
        } label: {
            Label("Help", systemImage: "questionmark.circle")
        }
    }
}
```

ProfileScreen currently has NO toolbar items. Add one with just the help button (no settings or other nav links needed — Profile is a leaf destination reached from training screens).

### TipKit Reset Implementation

`Tips.resetDatastore()` is an async throwing function. After calling it, the `@State tipGroup` needs to be recreated to pick up the reset state. Approach:

```swift
// Option A: Reset and recreate tipGroup
Button {
    Task {
        try? Tips.resetDatastore()
        tipGroup = TipGroup(.ordered) {
            ChartOverviewTip()
            EWMALineTip()
            StdDevBandTip()
            BaselineTip()
            GranularityZoneTip()
        }
    }
} label: {
    Label("Show chart help", systemImage: "questionmark.circle")
}
```

**Important:** `Tips.resetDatastore()` resets ALL tips globally, not just chart tips. This is acceptable because chart tips are the only TipKit tips in the app (as established in 41.6).

### Files to Modify

| File | Change |
|------|--------|
| `Peach/Profile/ProfileScreen.swift` | Add `.toolbar` modifier with help button; add tip reset logic |
| `Peach/Localization/Localizable.xcstrings` | Add "Show chart help" EN+DE |

**No new files needed.** Do NOT modify ProgressChartView — the button does not go on cards.

### What NOT to Do

- Do NOT add a button to `ProgressChartView.headlineRow()` — the original epic's per-card design was overridden
- Do NOT add a help sheet — this button resets TipKit tips inline, not a modal sheet
- Do NOT pass tipGroup to ProgressChartView — it stays entirely in ProfileScreen

### Project Structure Notes

- Alignment: Button follows established toolbar pattern from training screens
- No new dependencies — TipKit already imported in ProfileScreen.swift
- No architecture violations — UI-only change within Profile feature boundary

### References

- [Source: Peach/Profile/ProfileScreen.swift] — current ProfileScreen with TipGroup
- [Source: Peach/Profile/ChartTips.swift] — five tip definitions
- [Source: Peach/PitchComparison/PitchComparisonScreen.swift:109-116] — toolbar help button pattern to match
- [Source: docs/implementation-artifacts/41-6-tipkit-help-overlay-system.md] — previous story establishing TipKit foundation
- [Source: docs/project-context.md] — project conventions

### Previous Story Intelligence (41.6)

- TipGroup was moved from ProgressChartView to ProfileScreen during review — tips are screen-level
- Tips use `TipGroup(.ordered)` for sequential display
- `Tips.configure()` is called in PeachApp.init
- All five tips have English + German localizations
- TipView renders inline above progress cards in the ScrollView

### Git Intelligence

Recent commits show the pattern: create story → implement → review with architectural adjustments. The 41.6 review moved TipGroup to ProfileScreen, which aligns perfectly with this story's approach of putting the reset button at screen level too.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

No issues encountered.

### Implementation Deviation from AC #2

**AC #2 specifies:** "all chart tips are reset and the sequential tip flow restarts from the first tip"

**What was implemented instead:** Help button opens a help sheet (matching SettingsScreen/training screen pattern) that shows all five chart explanations at once.

**Why TipKit inline tip reset is not possible:**

1. `Tips.resetDatastore()` throws `TipKitError.tipsDatastoreAlreadyConfigured` — it can only be called BEFORE `Tips.configure()`, not at runtime after tips are already configured. There is no public API to unconfigure TipKit.
2. `Tips.showAllTipsForTesting()` has no effect when called at runtime after tips have been dismissed.
3. Reconfiguring with `Tips.configure([.datastoreLocation(.url(freshURL))])` succeeds but `TipGroup.currentTip` remains `nil` — dismissed tip state persists in-memory regardless of datastore changes.
4. Reassigning `@State tipGroup` with a new `TipGroup` instance does not cause SwiftUI to re-observe `currentTip` on the new object.

All four approaches were tested with diagnostic logging. TipKit fundamentally does not support un-dismissing tips at runtime — `resetDatastore()` is a development/testing utility meant for app startup, not a runtime feature.

**Reviewer decision needed:** Accept the help sheet approach (consistent with the rest of the app), or propose an alternative. One option would be removing TipKit entirely and managing tip display with custom `@AppStorage` state, but that's a larger change.

### Bug Fix: `.accessibilityLabel` blocking toolbar taps

The previous ProfileScreen had `.accessibilityLabel(accessibilitySummary)` applied to the outer view (after `.toolbar`). This caused UIKit to treat the entire screen as a single accessibility element, which silently swallowed all toolbar button taps — the button was visible but its action never fired. During review, the label was moved to the ScrollView content VStack with `.accessibilityElement(children: .contain)` so VoiceOver still announces the screen summary without blocking toolbar interaction.

### Completion Notes List

- Added `.toolbar` modifier with `ToolbarItem(placement: .navigationBarTrailing)` containing a help button — matches SettingsScreen pattern exactly
- Button opens a help sheet with all five chart explanations using `HelpContentView` (existing shared component)
- Help content reuses the same localized strings as the ChartTips (already translated EN+DE from story 41.6)
- Added "Chart Help" localization with German translation "Diagramm-Hilfe"
- Moved `.accessibilityLabel(accessibilitySummary)` from outer view to ScrollView content VStack (outer view placement blocked toolbar taps)
- Removed unused "Show chart help" localization key
- No new files created, no ProgressChartView modifications
- Build succeeds, all 1063 tests pass

### File List

- Peach/Profile/ProfileScreen.swift (modified)
- Peach/Resources/Localizable.xcstrings (modified)
- docs/implementation-artifacts/41-7-help-button-with-tip-reset.md (modified)
- docs/implementation-artifacts/sprint-status.yaml (modified)

### Change Log

- 2026-03-12: Implemented help button with help sheet in ProfileScreen toolbar (Story 41.7)
- 2026-03-12: Fixed `.accessibilityLabel` on outer view blocking toolbar taps
- 2026-03-12: Review — restored accessibility summary on ScrollView content, updated ACs/tasks to reflect help sheet approach, fixed File List path
