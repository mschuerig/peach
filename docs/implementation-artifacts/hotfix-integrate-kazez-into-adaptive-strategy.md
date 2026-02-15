# Hotfix: Integrate Kazez Convergence into AdaptiveNoteStrategy

Status: pending

## Motivation

The `KazezNoteStrategy` (see `hotfix-kazez-evaluation-strategy.md`) validated that the Kazez sqrt(P)-scaled formulas provide dramatically better difficulty convergence than the fixed multiplicative factors in `AdaptiveNoteStrategy`. Manual testing confirmed the training feel is responsive — difficulty homes in on the user's threshold in ~10 correct answers.

This story integrates the Kazez math into `AdaptiveNoteStrategy` while preserving its per-note difficulty tracking, then restores `AdaptiveNoteStrategy` as the active strategy in `PeachApp`.

## Story

As a **musician using Peach**,
I want the adaptive algorithm to converge quickly to my pitch discrimination threshold,
So that training feels responsive and targets my actual skill level from the start.

## Acceptance Criteria

1. **Given** `AdaptiveNoteStrategy`, **When** a correct answer is recorded, **Then** difficulty narrows using `N = P × [1 - (0.05 × sqrt(P))]` instead of a fixed factor

2. **Given** `AdaptiveNoteStrategy`, **When** an incorrect answer is recorded, **Then** difficulty widens using `N = P × [1 + (0.09 × sqrt(P))]` instead of a fixed factor

3. **Given** the per-note difficulty system, **When** Kazez formulas are applied, **Then** each note's `currentDifficulty` is still tracked independently via `PerceptualProfile.setDifficulty(note:difficulty:)`

4. **Given** `PeachApp`, **When** the app starts, **Then** it uses `AdaptiveNoteStrategy` (not `KazezNoteStrategy`)

5. **Given** all existing tests, **When** the full test suite is run, **Then** all tests pass (updated expectations where needed)

## Tasks / Subtasks

- [ ] Task 1: Replace fixed factors with Kazez formulas in AdaptiveNoteStrategy
  - [ ] Remove `narrowingFactor` and `wideningFactor` from `DifficultyParameters`
  - [ ] Replace difficulty math in `determineCentDifference()` with Kazez formulas
  - [ ] Keep per-note `currentDifficulty` as P (input to formula)
  - [ ] Keep `profile.setDifficulty(note:difficulty:)` call (output of formula)
  - [ ] Keep clamping to `settings.minCentDifference` / `settings.maxCentDifference`

- [ ] Task 2: Restore AdaptiveNoteStrategy in PeachApp
  - [ ] Change `KazezNoteStrategy()` back to `AdaptiveNoteStrategy()` in PeachApp.swift
  - [ ] Restore comment to reference Story 4.3

- [ ] Task 3: Update AdaptiveNoteStrategy tests
  - [ ] Update narrowing tests: expect Kazez formula output instead of `× 0.95`
  - [ ] Update widening tests: expect Kazez formula output instead of `× 1.3`
  - [ ] Add convergence test similar to KazezNoteStrategyTests (10 correct → ~5 cents)
  - [ ] Verify per-note tracking still works (different notes have independent difficulties)

- [ ] Task 4: Run full test suite and verify no regressions

## Dev Notes

### What Changes in AdaptiveNoteStrategy

The change is surgical — only `determineCentDifference()` (lines 197–220 of `AdaptiveNoteStrategy.swift`) needs modification. Currently:

```swift
let adjustedDiff = last.isCorrect
    ? max(stats.currentDifficulty * DifficultyParameters.narrowingFactor,
          settings.minCentDifference)
    : min(stats.currentDifficulty * DifficultyParameters.wideningFactor,
          settings.maxCentDifference)
```

Becomes:

```swift
let p = stats.currentDifficulty
let adjustedDiff = last.isCorrect
    ? max(p * (1.0 - 0.05 * p.squareRoot()),
          settings.minCentDifference)
    : min(p * (1.0 + 0.09 * p.squareRoot()),
          settings.maxCentDifference)
```

### What Does NOT Change

- **Note selection logic** (Natural/Mechanical balance, weak spots, nearby notes) — untouched
- **Per-note difficulty tracking** (`PerceptualProfile.setDifficulty`) — still called with the adjusted value
- **Regional difficulty** — each note still has independent `currentDifficulty`
- **Protocol interface** — `NextNoteStrategy.nextComparison()` signature unchanged
- **Cold start behavior** — untrained notes still default to 100 cents
- **`KazezNoteStrategy`** — remains in codebase for future A/B testing or reference

### Key Difference: Per-Note P vs Global P

In `KazezNoteStrategy`, P comes from `lastComparison.comparison.centDifference` (global, stateless). In `AdaptiveNoteStrategy`, P comes from `stats.currentDifficulty` for the specific note being trained (per-note, profile-backed). This is the correct source — the per-note difficulty *is* the previous interval for that note's training.

### DifficultyParameters Cleanup

After this change, `DifficultyParameters` simplifies to:

```swift
private enum DifficultyParameters {
    static let regionalRange: Int = 12
    static let defaultDifficulty: Double = 100.0
}
```

`narrowingFactor` and `wideningFactor` are removed entirely — the Kazez formulas replace them.

### Test Expectations to Update

In `AdaptiveNoteStrategyTests.swift`, tests that assert `× 0.95` or `× 1.3` behavior need updating:

- **Narrowing test at 100 cents**: currently expects 95.0 → should expect 50.0
- **Widening test at 100 cents**: currently expects 130.0 → should expect `100 × (1 + 0.09 × 10) = 190`, clamped to maxCentDifference (100.0)
- **Narrowing at smaller values**: will differ proportionally (see convergence table in hotfix-kazez-evaluation-strategy.md)

### References

- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — target file, `determineCentDifference()` method
- `Peach/Core/Algorithm/KazezNoteStrategy.swift` — reference implementation of Kazez formulas
- `PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift` — tests to update
- `Peach/App/PeachApp.swift` — strategy swap back to AdaptiveNoteStrategy
- `docs/implementation-artifacts/hotfix-kazez-evaluation-strategy.md` — evaluation story with convergence table

## Change Log

- 2026-02-15: Story created — integrate validated Kazez formulas into AdaptiveNoteStrategy
