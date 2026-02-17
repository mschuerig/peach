# Hotfix: Replace Signed Mean with Absolute Mean in PerceptualProfile

Status: ready-for-dev

## Motivation

The current `PerceptualProfile` uses a **signed mean** for detection thresholds. The `centOffset` passed to `update()` is signed based on comparison direction (`+` if `isSecondNoteHigher`, `-` otherwise). Welford's algorithm then computes a running average of these signed values.

The problem: signed values cancel each other out. If a note has equal "higher" and "lower" comparisons at 50 cents, the signed mean approaches 0.0 — making it look like the user has excellent discrimination when their actual threshold is 50 cents. The `weakSpots()` method uses `abs(mean)` to rank notes, but `abs(mean of signed values)` is not the same as `mean of absolute values`:

- `abs(mean(+50, -50))` = `abs(0)` = **0.0** (wrong — implies perfect discrimination)
- `mean(abs(+50), abs(-50))` = `mean(50, 50)` = **50.0** (correct threshold)

This affects weak spot identification, summary statistics, and potentially any future features built on the mean.

Documented in `future-work.md` under "Investigate Signed Mean in Perceptual Profile".

## Story

As a **musician using Peach**,
I want my perceptual profile to accurately reflect my pitch discrimination threshold,
So that weak spot identification and training targeting are based on my actual ability, not an artifact of signed averaging.

## Acceptance Criteria

1. **Given** `PerceptualProfile.update()`, **When** a comparison result is recorded, **Then** the `mean` is computed from `abs(centOffset)` (unsigned), not signed centOffset

2. **Given** a note with equal "higher" and "lower" comparisons at 50 cents, **When** `weakSpots()` is called, **Then** the mean is 50.0 (not 0.0)

3. **Given** `weakSpots()`, **When** ranking notes, **Then** it can use `stats.mean` directly (no `abs()` wrapper needed) since mean is now always non-negative

4. **Given** `PerceptualProfile.comparisonCompleted()`, **When** computing the centOffset for `update()`, **Then** it passes `comparison.centDifference` (unsigned) instead of the signed value

5. **Given** `overallMean`, **When** computing the aggregate, **Then** it returns the mean of unsigned per-note means

6. **Given** all existing tests (updated where needed), **When** the full test suite is run, **Then** all tests pass with zero regressions

## Tasks / Subtasks

- [ ] Task 1: Change `comparisonCompleted()` to pass unsigned centOffset
  - [ ] In `PerceptualProfile.comparisonCompleted()` (line 196), change `let centOffset = comparison.isSecondNoteHigher ? comparison.centDifference : -comparison.centDifference` to `let centOffset = comparison.centDifference`
  - [ ] Update comment on line 195 to reflect unsigned approach

- [ ] Task 2: Simplify `weakSpots()` to remove `abs()` wrapper
  - [ ] In `weakSpots()` (line 80), change `score = abs(stats.mean)` to `score = stats.mean`
  - [ ] Update doc comment (line 67) to remove "Uses absolute value of mean to ignore directional bias"

- [ ] Task 3: Update `PerceptualNote.mean` documentation
  - [ ] Change doc comment (line 155) from "signed average tracking directional bias" to reflect unsigned threshold meaning
  - [ ] Remove "Positive = more higher / Negative = more lower" comment (line 156)

- [ ] Task 4: Update `update()` method documentation
  - [ ] Update parameter doc for `centOffset` (line 36) to reflect that it is now unsigned

- [ ] Task 5: Update tests for unsigned mean behavior
  - [ ] Update `PerceptualProfileTests` — tests that assert signed mean values need updating
  - [ ] Update `TrainingSessionTests` — tests at lines 468, 575 assert negative means (e.g., `-95.0`, `-40.0`); these should become positive
  - [ ] Update `AdaptiveNoteStrategyTests.weakSpotsUseAbsoluteValue` — negative centOffset test case should produce positive mean
  - [ ] Verify all weak spot tests still correctly identify high-threshold notes

- [ ] Task 6: Run full test suite and verify no regressions

## Dev Notes

### The Core Issue

The signed mean conflates two separate pieces of information:
1. **Detection threshold** — how large a pitch difference the user can reliably detect (always positive)
2. **Directional bias** — whether the user is better at detecting "higher" vs "lower" comparisons (signed)

Currently, both are encoded in a single signed field. This means the threshold information is corrupted by direction cancellation.

### What Changes

The fix is simple: pass `comparison.centDifference` (always positive) to `update()` instead of the signed value. This makes `mean` an accurate representation of the average detection threshold.

**`comparisonCompleted()` (line 192-203):**

Current:
```swift
let centOffset = comparison.isSecondNoteHigher ? comparison.centDifference : -comparison.centDifference
```

New:
```swift
let centOffset = comparison.centDifference
```

**`weakSpots()` (line 80):**

Current:
```swift
score = abs(stats.mean)
```

New:
```swift
score = stats.mean
```

### What Does NOT Change

- **Welford's algorithm** — still used for incremental mean/stdDev computation
- **`currentDifficulty` field** — unrelated to `mean` (used by AdaptiveNoteStrategy)
- **`AdaptiveNoteStrategy`** — does not read `mean` field at all (uses `currentDifficulty`)
- **`stdDev` calculation** — still valid (variance of unsigned values)
- **`sampleCount`** — unchanged
- **`overallMean` / `overallStdDev`** — still computed from per-note means (now unsigned)

### Directional Bias: Deferred

The future-work item mentioned potentially tracking directional bias separately. This story does NOT add directional bias tracking — it simply removes the corrupted signal. If directional bias is useful, it can be added later as a separate field (e.g., `directionalBias: Double` tracking the proportion of correct "higher" vs "lower" answers).

### Test Impact Analysis

Tests asserting on `mean` values:

| Test File | Line | Current Assert | New Assert |
|-----------|------|---------------|------------|
| PerceptualProfileTests | 40 | `mean == 0.0` | `mean == 0.0` (unchanged — no data) |
| PerceptualProfileTests | 56 | `mean == 50.0` | `mean == 50.0` (already positive) |
| PerceptualProfileTests | 69-71 | `mean == 50.0/30.0/40.0` | Unchanged (positive values) |
| PerceptualProfileTests | 99 | `mean == 50.0` | Unchanged |
| PerceptualProfileTests | 111 | `mean == 45.0` | Unchanged |
| TrainingSessionTests | 421 | `mean == 100.0` | Unchanged |
| TrainingSessionTests | 436 | `mean == 10.0` | Unchanged |
| TrainingSessionTests | 468 | `mean == -95.0` | → `mean == 95.0` |
| TrainingSessionTests | 575 | `mean == -40.0` | → `mean == 40.0` |
| TrainingSessionTests | 493 | `mean == 100.0` | Unchanged |
| AdaptiveNoteStrategyTests | 347 | `-80.0` centOffset | Weak spot test: need to verify ranking still works with positive means |

### References

- `Peach/Core/Profile/PerceptualProfile.swift` — target file (update, weakSpots, comparisonCompleted)
- `PeachTests/Core/Profile/PerceptualProfileTests.swift` — profile tests
- `PeachTests/Training/TrainingSessionTests.swift` — integration tests asserting mean values
- `PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift` — weak spot test
- `docs/implementation-artifacts/future-work.md` — source issue

## Dev Agent Record

### Implementation Plan

*(To be filled during implementation)*

### Completion Notes

*(To be filled during implementation)*

## File List

*(To be filled during implementation)*

## Change Log

- 2026-02-17: Story created from future-work.md item "Investigate Signed Mean in Perceptual Profile"
