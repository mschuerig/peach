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

### Audio Clicks When Navigating Away During Playback

**Priority:** Medium
**Category:** Bug / Audio
**Date Added:** 2026-02-18

**Issue:**
When the user navigates to another screen (e.g., Settings, Profile) while a note is still playing, audible clicks/pops occur. This happens because `TrainingSession.stop()` calls `playerNode.stop()` which abruptly truncates the audio buffer without a fade-out, causing a discontinuity in the waveform.

**Root Cause:**
`TrainingScreen.onDisappear` calls `trainingSession.stop()`, which calls `notePlayer.stop()` → `playerNode.stop()`. The `AVAudioPlayerNode.stop()` method immediately stops playback at the current sample position. If the waveform is not at a zero crossing, this creates an audible click/pop.

**Potential Solutions:**
- Implement a rapid fade-out (e.g., 5-10ms ramp to zero) before stopping the player node
- Schedule a very short silence buffer after stop to allow the waveform to reach zero
- Use `playerNode.pause()` + volume ramp instead of immediate `stop()`
- Apply a real-time volume ramp on the mixer node before stopping

**Related Code:**
- `Peach/Core/Audio/SineWaveNotePlayer.swift:117-122` — `stop()` method
- `Peach/Training/TrainingSession.swift:280-283` — stop triggers `notePlayer.stop()`
- `Peach/Training/TrainingScreen.swift:67-69` — `onDisappear` triggers `stop()`

### Reset All Data Should Also Reset Difficulty

**Priority:** Medium
**Category:** Bug / Consistency
**Date Added:** 2026-02-18

**Issue:**
When the user taps "Reset All Training Data" in Settings, the `ComparisonRecord`s are deleted and the `PerceptualProfile` and `TrendAnalyzer` are reset. However, the `TrainingSession.lastCompletedComparison` (which drives the Kazez convergence chain) is not reset. If training is started again after a reset, the algorithm may continue from the previous difficulty level instead of starting fresh from 100 cents.

**Impact:**
- After resetting, the user expects a completely fresh start
- The convergence chain continuing from the previous difficulty level contradicts this expectation
- This is related to the broader "convergence chain not persisted" issue, but in the opposite direction — here the chain *should* be cleared but isn't

**Potential Solutions:**
- Expose a `reset()` method on `TrainingSession` or `AdaptiveNoteStrategy` that clears `lastCompletedComparison`
- Have the Settings reset action notify the training session (via observer pattern or environment)
- Clear the chain state whenever the profile is reset

**Related Code:**
- `Peach/Settings/SettingsScreen.swift:123-134` — `resetAllTrainingData()` function
- `Peach/Training/TrainingSession.swift:139` — `lastCompletedComparison` property
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — uses `lastComparison` parameter

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

### Consider Rolling Window for Profile Data

**Priority:** Medium
**Category:** Algorithm Design
**Date Added:** 2026-02-18

**Issue:**
The `PerceptualProfile` currently accumulates all historical `ComparisonRecord`s with equal weight using Welford's online algorithm. As a user improves over weeks/months, old data from when they were less skilled continues to drag the profile statistics. The profile may not reflect the user's *current* ability.

**Potential Approaches:**
- Only consider the last N comparisons per note (e.g., N=20 or N=100) when computing mean and stdDev
- Use exponential decay weighting so recent results count more
- The algorithm (`AdaptiveNoteStrategy`) should also respect this window — difficulty should reflect current ability, not lifetime average

**Impact:**
- Profile statistics would more accurately represent current skill level
- Weak spot identification would be more responsive to recent training
- Would require changes to `PerceptualProfile` (currently uses incremental Welford's, which doesn't support windowing without storing raw values)
- May need to store recent comparisons per note or switch to a different statistical approach

**Related Code:**
- `Peach/Core/Profile/PerceptualProfile.swift` — Welford's algorithm, `weakSpots()`
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — uses profile for difficulty selection
- `Peach/Core/Data/ComparisonRecord.swift` — stored records

