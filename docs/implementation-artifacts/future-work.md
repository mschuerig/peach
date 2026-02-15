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

**Future Resolution:**
Once the Kazez formulas are validated via manual testing, integrate the `sqrt(P)` scaling approach into `AdaptiveNoteStrategy`'s per-note difficulty tracking. The per-note architecture should be preserved — only the narrowing/widening math needs to change.

**Related Code:**
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — `DifficultyParameters.narrowingFactor` / `wideningFactor`
- `Peach/Core/Algorithm/KazezNoteStrategy.swift` — evaluation implementation
- `docs/implementation-artifacts/hotfix-kazez-evaluation-strategy.md` — story document

---

## Technical Debt

*(Items from story development will be added here during retrospectives)*

---

## Future Enhancements

*(Deferred features and nice-to-haves will be tracked here)*
