# Future Work & Technical Considerations

This document tracks design decisions to revisit, architectural improvements, and technical debt items discovered during development.

## Algorithm & Design

### Investigate Signed Mean in Perceptual Profile

**Priority:** Medium
**Category:** Algorithm Design
**Date Added:** 2026-02-14

**Issue:**
The current implementation uses a signed mean for detection thresholds in `PerceptualProfile`. The mean tracks directional bias (positive = more "higher" comparisons, negative = more "lower" comparisons).

**Concern:**
Signed values make sense in other contexts (e.g., `centOffset` for frequency calculations), but using a signed mean for detection threshold may be conceptually incorrect. The detection threshold should represent the *magnitude* of discriminable pitch difference, not directional bias.

**Impact:**
- Affects weak spot identification (currently uses `abs(mean)`)
- May confuse the semantic meaning of "detection threshold"
- Could affect difficulty calculations in `AdaptiveNoteStrategy`

**Potential Solutions to Explore:**
- Separate directional bias tracking from threshold magnitude
- Use unsigned mean for threshold, track bias separately
- Re-evaluate whether directional bias is actually useful data

**Related Code:**
- `Peach/Core/Profile/PerceptualProfile.swift` - mean calculation and storage
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` - uses mean for difficulty
- Documentation uses "signed value" language in multiple places

**Next Steps:**
- Review mathematical foundation of pitch discrimination measurement
- Analyze historical comparison data to see if directional bias provides value
- Prototype alternative approaches
- Assess impact on existing training data migration

### AdaptiveNoteStrategy: Slow Difficulty Convergence

**Priority:** High
**Category:** Algorithm Design
**Date Added:** 2026-02-15

**Issue:**
The `AdaptiveNoteStrategy` uses a fixed multiplicative factor (`narrowingFactor: 0.95`) for difficulty reduction on correct answers. This requires ~60 consecutive correct answers to reach the 5-cent range from the starting 100 cents. During manual testing, the user remains stuck in the 100–80 cent range for an unacceptably long time, even when answering correctly every time.

**Root Cause:**
A fixed percentage reduction converges linearly in log-space — 5% reduction per step regardless of current difficulty. Large intervals should shrink faster; small intervals near the user's threshold should shrink gently. The current algorithm treats both the same.

**Evaluation Approach:**
A separate `KazezNoteStrategy` was implemented (see `hotfix-kazez-evaluation-strategy.md`) to validate the Kazez convergence formulas (`N = P × [1 - 0.05 × sqrt(P)]`) which use `sqrt(P)` scaling for proportional convergence. This reaches the 5-cent range in ~10 correct answers.

**Status:** Kazez formulas validated via manual testing. Integration story created.

**Next Step:**
Implement `hotfix-integrate-kazez-into-adaptive-strategy.md` — replace fixed factors in `AdaptiveNoteStrategy.determineCentDifference()` with Kazez sqrt(P) formulas, preserving per-note tracking. Restore `AdaptiveNoteStrategy` as active strategy in `PeachApp`.

**Related Code:**
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — `DifficultyParameters.narrowingFactor` / `wideningFactor`
- `Peach/Core/Algorithm/KazezNoteStrategy.swift` — evaluation implementation
- `docs/implementation-artifacts/hotfix-kazez-evaluation-strategy.md` — story document

### Weighted Effective Difficulty: Convergence Still Too Slow

**Priority:** Critical
**Category:** Algorithm Design
**Date Added:** 2026-02-15

**Issue:**
After implementing weighted effective difficulty (neighbor-based bootstrapping), manual testing on device shows the algorithm still cannot reach the 3–10 cent range within 10 comparisons on a cold start. After ~100 correct answers, difficulty remains above 20 cents. The user's target is 3–10 cents within 10 comparisons.

**Current State (as implemented):**
- `weightedEffectiveDifficulty` borrows from up to 5 nearest trained neighbors in each direction, weighted by `1/(1+distance)`
- Kazez formula: `N = P × (1 - 0.05 × √P)` for correct, `N = P × (1 + 0.09 × √P)` for incorrect
- Kazez input uses raw `currentDifficulty` for notes that have been Kazez-updated, weighted difficulty only for first encounter (bootstrapping)

**Root Causes Identified:**

1. **Kazez narrowing coefficient (0.05) is too conservative for multi-note convergence.** On a single note, 10 correct answers from 100 cents reaches ~6 cents. But with a 48-note range (36–84), comparisons are spread across many notes — each note gets ~2 of 100 comparisons, barely converging. Increasing to **0.08** would give: 100 → 20 → 12.8 → 9.1 → 6.9 → 5.5 (5 steps on a single note), making bootstrapping far more effective since early-trained notes converge faster and new notes inherit lower starting points.

2. **Unrefined notes anchor weighted averages at 100 cents.** The first note in every session gets `profile.update()` (sampleCount=1) but never Kazez-refined (nil `lastComparison`). Its `currentDifficulty` stays at 100.0. The neighbor search includes any note with `sampleCount > 0`, so this 100-cent anchor pulls up weighted averages for all nearby untrained notes. **Fix:** neighbors should require `currentDifficulty != DifficultyParameters.defaultDifficulty` in addition to `sampleCount > 0`, ensuring only Kazez-refined notes contribute to bootstrapping.

**Proposed Changes:**

File: `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift`

1. Change Kazez correct-answer coefficient from `0.05` to `0.08`:
   ```swift
   // Line 215, in determineCentDifference:
   ? max(p * (1.0 - 0.08 * p.squareRoot()),   // was 0.05
   ```

2. Add `!= defaultDifficulty` guard to neighbor collection (lines 256, 267):
   ```swift
   if stats.sampleCount > 0
       && stats.currentDifficulty != DifficultyParameters.defaultDifficulty {
   ```

**Expected Convergence With Both Fixes (cold start, all correct):**
- Comp 1: Note A presented at 100 (nil lastComparison, no Kazez)
- Comp 2: Note B → weighted=100 (no refined neighbors yet) → Kazez: 100×0.2=20 → stored
- Comp 3: Note C → bootstraps from B(20) → Kazez: 20→12.8 → stored
- Comp 4: Note D → bootstraps from B(20),C(12.8) → weighted≈15 → Kazez: 15→10.2
- Comp 5: Note E → bootstraps≈12 → Kazez: 12→8.5
- Comp 6–10: Presented difficulties in 5–10 cent range

**Tests That Need Updating:**
- `regionalDifficultyNarrowsOnCorrect`: expects 50.0, should become 20.0
- `difficultyNarrowsAcrossJumps`: expects 50.0, should become 20.0
- `kazezConvergenceFromDefault`: expects <10 after 10 correct — will pass (converges faster)
- Other Kazez-related tests: verify expectations still hold with 0.08 coefficient
- `weightedDifficultyKernelNarrowing`: neighbor condition change may affect setup — verify

**Related Code:**
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — `determineCentDifference()`, `weightedEffectiveDifficulty()`
- `PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift` — Kazez convergence tests

---

## Technical Debt

*(Items from story development will be added here during retrospectives)*

---

## Future Enhancements

*(Deferred features and nice-to-haves will be tracked here)*
