---
title: 'Vertical Range Indicator Line for Pitch Slider'
slug: 'pitch-slider-range-line'
created: '2026-03-06'
status: 'completed'
stepsCompleted: [1, 2, 3, 4]
tech_stack: [SwiftUI]
files_to_modify: [Peach/PitchMatching/VerticalPitchSlider.swift]
code_patterns: [ZStack layering back-to-front, GeometryReader for layout, static methods for testable logic]
test_patterns: [Swift Testing with @Test/@Suite/#expect, async test functions, static method unit tests]
---

# Tech-Spec: Vertical Range Indicator Line for Pitch Slider

**Created:** 2026-03-06

## Overview

### Problem Statement

The pitch matching slider has no visual reference — the thumb floats on an invisible track, making it hard to judge position relative to the range extremes.

### Solution

Add a thin vertical line behind the slider thumb spanning the full track height, using a system color for a subtle visual anchor. This matches the web version's approach.

### Scope

**In Scope:**
- Adding a vertical range indicator line to `VerticalPitchSlider`

**Out of Scope:**
- Center indicators or tick marks
- Gradient effects or dashed lines
- Changes to slider behavior, gestures, or other screens

## Context for Development

### Codebase Patterns

- `VerticalPitchSlider` uses `GeometryReader` for layout with static helper methods for testability
- The track area is currently a `Color.clear` `Rectangle` with `.contentShape(Rectangle())`
- The thumb is a `RoundedRectangle` filled with `.tint`

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `Peach/PitchMatching/VerticalPitchSlider.swift` | The slider view to modify |
| `PeachTests/PitchMatching/VerticalPitchSliderTests.swift` | Existing tests |

### Technical Decisions

- Use `.separator` system color — designed for thin lines, adapts to light/dark mode automatically
- Simple solid line, no decorations
- Line goes in the `ZStack` between the clear hit-test rectangle and the thumb
- No new static methods needed — purely visual, no testable logic added
- Line width: 2pt (standard thin track width, visible but unobtrusive)

## Implementation Plan

### Tasks

- [x] Task 1: Add vertical range indicator line to `VerticalPitchSlider`
  - File: `Peach/PitchMatching/VerticalPitchSlider.swift`
  - Action: Inside the `ZStack` in `body`, add a `Rectangle` between the existing clear hit-test rectangle and the thumb `RoundedRectangle`. The line should be:
    - Width: 2pt, full height of the track (no explicit height — let it fill the `ZStack`)
    - Fill: `.separator` system color
    - Horizontally centered (default `ZStack` alignment handles this)
    - Rendered behind the thumb (placed before the thumb in the `ZStack`)
  - Notes: The line should share the same opacity modifier as the thumb (`isActive ? 1.0 : 0.4`) since it's part of the same visual group. This is already handled — both elements are inside the `ZStack` which has `.opacity` applied indirectly via `.disabled(!isActive)`. However, the current opacity modifier is on the thumb... actually, looking at the code: `.opacity(isActive ? 1.0 : 0.4)` is applied to the entire `ZStack`'s parent (the gesture view). So the line will inherit the same opacity automatically. No extra work needed.

### Acceptance Criteria

- [x] AC 1: Given the pitch matching screen is displayed, when the slider is active (awaiting touch or playing tunable), then a thin vertical line is visible spanning the full height of the slider track area
- [x] AC 2: Given the slider is inactive (not in an active state), when the screen renders, then the vertical line is visible but dimmed (same opacity as the thumb)
- [x] AC 3: Given light mode or dark mode, when the slider renders, then the line color adapts appropriately (uses `.separator` system color)
- [x] AC 4: Given the slider thumb is dragged, when it moves along the track, then the vertical line remains stationary behind the thumb as a fixed reference

## Additional Context

### Dependencies

None — purely visual change using built-in SwiftUI primitives and system colors.

### Testing Strategy

- **No new unit tests needed** — the change adds a static visual element with no logic, no new static methods, and no behavioral changes. Existing tests for `value()` and `thumbPosition()` remain valid and unchanged.
- **Manual testing:** Verify the line appears in both light and dark mode, is visible but subtle, and the thumb moves over it correctly. Check both active and inactive states for correct opacity.

### Notes

- The line width of 2pt is a starting point — may need visual tuning after seeing it on device. Adjust if it looks too thick or too thin relative to the thumb (80x60pt).
- Future enhancement (out of scope): could add small endpoint indicators. Keep it simple for now.

## Review Notes
- Adversarial review completed
- Findings: 6 total, 1 fixed, 5 skipped
- Resolution approach: auto-fix
- F1 (fixed): Changed `Rectangle` to `Capsule` for rounded line ends matching the thumb's rounded style
