# Hotfix: Kazez Evaluation Strategy

Status: done

## Motivation

During manual testing after completing Epic 4, a critical issue was discovered: the `AdaptiveNoteStrategy` difficulty convergence is far too slow. With a fixed `narrowingFactor` of 0.95 (5% reduction per correct answer), reaching the 5–10 cent range from the starting 100 cents requires approximately 60 consecutive correct answers. Users experience no perceptible progress for an extended period, violating the "Training, not testing" design philosophy.

This must be addressed before proceeding with Epics 5–7, which build on top of the adaptive algorithm.

## Approach

Rather than modifying the existing `AdaptiveNoteStrategy` (which implements per-note difficulty tracking intended for the final product), we implement a **separate, simpler strategy** behind the existing `NextNoteStrategy` protocol. This allows isolated evaluation of the Kazez difficulty formulas without risking the production algorithm.

The evaluation strategy is based on the paper:

> Kazez, D., Kazez, B., Zembar, M.J., & Andrews, D. (2001). *A Computer Program for Testing (and Improving?) Pitch Perception.* College Music Society, 2001 National Conference.

## Story

As a **developer evaluating pitch training algorithms**,
I want a simple, Kazez-formula-based strategy hardwired into the training loop,
So that I can validate that the difficulty convergence feels responsive and natural before integrating the approach into the production algorithm.

## Acceptance Criteria

1. **Given** a new `KazezNoteStrategy` class, **When** it conforms to `NextNoteStrategy`, **Then** it can be injected into `TrainingSession` without any other code changes

2. **Given** a correct answer with previous interval P (in cents), **When** the next comparison is generated, **Then** the new interval is `N = P × [1 - (0.05 × sqrt(P))]`, clamped to `minCentDifference`

3. **Given** an incorrect answer with previous interval P (in cents), **When** the next comparison is generated, **Then** the new interval is `N = P × [1 + (0.09 × sqrt(P))]`, clamped to `maxCentDifference`

4. **Given** no previous comparison (first in session), **When** training starts, **Then** the starting interval is `maxCentDifference` (100 cents)

5. **Given** the strategy, **When** it selects a note, **Then** it picks a random MIDI note within the range C3–C5 (48–72)

6. **Given** the strategy, **When** it calculates difficulty, **Then** it uses a single global difficulty (not per-note), derived solely from `lastComparison`

7. **Given** all existing tests, **When** the full test suite is run, **Then** all tests pass (no regressions)

## Tasks / Subtasks

- [x] Task 1: Revert uncommitted changes to AdaptiveNoteStrategy and NextNoteStrategy
  - [x] Restore `narrowingFactor` to 0.95, `wideningFactor` to 1.3
  - [x] Restore `noteRangeMin` default to 36, `noteRangeMax` default to 84
  - [x] Verify existing tests pass with restored values

