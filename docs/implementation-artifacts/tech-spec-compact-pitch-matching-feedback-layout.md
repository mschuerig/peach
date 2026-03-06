---
title: 'Compact Pitch Matching Feedback Layout'
slug: 'compact-pitch-matching-feedback-layout'
created: '2026-03-06'
status: 'completed'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['SwiftUI', 'Swift 6.2']
files_to_modify: ['Peach/PitchMatching/PitchMatchingScreen.swift', 'Peach/PitchMatching/PitchMatchingFeedbackIndicator.swift']
code_patterns: ['static methods for testable layout logic', 'extracted subviews', 'thin views with no business logic']
test_patterns: ['static method unit tests for band/color/text/accessibility logic', 'no existing icon size or layout height tests']
---

# Tech-Spec: Compact Pitch Matching Feedback Layout

**Created:** 2026-03-06

## Overview

### Problem Statement

The `PitchMatchingFeedbackIndicator` occupies a fixed 130pt of vertical space in `PitchMatchingScreen`, using large arrow icons (40-100pt). This significantly reduces the available height for the `VerticalPitchSlider`, especially in landscape orientation where vertical space is scarce and slider length is critical for delicate pitch adjustments.

### Solution

Restructure the top area of `PitchMatchingScreen` so the feedback indicator sits to the right of the stats/interval label, using a compact horizontal layout (arrow + cents text in an HStack). The feedback arrow scales to the natural height of the two text lines beside it. This eliminates the 130pt fixed height and gives the slider all remaining vertical space.

### Scope

**In Scope:**
- Rearrange `PitchMatchingScreen` layout: stats + interval label on the left, compact feedback on the right
- Redesign `PitchMatchingFeedbackIndicator` to a compact horizontal layout (arrow icon + cents text in HStack)
- Remove the 130pt fixed height for the feedback indicator
- Slider fills all remaining vertical space

**Out of Scope:**
- Changes to `VerticalPitchSlider` internals
- Changes to `TrainingStatsView` internals
- Feedback logic, colors, or band thresholds
- `PitchComparisonScreen` layout

## Context for Development

### Codebase Patterns

- Views are thin — observe state, render, send actions; no business logic
- Extract subviews at ~40 lines
- Layout parameters extracted to `static` methods for unit testability
- `@Environment(\.accessibilityReduceMotion)` already used for feedback animation
- Same layout works for both portrait and landscape orientations

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `Peach/PitchMatching/PitchMatchingScreen.swift` | Main screen — current VStack layout with 130pt feedback height constant |
| `Peach/PitchMatching/PitchMatchingFeedbackIndicator.swift` | Current vertical feedback view (VStack: large arrow icon 40-100pt + cents text) |
| `Peach/App/TrainingStatsView.swift` | Stats view (Latest/Best) — no changes, layout context only |
| `PeachTests/PitchMatching/PitchMatchingFeedbackIndicatorTests.swift` | Existing tests for static methods (band, color, text, accessibility) — all pass unchanged |
| `PeachTests/PitchMatching/PitchMatchingScreenTests.swift` | Existing tests for feedbackAnimation and helpSections — no layout height tests exist |

### Technical Decisions

- The feedback arrow icon sizes to match the natural height of the two text lines beside it, using `.font(.title2)` instead of fixed pixel sizes
- The compact feedback uses an HStack (arrow + cents text) instead of the current VStack
- The `feedbackIndicatorHeight` constant (130pt) is removed entirely — no fixed height reservation
- The four icon size constants (`defaultIconSize`, `closeIconSize`, `moderateIconSize`, `farIconSize`) and `iconSizeForBand()` method are removed — a single font size applies to all bands
- All static logic methods (`band()`, `centOffsetText()`, `arrowSymbolName()`, `feedbackColor()`, `accessibilityLabel()`) remain unchanged

## Implementation Plan

### Tasks

- [x] Task 1: Redesign `PitchMatchingFeedbackIndicator` to compact horizontal layout
  - File: `Peach/PitchMatching/PitchMatchingFeedbackIndicator.swift`
  - Action: Change the view body from a VStack (large icon stacked above text) to an HStack (icon beside text). Replace the four fixed icon size constants and `iconSizeForBand()` with a single `.font(.title2)` on the arrow image. Keep all static logic methods (`band()`, `centOffsetText()`, `arrowSymbolName()`, `feedbackColor()`, `accessibilityLabel()`) unchanged.
  - Details:
    - Remove: `defaultIconSize` (100), `closeIconSize` (40), `moderateIconSize` (70), `farIconSize` (100) constants
    - Remove: `iconSizeForBand(_:)` method
    - Change body: `VStack(spacing: 4)` → `HStack(spacing: 4)`
    - Change icon: `.font(.system(size: Self.iconSizeForBand(band)))` → `.font(.title2)`
    - Keep: all accessibilityElement/accessibilityLabel modifiers
    - Update previews to remove `.padding()` frame if desired