### Convergence Chain State Not Persisted Across App Restarts

**Priority:** Medium
**Category:** State Management
**Date Added:** 2026-02-18

**Issue:**
The Kazez convergence chain (the current difficulty level / last cent offset) is not persisted. When the app restarts, `TrainingSession` has no `lastComparison`, so the difficulty resets. The `PerceptualProfile` rebuilds from stored `ComparisonRecord`s and bootstraps via neighbor-weighted difficulty, but the actual position in the convergence chain is lost.

**Impact:**
- Returning users experience an abrupt jump back to wider intervals on every app launch
- Serious users who train daily will find this jarring and disruptive to their flow
- The adaptive algorithm effectively restarts its convergence each session, wasting early comparisons re-converging to the user's actual level

**Potential Solutions:**
- Persist `lastComparison` (or just the last cent offset) to UserDefaults or SwiftData
- On launch, seed the chain from the persisted value instead of bootstrapping from scratch
- Consider whether the profile's bootstrapped difficulty is "close enough" or whether exact chain continuity matters

**Related Code:**
- `Peach/Training/TrainingSession.swift` — `lastComparison` property
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` — `nextComparison()` cold start path
- `Peach/Core/Profile/PerceptualProfile.swift` — neighbor-weighted bootstrapping

---

## UX & Onboarding

### No First-Run Onboarding Experience

**Priority:** High
**Category:** User Experience
**Date Added:** 2026-02-18

**Issue:**
There is no guided onboarding for new users. A musician downloading Peach sees the Start Screen with an empty profile preview and can tap "Start Training" — but nothing explains what will happen, what the controls mean, or what "cents" are in the context of pitch discrimination.

**Impact:**
- Musicians may not understand the task format (two sequential tones, tap Higher/Lower)
- The concept of "cents" as a unit of pitch difference is unfamiliar to many musicians who think in terms of "sharp/flat" or "in tune/out of tune"
- The profile visualization (confidence band, log scale) is meaningless without context
- Risk of immediate abandonment if the first experience feels confusing

**Potential Solutions:**
- A brief first-run walkthrough (2-3 screens) explaining the training concept
- Contextual tooltips on first use of each screen
- Musician-friendly language throughout ("pitch accuracy" instead of "cent threshold")
- An introductory training round with wider intervals and explanatory overlays

### Redesign Profile Graph for Interpretability

**Priority:** High
**Category:** User Experience
**Date Added:** 2026-02-18

**Issue:**
The Profile Screen's confidence band chart (piano keyboard + AreaMark with log-scale Y-axis showing cent thresholds and standard deviations) is not helpful even for the developer. The visualization is technically accurate but practically uninterpretable — users cannot derive meaningful insight about their pitch discrimination ability from looking at it.

**Impact:**
- The profile is the primary way users understand their progress, and it currently fails at this job
- Musicians will not understand what the confidence band represents
- Log-scale Y-axis is unintuitive for non-technical users
- No translation of data into actionable musical feedback
- The summary statistics (mean, stdDev, trend) use technical terminology

**Potential Solutions:**
- Rethink the visualization from scratch — what do users actually want to know?
- Consider bar chart per note (simpler), heat map, or qualitative ratings
- Use musical note names prominently
- Provide plain-language interpretive text ("You can hear differences of X cents around these notes")
- Consider a simplified default view with an optional detailed/advanced view

**Related Code:**
- `Peach/Profile/ProfileScreen.swift` — current visualization
- `Peach/Profile/ConfidenceBandView.swift` — Swift Charts AreaMark implementation
- `Peach/Profile/PianoKeyboardView.swift` — Canvas-rendered keyboard

### Tap-to-Inspect Note Detail on Profile Graph

**Priority:** Medium
**Category:** User Experience
**Date Added:** 2026-02-18

**Issue:**
There is no way to get detailed information about a specific note's training data. When looking at the profile graph, the user should be able to tap on a point/note to see detailed statistics for that particular note.

**Desired Behavior:**
- Tap on a note in the profile visualization to see a detail view or popover
- Show per-note statistics: number of comparisons, mean threshold, standard deviation, trend, recent history
- Translate into musician-friendly language where possible

**Related Code:**
- `Peach/Profile/ProfileScreen.swift` — profile UI
- `Peach/Core/Profile/PerceptualProfile.swift` — per-note `NoteProfile` data (mean, stdDev, count)

### Show Progress Over Time

**Priority:** Medium
**Category:** User Experience
**Date Added:** 2026-02-18

**Issue:**
There is no way to see how pitch discrimination ability has improved (or declined) over time. The `TrendAnalyzer` computes a simple improving/stable/declining trend from bisecting historical records, but there is no temporal visualization — no chart showing threshold convergence across days/weeks, no profile snapshots, no historical comparison.

This was identified as a Phase 2 feature in the original PRD brainstorming but has not been designed or implemented.

**Desired Behavior:**
- A view (accessible from the Profile screen or Start screen) that shows improvement over time
- Could be a line chart of average threshold per day/week
- Could show per-note improvement trajectories
- Should answer the user's question: "Am I getting better?"

**Related Code:**
- `Peach/Core/Data/ComparisonRecord.swift` — has `timestamp` field for temporal queries
- `Peach/Core/Profile/TrendAnalyzer.swift` — existing trend computation (bisection approach)
- `Peach/Profile/ProfileScreen.swift` — likely home for temporal visualization

### No Sense of Session or Progress Acknowledgment

**Priority:** Medium
**Category:** User Experience
**Date Added:** 2026-02-18

**Issue:**
The training loop runs indefinitely with no session boundaries, progress milestones, or acknowledgment of effort. While the "training, not testing" philosophy deliberately avoids gamification, there is currently no feedback at all about training duration, improvement over time, or encouragement to return.

**Impact:**
- Users have no sense of how long they've trained or whether it's "enough"
- No motivation loop to encourage daily practice habits
- The TrendAnalyzer computes improving/stable/declining trends but this data is only visible if the user navigates to the Profile screen
- Missed opportunity to reinforce the value of consistent practice

**Potential Solutions:**
- Subtle session summary when the user stops training ("You trained for 5 minutes, completed 47 comparisons")
- Periodic gentle progress nudges surfaced on the Start Screen ("Your accuracy improved 12% this week")
- Optional daily practice reminders (notifications)
- Keep it minimal and informational — acknowledge effort without gamifying it

### Display Current Difficulty on Training Screen

**Priority:** Medium
**Category:** User Experience
**Date Added:** 2026-02-18

**Issue:**
During training, the user has no visibility into what difficulty level (cent difference) they are currently training at. There is no indication of whether they are being challenged at 50 cents, 10 cents, or 2 cents. Additionally, there is no way to see the highest difficulty (smallest cent difference) achieved within the current training session.

**Desired Behavior:**
- Show the current cent difference somewhere on the Training Screen (possibly optional/toggleable)
- Optionally show a "session best" (smallest cent difference achieved correctly in this session)
- Should not distract from the core Higher/Lower interaction
- Consider showing this as a small, unobtrusive label or in a toolbar area

**Related Code:**
- `Peach/Training/TrainingScreen.swift` — training UI
- `Peach/Training/TrainingSession.swift` — `currentComparison` has the cent difference
- `Peach/Training/Comparison.swift` — `centDifference` property

### Feedback Icon Flicker on Correctness Change

**Priority:** Medium
**Category:** Bug
**Date Added:** 2026-02-18

**Issue:**
When the correctness of consecutive answers differs (e.g., previous answer was correct, current answer is wrong), the feedback indicator briefly flickers showing the *previous* icon before switching to the *current* one. Specifically: if the last answer showed thumbs-up (correct) and the new answer is wrong, the thumbs-up briefly appears before the thumbs-down replaces it.

**Root Cause Analysis:**
In `TrainingSession.handleAnswer()`, the sequence is:
1. `isLastAnswerCorrect = completed.isCorrect` (updates the icon)
2. `showFeedback = true` (makes the icon visible)

But in the training loop, `showFeedback` is set to `false` at the end of the feedback duration (line 261), and then `playNextComparison()` runs. After the user answers the *next* comparison, `isLastAnswerCorrect` is updated first (line 249), but at this point `showFeedback` is still `false` from the previous cycle, so when `showFeedback` becomes `true` (line 250), the icon has already been set — however, the `.animation()` modifier on the opacity transition causes the *old* icon content to flash briefly during the opacity fade-in because SwiftUI animates both the opacity and the content change.

**Potential Solutions:**
- Set `isLastAnswerCorrect = nil` when hiding feedback (clear the icon content, not just opacity)
- Use a `.transition()` instead of `.opacity()` animation to avoid showing stale content
- Disable animation on the icon content change, only animate the opacity
- Use `.id(isLastAnswerCorrect)` to force SwiftUI to replace the view rather than animate it

**Related Code:**
- `Peach/Training/TrainingSession.swift:249-261` — feedback state management
- `Peach/Training/TrainingScreen.swift:37-43` — feedback overlay with `.opacity()` and `.animation()`
- `Peach/Training/FeedbackIndicator.swift` — icon rendering

### Haptic Feedback Unavailable on iPad

**Priority:** Low
**Category:** User Experience / Platform
**Date Added:** 2026-02-18

**Issue:**
Wrong-answer feedback uses `UIImpactFeedbackGenerator` for haptic response. iPads do not have a Taptic Engine, so this feedback channel is completely absent on iPad.

**Impact:**
- iPad users receive only the visual feedback indicator for wrong answers — no tactile reinforcement
- The feedback experience is inconsistent across device types
- May reduce the effectiveness of the training feedback loop on iPad

**Potential Solutions:**
- Add a subtle visual reinforcement (e.g., screen flash, shake animation) as a complement to haptics
- Consider an optional audio feedback cue (short error tone) that works on all devices
- Respect the "Reduce Motion" accessibility setting for any visual alternatives
- Detect haptic capability and adapt feedback strategy accordingly

**Related Code:**
- `Peach/Training/HapticFeedbackManager.swift` — haptic implementation
- `Peach/Training/FeedbackIndicator.swift` — visual feedback

---

## Future Enhancements

### Swappable Sound Sources (Instrument Timbres)

**Priority:** Medium
**Category:** Audio / Training Effectiveness
**Date Added:** 2026-02-18

**Issue:**
The app currently uses only sine wave tones for pitch comparisons. While precise and deterministic, sine waves lack the harmonic content of real instruments. Musicians train their ears on timbres — a violinist needs to hear pitch differences in violin-like tones, not pure sine waves.

**Impact:**
- Training with sine waves may not transfer fully to real instrument contexts
- The app feels clinical rather than musical to the target audience
- Limits the app's credibility and usefulness for serious musicians

**Potential Solutions:**
- The `NotePlayer` protocol already supports swappable implementations
- Add sampled instrument sound sources (piano, strings, woodwinds, brass)
- Start with a single high-quality piano sample as an alternative to sine waves
- Allow users to select their preferred sound source in Settings (the UI slot already exists)

**Related Code:**
- `Peach/Core/Audio/NotePlayer.swift` — protocol definition
- `Peach/Core/Audio/SineWaveNotePlayer.swift` — current implementation
- `Peach/Settings/SettingsScreen.swift` — sound source setting (currently sine-only)

*(Additional deferred features and nice-to-haves will be tracked here)*
