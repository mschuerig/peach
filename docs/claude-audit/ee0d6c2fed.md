---
commit: "ee0d6c2fed9e5f3207c2c8160a51ea408dd6b379"
date: "2026-02-15T13:45:04+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Document convergence findings: Kazez coefficient too slow, neighbor anchoring"
sessions: ["8b40f40e-4bc8-4fef-b2c9-f9cf458a6112"]
prev: "a225a9fcf1.md"
next: "679cf6316a.md"
---

[← Previous (a225a9fcf1)](a225a9fcf1.md) | [Index](index.md) | [Next (679cf6316a) →](679cf6316a.md)

# Commit ee0d6c2fed

**Date:** 2026-02-15 13:45:04 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Document convergence findings: Kazez coefficient too slow, neighbor anchoring

Manual testing shows weighted difficulty alone is insufficient — 100
comparisons still above 20 cents. Root causes identified:
1. Kazez narrowing coefficient 0.05 too conservative for multi-note ranges
2. Unrefined notes (sampleCount>0, currentDifficulty==100) anchor neighbors

Proposed fix: increase coefficient to 0.08 and filter unrefined neighbors.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
docs/implementation-artifacts/future-work.md | 55 ++++++++++++++++++++++++++++
 1 file changed, 55 insertions(+)
```

## Session `8b40f40e…`

*2026-02-15 11:53:59 UTC → 2026-02-15 12:45:11 UTC*

### 🧑 Human (11:53:59)

Implement the following plan:

# Story: Weighted Effective Difficulty for Faster Convergence

Status: draft

## Context

The `AdaptiveNoteStrategy` currently reads each note's `currentDifficulty` in isolation from the `PerceptualProfile`. Untrained notes start at 100 cents and require ~10 correct answers each to converge. Across a 48-note training range, this means hundreds of comparisons before the system understands the user's ability. Since pitch discrimination doesn't vary sharply between adjacent semitones, we can **borrow evidence from trained neighbors** to bootstrap untrained notes — dramatically accelerating early convergence.

## Story

As a **musician using Peach**,
I want the adaptive algorithm to use nearby note data to estimate difficulty for untrained notes,
So that training converges faster to my actual skill level across the full note range.

## Acceptance Criteria

1. **Given** an untrained note with trained neighbors, **When** difficulty is determined, **Then** it uses a weighted average of up to 5 nearest trained notes in each direction, weighted by `1 / (1 + distance)`

2. **Given** a trained note (sampleCount > 0), **When** difficulty is determined, **Then** its own raw difficulty is included at distance 0 (maximum weight) and dominates the estimate

3. **Given** no trained notes anywhere in range, **When** difficulty is determined, **Then** it defaults to 100.0 cents

4. **Given** a note at the edge of the training range, **When** neighbors are collected, **Then** it correctly handles asymmetric neighbor availability (fewer neighbors on one side)

5. **Given** the weighted effective difficulty, **When** the Kazez formula is applied after a comparison, **Then** the input to Kazez is the weighted effective difficulty, and the result is stored as the note's raw `currentDifficulty`

6. **Given** weak spot identification, **When** selecting notes for mechanical training, **Then** weak spots still use raw per-note data (unchanged)

7. **Given** all existing tests, **When** the full test suite is run, **Then** all tests pass (updated expectations where needed)

## Tasks / Subtasks

### Task 1: Add `weightedEffectiveDifficulty` method to `AdaptiveNoteStrategy`

**File:** `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift`

Add a private method:

```swift
private func weightedEffectiveDifficulty(
    for note: Int,
    profile: PerceptualProfile,
    settings: TrainingSettings
) -> Double
```

Algorithm:
1. Collect all notes in `settings.noteRangeMin...settings.noteRangeMax` where `profile.statsForNote(i).sampleCount > 0`
2. Include current note `n` in candidates only if `sampleCount > 0`
3. From candidates where `i < n`, take closest 5 (sorted by ascending distance)
4. From candidates where `i > n`, take closest 5 (sorted by ascending distance)
5. Combine: current note (if trained) + left neighbors + right neighbors
6. If no candidates → return `DifficultyParameters.defaultDifficulty` (100.0)
7. Weight each: `w(i) = 1.0 / (1.0 + Double(abs(n - i)))`
8. Return `Σ w(i) × difficulty(i) / Σ w(i)`

### Task 2: Update `determineCentDifference` to use weighted difficulty

**File:** `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift`

Change the method to:
- Use `weightedEffectiveDifficulty(for:profile:settings:)` instead of `profile.statsForNote(note).currentDifficulty`
- The weighted value feeds into both:
  - The no-lastComparison path (first comparison for this note)
  - The Kazez formula input (`p` = weighted effective difficulty)
- The Kazez output is still stored via `profile.setDifficulty(note:difficulty:)` as the raw value

### Task 3: Add `maxNeighbors` constant to `DifficultyParameters`

**File:** `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift`

```swift
static let maxNeighbors: Int = 5
```

### Task 4: Update existing tests and add new tests

**File:** `PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift`

**Tests to update:**
- `untrainedNoteUsesDefault` — still expects 100.0 (no data anywhere → default). No change needed.
- `perNoteIndependentDifficulties` — note 72 now picks up neighbor data from trained note 60 (distance 12). The weighted effective difficulty won't be 100.0 anymore. Update expectation: note 72's difficulty should be less than 100.0 (influenced by trained note 60).
- `difficultyNarrowsAcrossJumps` — note 84 after training note 36 at distance 48: only 5 nearest neighbors, and note 36 is likely the only one (distance 48). Weight = `1/(1+48) ≈ 0.02`. Since it's the only data point, the weighted average = note 36's difficulty regardless of weight. Update expectation: note 84 won't be 50.0, it will be whatever note 36's post-Kazez difficulty is (50.0 from the first correct at 100). Actually since note 36 is the only trained note within the 5-nearest search... note 36 is within the range [36,84], so yes it's a valid neighbor at distance 48. The weighted average of a single point is that point's value = 50.0. So this test may still pass. Need to verify.

**New tests to add:**
- `weightedDifficultyNoDataReturnsDefault` — empty profile → 100.0
- `weightedDifficultyCurrentNoteOnlyReturnsOwnDifficulty` — single trained note, query that note → its raw difficulty
- `weightedDifficultyNeighborsOnly` — untrained note with trained neighbors → weighted average of neighbors
- `weightedDifficultyCurrentNoteDominates` — trained note with neighbors → own difficulty dominates via distance-0 weight
- `weightedDifficultyKernelNarrowing` — sparse data = wide reach, dense data = local (verify 5-nearest behavior)
- `weightedDifficultyBoundaryNote` — note at range edge with asymmetric neighbors

## Dev Notes

### What Changes
- `AdaptiveNoteStrategy.swift`: Add `weightedEffectiveDifficulty` method, update `determineCentDifference` to use it, add `maxNeighbors` constant
- `AdaptiveNoteStrategyTests.swift`: Update affected tests, add new weighted difficulty tests

### What Does NOT Change
- `PerceptualProfile` — stores raw values only, no changes
- `NextNoteStrategy` protocol — interface unchanged
- `TrainingSettings` — no new settings needed
- Weak spot logic — remains based on raw data
- `KazezNoteStrategy` — reference implementation, untouched

### Key Design Decisions
- **Write raw, read weighted**: Profile stores raw per-note difficulty. Weighted aggregation computed on the fly in the strategy.
- **k-nearest neighbors**: Up to 5 trained notes in each direction. Naturally adaptive bandwidth — wide when sparse, narrow when dense.
- **Weighting**: `1 / (1 + distance)` in semitones. Simple, no hyperparameters beyond neighbor count.
- **Cold start**: No data → 100.0 cents (unchanged default).

## Verification

1. Run full test suite: `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
2. All existing tests pass (with updated expectations where needed)
3. All new weighted difficulty tests pass

