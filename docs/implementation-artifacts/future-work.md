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

### Investigate Whether Seamless Playback Makes Pitch Comparison Easier

**Priority:** Medium
**Category:** Algorithm Design / Calibration
**Date Added:** 2026-02-17

**Observation:**
After implementing chain-based Kazez convergence, the algorithm quickly converges to sub-2-cent differences. However, the user consistently achieves much finer discrimination in Peach than in InTune (a reference app), where they typically plateau around 5 cents and only occasionally reach below 3 cents.

**Hypothesis:**
Peach plays the two comparison tones seamlessly (back-to-back without a gap), which may make pitch differences perceptually easier to detect than when tones are separated by silence. This could mean the difficulty levels in Peach are not directly comparable to those in apps that use gaps between tones.

**Impact:**
- Peach's difficulty numbers may overstate the user's actual pitch discrimination ability
- Comparison with other ear training apps may be misleading
- The training may be less effective if the task is artificially easier

**Investigation Areas:**
- Compare perceptual difficulty of seamless vs. gap-separated tone pairs at the same cent difference
- Research psychoacoustic literature on the effect of inter-stimulus intervals on pitch discrimination
- Consider adding a configurable gap between tones as an advanced setting
- Evaluate whether the current approach is still valuable for training (even if "easier")

**Related Code:**
- `Peach/Core/Audio/SineWaveNotePlayer.swift` — tone generation and playback
- `Peach/Training/TrainingSession.swift` — playback sequencing

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

### Extract Environment Keys to Shared Locations

**Priority:** Low
**Category:** Code Organization
**Date Added:** 2026-02-17
**Source:** Story 6.1 code review (finding L1)

**Issue:**
`PerceptualProfileKey` and its `EnvironmentValues` extension are defined in `Peach/Profile/ProfileScreen.swift` (lines 131-149), but `@Environment(\.perceptualProfile)` is used across multiple features: Settings, Start, and Profile. This couples unrelated feature modules to a specific View file for infrastructure plumbing.

**Impact:**
- `SettingsScreen` implicitly depends on `ProfileScreen.swift` for the environment key definition
- `ProfilePreviewView` (Start feature) has the same hidden dependency
- If `ProfileScreen.swift` were ever moved or split, the environment key would need to be relocated

**Proposed Fix:**
Move environment key definitions next to their corresponding types:
- `PerceptualProfileKey` → `Peach/Core/Profile/PerceptualProfile.swift` (alongside the class, matching the `TrendAnalyzerKey` pattern in `TrendAnalyzer.swift`)

**Related Code:**
- `Peach/Profile/ProfileScreen.swift:131-149` — current location of `PerceptualProfileKey`
- `Peach/Core/Profile/TrendAnalyzer.swift:92-108` — reference pattern (key defined alongside type)
- `Peach/Settings/SettingsScreen.swift:24` — consumer of `\.perceptualProfile`
- `Peach/Start/ProfilePreviewView.swift:7` — consumer of `\.perceptualProfile`

---

## Future Enhancements

*(Deferred features and nice-to-haves will be tracked here)*
