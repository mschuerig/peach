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

### ~~AdaptiveNoteStrategy: Slow Difficulty Convergence~~ (RESOLVED)

**Status:** Resolved — 2026-02-15
**Resolution:** Kazez sqrt(P) formulas integrated into `AdaptiveNoteStrategy` via `hotfix-integrate-kazez-into-adaptive-strategy.md`. Fixed factors replaced with `N = P × [1 - 0.05 × √P]` (correct) and `N = P × [1 + 0.09 × √P]` (incorrect).

### ~~Weighted Effective Difficulty: Convergence Still Too Slow~~ (RESOLVED)

**Status:** Resolved — 2026-02-17
**Resolution:** Implemented via `hotfix-tune-kazez-convergence.md`:
1. Kazez correct-answer coefficient increased from 0.05 to 0.08 — single correct from 100 cents now gives 20.0 (was 50.0)
2. Neighbor filtering: only Kazez-refined notes (`currentDifficulty != defaultDifficulty`) contribute to bootstrapping, preventing 100-cent anchoring

---

## Technical Debt

*(Items from story development will be added here during retrospectives)*

---

## Future Enhancements

*(Deferred features and nice-to-haves will be tracked here)*