## File List

- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` (modified)
- `PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift` (modified)


If you need specific details from before exiting plan mode (like exact code snippets, error messages, or content you generated), read the full transcript at: /Users/michael/.claude/projects/-Users-michael-Projekte-peach/2d9ebfd9-b4da-4ba6-b60b-41a13b618cca.jsonl

### 🤖 Assistant (11:54:06)

Let me also check the PerceptualProfile and TrainingSettings to understand the interfaces.

### 🤖 Assistant (11:54:26)

Now I have all the context. Let me implement the changes.

### 🤖 Assistant (11:54:42)

Now add the `weightedEffectiveDifficulty` method before the `clamp` method:

### 🤖 Assistant (11:54:55)

The diagnostics are just SourceKit indexing issues, not real errors. Now update `determineCentDifference`:

### 🤖 Assistant (11:55:06)

Now update the tests. First, let me re-read the modified strategy file to verify correctness:

### 🤖 Assistant (11:55:17)

Good, the implementation looks correct. Now let me update the tests. I need to think about which tests need updating:

1. **`perNoteIndependentDifficulties`** — note 72 with range `[72,72]` and note 60 trained: note 60 is outside the range `[72,72]`, so it won't be found as a neighbor. Wait, let me re-read... The range is `settings.noteRangeMin...settings.noteRangeMax`. The test uses `TrainingSettings(noteRangeMin: 72, noteRangeMax: 72)`. So the search for neighbors only looks within `[72,72]`, and note 60 is outside. So this test should still pass as-is.

2. **`difficultyNarrowsAcrossJumps`** — note 84 with range `[84,84]`: neighbor search within `[84,84]`, note 36 is outside. Should still pass.

3. **`statelessStrategyConsistency`** — sets difficulty for note 60 to 42.0 via `setDifficulty` but doesn't `update` (sampleCount stays 0). With weighted difficulty, since sampleCount is 0, it won't pick up the raw difficulty. This test will break! The weighted method checks `sampleCount > 0`, but `setDifficulty` alone doesn't increment sampleCount.

Let me check what `setDifficulty` does vs `update`:

### 🤖 Assistant (11:55:34)

I see that `setDifficulty` doesn't increment `sampleCount`, so some tests that use only `setDifficulty` (without `update`) will break because `weightedEffectiveDifficulty` checks `sampleCount > 0`. I need to fix: `statelessStrategyConsistency`, `difficultyRespectsFloor`, and `difficultyRespectsCeiling`.

### 🤖 Assistant (11:55:48)

Now update the `perNoteIndependentDifficulties` test. Note 72 with range `[72,72]` won't see note 60 as a neighbor since it's outside the range. But wait — the test trains note 60 with 5 correct answers. After those iterations, `setDifficulty` is called on note 60 multiple times. Then it queries note 72 with range `[72,72]`. Since the search range is `[72,72]`, no neighbors will be found, so it defaults to 100.0. This test should still pass as-is.

Now let me add the new tests at the end of the file:

### 🤖 Assistant (11:56:00)

Now add the 6 new tests at the end of the file:

### 🤖 Assistant (11:57:08)

The tests I added have some messy code. Let me clean them up:

### 🤖 Assistant (12:00:21)

Let me read the current state of the test file to get exact strings:

### 🤖 Assistant (12:00:25)

Now I'll rewrite the messy tests cleanly. Let me replace the entire weighted difficulty section:

### 🤖 Assistant (12:01:39)

Now I need to think about the `difficultyNarrowsAcrossJumps` test more carefully. It uses `fixedSettings84 = TrainingSettings(noteRangeMin: 84, noteRangeMax: 84)`. Note 36 was trained via `setDifficulty` in the Kazez path (line 214 of the strategy). But note 36 is outside the range `[84,84]`, so the weighted search won't find it. Note 84 is untrained (sampleCount=0), so weighted difficulty returns 100.0. Then Kazez narrows from 100 → 50. The test expects 50.0, so it should still pass.

Wait, but there's a subtlety. The first comparison at note 36 with `fixedSettings36` doesn't have a `lastComparison`, so it just returns the weighted difficulty (100.0, since no data). It doesn't call `setDifficulty`. Then the second call with `fixedSettings84` and `completed1` (correct answer) uses `weightedEffectiveDifficulty` for note 84. Note 84 has sampleCount=0, and range is [84,84], so no neighbors. Returns 100.0. Then Kazez: `100 * (1 - 0.05 * 10) = 50.0`. And stores 50.0 via `setDifficulty`. Test expects 50.0. Good.

Now let me also check the `regionalDifficultyNarrowsOnCorrect` test. First comparison at note 60, no lastComparison → weighted difficulty = 100.0 (untrained, no neighbors in [60,60]). Returns 100. Then second call with correct answer → weighted difficulty for note 60... but after the first call, was `setDifficulty` called? No, because `lastComparison` was nil, so the `guard` returned early without calling `setDifficulty`. So note 60 still has sampleCount=0, currentDifficulty=100.0. The second call has lastComparison set, so it goes through Kazez. `weightedEffectiveDifficulty` for note 60 = 100.0 (untrained, no neighbors). Kazez: `100 * (1 - 0.05 * 10) = 50`. Stores 50 via `setDifficulty`. Returns 50. Test expects 50.0. Good.

Now let me run the tests:

### 🤖 Assistant (12:02:55)

Tests failed. Let me see what failed:

### 🤖 Assistant (12:03:58)

Two failures. Let me check the details:

### 🤖 Assistant (12:09:58)

Let me look at the xcresult for detailed errors:

### 🤖 Assistant (12:11:30)

I don't see the actual error messages. Let me think about what's going wrong:

**`kazezConvergenceFromDefault`**: This test uses `noteRangeMin: 60, noteRangeMax: 60` and simulates 10 correct answers. The problem is: after each Kazez step, `setDifficulty` stores the new value. But on the next iteration, `weightedEffectiveDifficulty` checks `sampleCount > 0`. The `setDifficulty` doesn't increment `sampleCount` — only `update` does. So note 60 always has `sampleCount == 0`, and weighted difficulty returns 100.0 every time. The Kazez formula always narrows from 100→50, never converging further!

**`weightedDifficultyKernelNarrowing`**: Uses `profile.update` which increments `sampleCount`, then `setDifficulty`. Note 52 is at distance 8 from note 60, but note 53 is at distance 7. The 5 closest neighbors from below are 59(d=1), 58(d=2), 57(d=3), 56(d=4), 55(d=5). Note 54 at d=6 is excluded. But note 52 was trained at difficulty 10.0 while notes 53-59 are at 50.0. Since 52 is excluded, the weighted avg should be 50.0. Wait, but I also trained 53 at 50.0. Let me check: `for i in 53...59` trains notes 53,54,55,56,57,58,59 — that's 7 notes. Plus note 52 at 10.0. So 8 total below. The 5 nearest to note 60 are 59,58,57,56,55. All at 50.0. So weighted avg = 50.0. That should pass.

Wait, maybe the issue is that note 60 is at the edge of range [52,60]. In a range with many trained notes, weak spots would be note 60 (untrained). But the test uses 200 iterations... maybe it never selects note 60? With a range of [52,60], that's 9 notes, 8 of which are trained. The untrained notes would be weak spots. Only note 60 is untrained. So with `naturalVsMechanical: 0.5` (default), it should pick 60 fairly often. Unless `weakSpots` returns different results...

Actually, I think the problem might be different. The test expects `diff == 50.0` but the note selection might be modifying the profile state as it goes through the loop iterations (calling `setDifficulty` on other notes if lastComparison isn't nil). But `lastComparison: nil` means no Kazez adjustment, so no `setDifficulty` is called. Each iteration just returns the weighted difficulty. So it shouldn't mutate state. But wait — actually, `comp.note1` could be any note in range. If `lastComparison` is nil, the guard returns early without calling `setDifficulty`. So no mutations. Good.

Wait, maybe the issue is simpler — note 60 IS in the range but `stride(from: 59, through: 52, by: -1)` stops searching after 5 hits. Notes 59,58,57,56,55 are the 5 closest below note 60. But note 60's range upper bound is 60, so `stride(from: 61, through: 60, by: 1)` — this doesn't execute because 61 > 60. So no right neighbors. 5 left neighbors all at 50.0. Average = 50.0. This should work.

Hmm, let me reconsider the `kazezConvergenceFromDefault` issue. That's the real problem. The issue is that `weightedEffectiveDifficulty` checks `sampleCount > 0`, but `setDifficulty` (called by Kazez path) doesn't increment `sampleCount`. So the stored difficulty value is invisible to the weighted method.

The fix: I should check `currentDifficulty` differently, or also consider notes whose `currentDifficulty` has been modified (even if `sampleCount == 0`). But that breaks the design — `currentDifficulty` defaults to 100.0 for all notes, so checking it alone would treat all notes as "trained".

Actually, the right fix is simpler: after the Kazez formula stores the new difficulty, the next call to `weightedEffectiveDifficulty` should see it. The issue is that `setDifficulty` doesn't mark the note as trained. But conceptually, once the algorithm has set a difficulty for a note, that note IS trained for the purpose of the weighted calculation.

I think the cleanest solution is: in the `determineCentDifference` method, after calling `profile.setDifficulty`, also ensure the note's sampleCount reflects it's been worked on. But modifying `PerceptualProfile` would break the story's constraint that PerceptualProfile shouldn't change.

Alternative: in `weightedEffectiveDifficulty`, also include the current note if its `currentDifficulty != DifficultyParameters.defaultDifficulty` (i.e., it's been modified). But this is fragile — what if someone intentionally sets it to 100.0?

Better alternative: use `isTrained` OR check if `currentDifficulty` has been explicitly set. But there's no flag for that.

Actually, the simplest fix is: don't gate on `sampleCount > 0`. Instead, always include the current note's `currentDifficulty` at distance 0 (weight 1.0). For neighbors, still require `sampleCount > 0`. This way:
- Untrained notes always include their own `currentDifficulty` (100.0 default) at maximum weight
- Trained neighbors influence the result but don't override the note's own data
- After Kazez sets a difficulty, the next call picks it up

Wait, but then an untrained note with no neighbors would always return 100.0 (its own default), which is correct. An untrained note WITH neighbors would blend its 100.0 (weight 1.0) with neighbor data, which dilutes the neighbor influence. That's not what we want — we want untrained notes to borrow evidence from neighbors.

Let me reconsider. The real issue is: `setDifficulty` is the mechanism for storing Kazez output, but it doesn't mark the note as "trained" for the weighted calculation. The fix should be to track "has this note been actively trained by the algorithm" separately from "has the user completed a comparison for this note".

But wait, looking at the original code before my changes, `determineCentDifference` used `stats.currentDifficulty` directly. The `currentDifficulty` is always available (defaults to 100.0). The weighted method should also use `currentDifficulty` for the current note (distance 0), not gated by `sampleCount`. For neighbors, we should gate by `sampleCount > 0` to avoid pulling in default 100.0 from all neighbors.

This is the right approach:

### 🤖 Assistant (12:11:55)

Wait, but now the current note is always included, so the `guard !candidates.isEmpty` never triggers for the default case. And an untrained note with no neighbors would return its own 100.0. That's correct.

But for AC#1 — "uses a weighted average of up to 5 nearest trained notes in each direction" — an untrained note with trained neighbors would blend its own 100.0 (weight 1.0) with neighbor data. For example, if neighbors are at 40.0, the weighted average would be (1.0*100 + 0.5*40) / (1.0 + 0.5) = 120/1.5 = 80.0 instead of 40.0. That dilutes neighbor influence significantly.

Hmm, the story says AC#2: "a trained note (sampleCount > 0) — its own raw difficulty is included at distance 0 and dominates the estimate." This implies that for untrained notes (sampleCount == 0), own data should NOT be included at distance 0. Only neighbors matter.

So the issue is specifically: after Kazez stores a difficulty via `setDifficulty`, the note should be treated as having data. Let me gate on `sampleCount > 0 || currentDifficulty != defaultDifficulty`:

Actually wait, re-reading the convergence test: it simulates 10 correct answers at note 60, all with the same note range [60,60]. The first call (nil lastComparison) returns 100.0 and doesn't call `setDifficulty`. The second call (correct lastComparison) runs Kazez: `p = weightedEffectiveDifficulty(60)`. With the current note's sampleCount = 0 and no neighbors, this returns 100.0. Kazez: `100 * (1 - 0.05 * 10) = 50.0`. Stores 50.0 via `setDifficulty`. Third call: `p = weightedEffectiveDifficulty(60)`. sampleCount is still 0 (only `update` increments it). Returns 100.0 again. Kazez again: `100 * (1 - 0.05 * 10) = 50.0`. Same result every time. Never converges.

The fix: the current note should be included if `sampleCount > 0` OR if `currentDifficulty` has been modified from default. Since `currentDifficulty` defaults to 100.0, checking `!= 100.0` would work for this case. But it's fragile.

A better approach: always include the current note's `currentDifficulty` regardless of `sampleCount`. This is what the original code did. The question is just whether to also include neighbors.

Let me revert to always including the current note:

Actually, I already made that change above. Let me reconsider: with this change:
- Untrained note, no neighbors: returns own 100.0 ✓
- Untrained note with trained neighbors at 40.0: returns (1.0*100 + 0.5*40) / 1.5 = 80.0 — this is the blended result, not pure neighbor data

Is this acceptable? The story says "uses a weighted average of up to 5 nearest trained notes in each direction, weighted by 1/(1+distance)." For an untrained note, AC#1 says to use neighbor data. AC#2 says trained notes include their own data at distance 0.

So for untrained notes (sampleCount == 0), we should NOT include the current note's default 100.0. Only neighbors. But for Kazez-updated notes (sampleCount == 0 but currentDifficulty != default), we SHOULD include the current value.

The cleanest solution: include the current note if `sampleCount > 0` OR `currentDifficulty != DifficultyParameters.defaultDifficulty`:

### 🤖 Assistant (12:12:16)

Now let me think about the `kazezConvergenceFromDefault` test flow again:
1. Iter 1: no lastComparison → weighted(60) = 100.0 (untrained, no neighbors, default) → returns 100.0
2. Iter 2: correct → weighted(60) = 100.0 (still untrained) → Kazez: 50.0 → setDifficulty(60, 50.0)
3. Iter 3: correct → weighted(60): currentDifficulty=50.0 != 100.0 → includes (d=0, 50.0) → returns 50.0. Kazez: `50 * (1 - 0.05 * √50) ≈ 50 * 0.6464 ≈ 32.32` → setDifficulty(60, 32.32)
4. Continues converging ✓

Now for the `weightedDifficultyKernelNarrowing` test — note 60 is untrained, currentDifficulty = 100.0 (default). So the condition `!= defaultDifficulty` is false, and `sampleCount == 0`. So note 60 is NOT included as a candidate. Only the 5 nearest neighbors (all at 50.0) are included. Weighted avg = 50.0. ✓

But wait, I need to recheck the `weightedDifficultyKernelNarrowing` test — the actual failure could be something else. Let me also consider: with 200 iterations and range [52,60], is note 60 likely to be selected? The range has 9 notes (52-60). With default `naturalVsMechanical: 0.5`, half the time it picks weak spots, half picks from weak spots (since nil lastComparison). Weak spots would prioritize untrained notes. Only note 60 is untrained. So with 200 iterations, note 60 should be selected frequently. But maybe not — let me check what `weakSpots(count: 10)` returns.

Wait, `weakSpots` returns the top 10 weakest notes from ALL 128 MIDI notes. All untrained notes (125 of them) have infinite score, then the 3 trained notes. So `weakSpots(count: 10)` returns 10 random untrained notes from the full 128 range. The test then filters by `isInRange` (52-60). Only note 60 is untrained in range. But note 60 might not be in the 10 random untrained notes! With 120 untrained notes and only 10 selected, there's a ~8.3% chance per slot, or about 58% chance of being included in 10 draws. So there's about a 42% chance it's NOT included and the test fails to find note 60. That's the likely failure.

Let me fix this test to be more robust:

### 🤖 Assistant (12:12:22)

The problem with the non-deterministic tests is that `weakSpots(count: 10)` returns only 10 from the full 128 MIDI range. The fix is to train all out-of-range notes so only the notes we care about are untrained. Or better, use a tight range where the desired note is more likely to be selected.

Let me fix the `weightedDifficultyKernelNarrowing` test to make it deterministic. I'll train all notes in the range except note 60, so note 60 is the only untrained weak spot:

### 🤖 Assistant (12:12:44)

The issue is that with range [52,60], note 60 is the only untrained note, but `weakSpots(count: 10)` picks from ALL 128 MIDI notes. There are 119 other untrained notes outside the range. `weakSpots` returns 10 random untrained notes, which are then filtered by `isInRange`. Only note 60 is untrained in range, but it might not be in the initial 10.

A better approach: use `naturalVsMechanical: 1.0` to always use weak spots, and increase the iterations. Actually, even with 1.0, the same problem applies because `weakSpots(count: 10)` returns only 10 from 120 untrained notes.

The real fix: use `naturalVsMechanical: 0.0` with a `lastComparison` targeting note 60. With `selectNearbyNote(around: 60, ...)` and range [52,60], note 60 has a good chance of being picked (it's within the nearby range). But still not guaranteed.

Actually, the simplest fix for all these randomized tests: set `noteRangeMin` = `noteRangeMax` = the target note, but then we lose neighbor search. The design constraint is that the neighbor search uses the same settings range.

Let me rethink: I can make these tests deterministic by training ALL notes in range except the target one, AND training all notes OUTSIDE the range too. That way `weakSpots` returns the target note as the top weak spot. But that's 127 `update` calls...

Actually, wait. Let me look at `selectWeakSpot` again:

```swift
let weakSpots = profile.weakSpots(count: 10)
let filtered = weakSpots.filter { settings.isInRange($0) }
if let selected = filtered.randomElement() {
    return selected
} else {
    return Int.random(in: settings.noteRangeMin...settings.noteRangeMax)
}
```

If no weak spots are in range, it picks a random note from the range. So even if `weakSpots` doesn't include note 60, there's a `1/9` chance of randomly picking note 60 from range [52,60]. With 200 iterations, probability of never hitting it is `(8/9)^200 ≈ 3.4e-10`. But half the time (with default 0.5 mechanical ratio), it goes to the else branch... which also calls `selectWeakSpot` since lastComparison is nil. So effectively all 200 iterations go through `selectWeakSpot`.

With `weakSpots(count: 10)` filtering: P(note 60 in weakSpots) ≈ 1 - (119/120)^10 ≈ 8%. Then filtered = [60]. Returns 60.
P(note 60 NOT in weakSpots) ≈ 92%. Then filtered = []. Falls back to random in [52,60]: P(60) = 1/9 ≈ 11%.

Combined P(select 60 per iteration) = 0.08 * 1.0 + 0.92 * (1/9) ≈ 0.08 + 0.10 = 0.18

P(never select 60 in 200 iterations) = (1 - 0.18)^200 ≈ 0. So actually it should work with 200 iterations. But the `weightedDifficultyKernelNarrowing` failure might be a different issue.

Hmm, let me reconsider. Maybe the `weakSpots` implementation picks untrained notes deterministically, not randomly?

### 🤖 Assistant (12:12:56)

So `weakSpots(count: 10)` returns the top 10 notes by score. All untrained notes have `Double.infinity` score, so they all sort first. But `sort` is stable in Swift, meaning notes with the same score maintain their original order (enumerated order = 0, 1, 2, ...). So the top 10 weak spots are always notes 0-9 (the first 10 untrained MIDI notes).

With range [52,60], note 60 is untrained but won't be in the top 10 (notes 0-9 are). So `filtered` is empty. Falls back to `Int.random(in: 52...60)` — 1/9 chance per iteration. With 200 iterations: P(never hit 60) = (8/9)^200 ≈ 2.3e-10. Extremely unlikely but not impossible. This should pass with 200 iterations.

Actually wait — notes 53-59 and 52 ARE trained (sampleCount > 0), so they have finite scores. The untrained notes are 0-51 and 60-127 (minus 52-59 which are trained). That's 120 untrained notes. The top 10 are notes 0, 1, 2, ..., 9. All outside range [52,60].

So for each of 200 iterations, note 60 is selected via fallback random with P = 1/9. P(selected at least once in 200) ≈ 1 - (8/9)^200 ≈ 1. This should work.

But maybe the actual test failure is something else entirely. Let me just run the tests and pipe the full output:

### 🤖 Assistant (12:14:46)

`kazezConvergenceFromDefault` now passes. Only `weightedDifficultyKernelNarrowing` fails. It runs twice (Swift Testing runs tests multiple times?) and fails both times. But the test should statistically always hit note 60 in 200 iterations. Let me look more carefully at the issue.

The test runs in 0-1 seconds. Maybe it IS finding note 60, but the assertion is wrong. Let me check: perhaps the issue is that note 60's `currentDifficulty` is being modified by a previous iteration's Kazez path. But no, `lastComparison: nil` means no Kazez modification.

Wait, but the test loop runs `nextComparison` which goes through `selectNote` → `selectWeakSpot` → could pick any note in range. For each note, `determineCentDifference` is called. With `lastComparison: nil`, it returns the weighted difficulty without modification. So no side effects. Good.

Maybe note 60 is being selected and its weighted difficulty includes note 52's data? Let me re-examine: note 52 is at distance 8 from note 60. The 5 nearest below note 60 are 59(d=1), 58(d=2), 57(d=3), 56(d=4), 55(d=5). Note 54 at d=6 is the 6th, excluded. So note 52 at d=8 is definitely excluded.

But wait, maybe note 60 is never being selected and the `if let` clause is skipped, meaning the test passes silently without actually testing anything! But in the test output it says "failed". Let me think about what could cause a failure...

Oh! The test is run with Swift Testing's test repetition. The test suite appears twice. The first run (0.000 seconds) is likely the initial run, and the second (1.000 seconds) is a retry. The test FAILS both times.

Maybe the issue is that in the first run, note 60 is NEVER selected in 200 iterations, so `note60Difficulty` is nil, and the `if let` block is skipped. But then the test should PASS (no assertions fail). Unless Swift Testing treats a test with no assertions as a failure? No, that's not standard behavior.

Let me look more carefully. Actually, maybe the test contains a compilation error or something. Let me check:

### 🤖 Assistant (12:15:28)

It passed when run individually! This might be a test isolation issue — another test modifies shared state that affects this test. Let me run the full suite again to see if it's flaky:

### 🤖 Assistant (12:16:33)

Still failing. The test passes in isolation but fails in the full suite. This is a flaky test issue related to the randomized note selection. Since the test creates fresh profile and strategy instances, it shouldn't be a shared state issue — but Swift Testing might run tests concurrently on the same actor.

Actually, since `AdaptiveNoteStrategy` is `@MainActor`, all tests run sequentially on the main actor. The issue must be randomness-based. Let me make the test deterministic by increasing iterations to 1000 and also adding a fallback assertion:

### 🤖 Assistant (12:17:54)

Still only `weightedDifficultyKernelNarrowing` fails and it passes in isolation. I notice it takes 0.000 seconds in the first run but completes. It passes in the isolated run. Let me check the xcresult for the failure message:

### 🤖 Assistant (12:19:31)

The colon from `ls` is being included. Let me fix:

### 🤖 Assistant (12:19:40)

The error is a floating point precision issue: `49.99999999999999` vs `50.0`. The weighted average computation introduces floating point error. Let me fix the assertion to use an epsilon comparison:

### 🤖 Assistant (12:19:44)

Now run the full test suite again:

### 🤖 Assistant (12:20:30)

All tests pass. Let me run once more to make sure it's not flaky:

### 🤖 Assistant (12:21:14)

All tests pass consistently. Let me commit the changes.

### 🤖 Assistant (12:21:34)

Done. Here's a summary of the changes:

**`AdaptiveNoteStrategy.swift`:**
- Added `maxNeighbors = 5` constant to `DifficultyParameters`
- Added `weightedEffectiveDifficulty(for:profile:settings:)` method that collects up to 5 nearest trained neighbors in each direction, weights them by `1/(1+distance)`, and returns the weighted average (or 100.0 default if no data)
- Updated `determineCentDifference` to use `weightedEffectiveDifficulty` instead of raw `currentDifficulty` for both the no-lastComparison path and the Kazez formula input
- The current note is included at distance 0 if it has been trained (`sampleCount > 0`) or had its difficulty modified by Kazez (`currentDifficulty != default`)

**`AdaptiveNoteStrategyTests.swift`:**
- Updated 3 existing tests (`difficultyRespectsFloor`, `difficultyRespectsCeiling`, `statelessStrategyConsistency`) to call `profile.update()` before `setDifficulty()` so `sampleCount > 0`
- Updated `perNoteIndependentDifficulties` test description to clarify isolated range behavior
- Added 6 new tests: `weightedDifficultyNoDataReturnsDefault`, `weightedDifficultyCurrentNoteOnlyReturnsOwnDifficulty`, `weightedDifficultyNeighborsOnly`, `weightedDifficultyCurrentNoteDominates`, `weightedDifficultyKernelNarrowing`, `weightedDifficultyBoundaryNote`

### 🧑 Human (12:22:23)

Let me run the tests in Xcode.

### 🤖 Assistant (12:22:25)

Sounds good — let me know how they go.

### 🧑 Human (12:28:12)

The tests pass. When I test manually test on my iPhone and only provide correct answers, I still get stuck around 40 cent difficulty.

### 🤖 Assistant (12:29:46)

Let me trace through the algorithm to understand the issue.

### 🤖 Assistant (12:29:55)

I see the problem. The Kazez formula uses the **weighted** difficulty as input `p`, not the note's own raw difficulty. Here's what happens in a real session:

1. Note 60 trained down to 30 cents via Kazez
2. Note 62 trained down to 35 cents
3. Note 60 is selected again → weighted difficulty blends 30 (self, w=1.0) with 35 (neighbor, w=0.5) = **31.7 cents**
4. Kazez narrows from 31.7 → ~25 cents, stores 25
5. Next time: weighted blends 25 with neighbor's 35 → **28.3** → Kazez narrows to ~22
6. But neighbor also gets pulled up on ITS next visit...

The neighbors keep pulling each other back up, creating a **floor around 40 cents** where the weighted averaging counteracts Kazez narrowing. The weighted difficulty should only be used to **bootstrap untrained notes** — once a note has its own Kazez data, the raw difficulty should feed Kazez directly.

### 🤖 Assistant (12:30:02)

Now the Kazez formula uses raw difficulty once the note has been updated, and only bootstraps from neighbors on the first encounter. Let me run the tests:

### 🤖 Assistant (12:30:59)

All tests pass. Let me run once more to confirm stability:

### 🤖 Assistant (12:31:54)

Now let me commit:

### 🤖 Assistant (12:32:03)

The fix: **weighted difficulty is now only used as Kazez input for bootstrapping untrained notes**. Once a note has its own Kazez-updated difficulty (`currentDifficulty != 100.0`), the raw per-note value feeds Kazez directly. The weighted value is still used for the presentation path (nil `lastComparison`) so untrained notes show a difficulty informed by neighbors.

The root cause was that neighbors kept pulling each other's weighted average back up on every Kazez step, counteracting the narrowing and creating a convergence floor around 40 cents.

### 🧑 Human (12:40:36)

I've tried the app on my iPhone and convergence was much too slow. I've done at least 100 comparisons and still did not get below 20 cent difficulty. The interesting training difficulties for me are between 10 and 3 cents. I would to get there on a cold start in no more than 10 comparisons.

### 🤖 Assistant (12:44:11)

I see the issue. Let me trace through what happens in a real session to understand the convergence problem.

### 🤖 Assistant (12:44:21)

There are two problems:

**Problem 1: Kazez narrowing is too slow.** Current coefficient 0.05 gives this convergence on a single note:
- 100 → 50 → 32 → 23 → 18 → 14 → 11 → 9.4 → 8.0 → 6.8 (10 steps)

With 48 notes in range, each note gets ~2 of every 100 comparisons, so they barely converge.

**Problem 2: Unrefined notes poison neighbor bootstrapping.** The first note in a session gets `profile.update()` (sampleCount=1) but never gets Kazez-refined (nil lastComparison). Its `currentDifficulty` stays at 100. Since the neighbor search includes any note with `sampleCount > 0`, this 100-cent anchor pulls up weighted averages for all nearby notes.

Let me document these findings in the story file for the next session.

### 🤖 Assistant (12:44:32)

Now let me write the findings document:

### 🤖 Assistant (12:45:11)

Done. I've documented the findings in `docs/implementation-artifacts/future-work.md` under "Weighted Effective Difficulty: Convergence Still Too Slow". Here's a summary of what's captured:

**Two root causes identified:**

1. **Kazez coefficient too conservative (0.05)** — With a 48-note range, comparisons spread thin. Each note gets ~2 of 100 comparisons. Proposed fix: increase to **0.08**, which gives 100 → 20 → 12.8 → 9.1 → 6.9 in just 5 steps on a single note.

2. **Unrefined notes anchor neighbors at 100 cents** — The first note each session gets `profile.update()` (sampleCount=1) but never Kazez-refined. Its 100-cent difficulty poisons weighted averages for all nearby notes. Proposed fix: require `currentDifficulty != defaultDifficulty` for neighbor inclusion.

**Expected result with both fixes:** presented difficulty reaches 5–10 cents by comparison 6–10 on a cold start, matching your target.

The document includes the exact code changes needed, the expected convergence trace, and which tests need updating — ready to pick up in the next session.

---

[← Previous (a225a9fcf1)](a225a9fcf1.md) | [Index](index.md) | [Next (679cf6316a) →](679cf6316a.md)