- [x] Task 2: Implement KazezNoteStrategy (AC: #1, #2, #3, #4, #5, #6)
  - [x] Create `Peach/Core/Algorithm/KazezNoteStrategy.swift`
  - [x] Conform to `NextNoteStrategy` protocol
  - [x] Implement Kazez correct formula: `N = P × [1 - (0.05 × sqrt(P))]`
  - [x] Implement Kazez incorrect formula: `N = P × [1 + (0.09 × sqrt(P))]`
  - [x] Use `lastComparison.comparison.centDifference` as P (stateless)
  - [x] Fall back to `settings.maxCentDifference` when `lastComparison` is nil
  - [x] Clamp results to `settings.minCentDifference` / `settings.maxCentDifference`
  - [x] Note selection: `Int.random(in: 48...72)` (C3–C5 hardcoded)
  - [x] Direction: `Bool.random()` for isSecondNoteHigher

- [x] Task 3: Hardwire KazezNoteStrategy into PeachApp (AC: #1)
  - [x] Replace `AdaptiveNoteStrategy()` with `KazezNoteStrategy()` in PeachApp.swift
  - [x] No other wiring changes needed (protocol handles it)

- [x] Task 4: Write unit tests for KazezNoteStrategy (AC: #2, #3, #4, #7)
  - [x] Test correct-answer formula at various P values (100, 50, 10, 5)
  - [x] Test incorrect-answer formula at various P values (5, 10, 50)
  - [x] Test first comparison uses maxCentDifference
  - [x] Test floor clamping (minCentDifference)
  - [x] Test ceiling clamping (maxCentDifference)
  - [x] Test note selection within 48–72 range
  - [x] Test convergence: 10 consecutive correct from 100 → verify reaches ~5 cents

- [x] Task 5: Run full test suite and verify no regressions (AC: #7)

## Dev Notes

### Kazez Formulas — Convergence Profile

The key insight from the Kazez paper is using `sqrt(P)` as a scaling factor. This creates **proportional convergence**: large intervals shrink fast, small intervals shrink gently.

**After correct answer:** `N = P × [1 - (0.05 × sqrt(P))]`

| P (cents) | sqrt(P) | Factor      | N (cents) | Reduction |
|-----------|---------|-------------|-----------|-----------|
| 100       | 10.00   | 0.500       | 50.0      | 50%       |
| 50        | 7.07    | 0.646       | 32.3      | 35%       |
| 32        | 5.66    | 0.717       | 22.9      | 28%       |
| 23        | 4.80    | 0.760       | 17.5      | 24%       |
| 17        | 4.12    | 0.794       | 13.5      | 21%       |
| 13        | 3.61    | 0.820       | 10.7      | 18%       |
| 10        | 3.16    | 0.842       | 8.4       | 16%       |
| 8         | 2.83    | 0.859       | 6.9       | 14%       |
| 7         | 2.65    | 0.868       | 6.1       | 13%       |
| 6         | 2.45    | 0.878       | 5.3       | 12%       |
| 5         | 2.24    | 0.888       | 4.4       | 11%       |

With consecutive correct answers, the algorithm reaches ~5 cents in about **10 steps** (vs. ~60 with the fixed 0.95 factor).

**After incorrect answer:** `N = P × [1 + (0.09 × sqrt(P))]`

| P (cents) | sqrt(P) | Factor | N (cents) | Increase |
|-----------|---------|--------|-----------|----------|
| 5         | 2.24    | 1.201  | 6.0       | 20%      |
| 10        | 3.16    | 1.284  | 12.8      | 28%      |
| 50        | 7.07    | 1.636  | 81.8      | 64%      |

The asymmetry (larger increase on incorrect than decrease on correct) prevents the algorithm from oscillating and ensures it settles at the user's true threshold.

### Design Decisions

- **Stateless**: `lastComparison.comparison.centDifference` provides P directly. No internal state needed.
- **Global difficulty**: Single difficulty value (not per-note). This is intentional simplification for evaluation.
- **Hardcoded range**: C3–C5 (MIDI 48–72) baked into the strategy, not read from settings. This is an evaluation strategy — simplicity over configurability.
- **PerceptualProfile ignored**: The protocol passes it, but this strategy doesn't use it. Profile still gets updated via the observer pattern (data collection continues).
- **AdaptiveNoteStrategy untouched**: Production algorithm preserved for future integration of Kazez-style convergence into per-note tracking.

### What This Is NOT

- NOT a replacement for AdaptiveNoteStrategy
- NOT a permanent change — the production strategy will be updated with better convergence later
- NOT a change to the protocol, data model, or observer pattern
- NOT blocking Epics 5–7 — this unblocks them by validating the core training feel

### References

- Kazez et al. (2001), *A Computer Program for Testing (and Improving?) Pitch Perception*, CMS National Conference
- [Source: docs/planning-artifacts/architecture.md#Service Boundaries] — NextNoteStrategy protocol design
- [Source: docs/implementation-artifacts/4-2-implement-nextnotestrategy-protocol-and-adaptivenotestrategy.md] — AdaptiveNoteStrategy implementation
- [Source: docs/implementation-artifacts/4-3-integrate-adaptive-algorithm-into-trainingsession.md] — TrainingSession integration

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Completion Notes List

- Task 1: Uncommitted changes reverted by user (manual)
- Task 2: Created KazezNoteStrategy.swift — stateless, Kazez formulas, random note in 48–72, global difficulty
- Task 3: Swapped AdaptiveNoteStrategy → KazezNoteStrategy in PeachApp.swift (single line)
- Task 4: 15 unit tests covering formulas, clamping, note range, convergence, recovery
- Task 5: Full test suite passes (TEST SUCCEEDED)

### File List

New files:
- Peach/Core/Algorithm/KazezNoteStrategy.swift
- PeachTests/Core/Algorithm/KazezNoteStrategyTests.swift

Modified files:
- Peach/App/PeachApp.swift (strategy swap)
- docs/implementation-artifacts/future-work.md (convergence issue documented)

## Change Log

- 2026-02-15: Story created — Kazez evaluation strategy to address slow difficulty convergence in AdaptiveNoteStrategy
- 2026-02-15: Story implemented — KazezNoteStrategy with Kazez formulas, hardwired into PeachApp, 15 tests passing, full suite green