- [x] Task 2: Restructure `PitchMatchingScreen` top area layout
  - File: `Peach/PitchMatching/PitchMatchingScreen.swift`
  - Action: Replace the current sequential VStack (TrainingStatsView → interval label → feedback indicator → slider) with a two-column top area (left: stats + interval label, right: feedback) above the slider.
  - Details:
    - Remove: `feedbackIndicatorHeight` constant (line 150)
    - Remove: `.frame(height: Self.feedbackIndicatorHeight)` from the feedback indicator
    - Wrap TrainingStatsView, interval label, and PitchMatchingFeedbackIndicator in an HStack:
      - Left side (VStack): TrainingStatsView on top, interval label below (when in interval mode)
      - Right side: PitchMatchingFeedbackIndicator (pushed to trailing edge with `Spacer()`)
    - The feedback indicator's `.opacity()` and `.animation()` modifiers stay as-is
    - The `.accessibilityHidden()` modifier stays as-is
    - VerticalPitchSlider remains below, filling all remaining space with `.padding()`

### Acceptance Criteria

- [ ] AC 1: Given the pitch matching screen is displayed, when the user sees the layout, then the training stats (Latest/Best) appear in the top-left area and the feedback indicator appears to the right of the stats
- [ ] AC 2: Given a pitch matching exercise completes, when feedback is shown, then the feedback arrow and cent error text appear side by side (horizontally) to the right of the stats
- [ ] AC 3: Given the device is in landscape orientation, when the pitch matching screen is displayed, then the vertical slider fills all available height below the single-row top area (no 130pt gap)
- [ ] AC 4: Given interval mode is active, when the screen is displayed, then the interval label and tuning system appear below the stats in the left column, with feedback still to the right
- [ ] AC 5: Given feedback is not being shown (state != .showingFeedback), when the screen is displayed, then the feedback area has zero opacity but still occupies its natural layout space (no layout jumps)
- [ ] AC 6: Given Reduce Motion is enabled, when feedback appears, then no animation is applied (existing behavior preserved)
- [ ] AC 7: Given VoiceOver is active, when feedback is shown, then the accessibility label reads the cent error with direction ("X cents sharp/flat" or "Dead center") — unchanged from current behavior

## Additional Context

### Dependencies

None — pure UI layout change with no service or data model impacts.

### Testing Strategy

- **No test changes required** — all 33 existing tests in `PitchMatchingFeedbackIndicatorTests` test static logic methods (`band()`, `feedbackColor()`, `centOffsetText()`, `arrowSymbolName()`, `accessibilityLabel()`) which remain unchanged
- **No layout height tests exist** in `PitchMatchingScreenTests` — the `feedbackIndicatorHeight` constant removal has no test impact
- **Manual verification**: Check both portrait and landscape on iPhone and iPad to confirm slider fills available space and feedback renders compactly beside stats

### Notes

- The `feedbackAnimation` static method and its tests in `PitchMatchingScreenTests` remain unchanged
- The `helpSections` tests in `PitchMatchingScreenTests` remain unchanged
- If the compact feedback feels too small visually, `.title2` can be adjusted to `.title3` or a custom size — but start with `.title2` to match the text beside it

## Review Notes

- Adversarial review completed
- Findings: 7 total, 4 fixed, 3 skipped
- Resolution approach: auto-fix
- F1 (High, fixed): Added hidden placeholder in feedback indicator to prevent layout jump on first feedback
- F2 (Medium, fixed): Added `HStack(alignment: .top)` for proper vertical alignment
- F3 (Medium, skipped): Icon size variation removal is intentional per spec
- F4 (Medium, fixed): Added `.leading` alignment to interval VStack
- F5 (Low, skipped): Padding equivalence verified — no change needed
- F6 (Low, skipped): No tests reference `feedbackIndicatorHeight` — confirmed safe
- F7 (Low, fixed): Removed extra blank line
