---
commit: "9cd3fe0cfe1feb0ef2f440c7b369b408fd65a43f"
date: "2026-02-15T10:18:16+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Add hotfix story: Kazez evaluation strategy for difficulty convergence"
sessions: ["109535f8-7554-4035-8eac-f3f782bf5f54"]
prev: "d2864556e1.md"
next: "e92dd618f6.md"
---

[← Previous (d2864556e1)](d2864556e1.md) | [Index](index.md) | [Next (e92dd618f6) →](e92dd618f6.md)

# Commit 9cd3fe0cfe

**Date:** 2026-02-15 10:18:16 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Add hotfix story: Kazez evaluation strategy for difficulty convergence

AdaptiveNoteStrategy converges too slowly (5% per correct answer = ~60 steps
to reach 5 cents). Add story doc and future-work entry for a separate
KazezNoteStrategy using sqrt(P)-scaled formulas from Kazez et al. (2001)
that reach 5 cents in ~10 steps.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
docs/implementation-artifacts/future-work.md       |  23 ++++
 .../hotfix-kazez-evaluation-strategy.md            | 132 +++++++++++++++++++++
 2 files changed, 155 insertions(+)
```

## Session `109535f8…`

*2026-02-15 08:47:22 UTC → 2026-02-15 09:19:02 UTC*

### 🧑 Human (08:47:22)

<command-message>bmad-party-mode</command-message>
<command-name>/bmad-party-mode</command-name>
<command-args>Everyone! After manually testing the app, I must say, that the next node algorithm does not work as intended. Even though I only give only correct answers (as I can see the note values from the log), I stick around the 100 to 80 difficulty range for very long. Instead, the algorithm should home in on the difficulty where the user needs training very quickly. In my case this is in the 10 to 5 cent difficulty range. I think this is an issue we need to get ahead of before proceeding with the intended epics. In order to find a better algorithm, I think *temporarily* we ought to try a simpler NextNoteStrategy. Here's my suggestion:
* Smaller range from C3 (MIDI note 48) to C5 (MIDI note 72).
* Only calculate and use an overall difficulty, not for each note.
* For pitch difference calculation (i.e. difficulty for the next comparison) look at this paper from Dr. Kazez (one of the people behind InTune): /tmp/Pitch-Kazez-CMS-2001-abstract.pdf 

Discuss.</command-args>

### 🤖 Assistant (08:47:25)

I'll start by reading the workflow file and then exploring the relevant code and the paper.

### 🤖 Assistant (08:47:36)

Now let me load the party mode configuration and explore the current algorithm code.

### 🤖 Assistant (08:48:55)

Now let me read the discussion orchestration step to complete setup.

### 🤖 Assistant (08:49:38)

Good, I now have everything I need. Let me orchestrate this party mode discussion.

---

🎉 **PARTY MODE ACTIVATED!** 🎉

Welcome Michael! All BMAD agents are here and ready for a dynamic group discussion. I've assembled the team most relevant to your algorithm challenge.

Let me bring in the experts for this one...

---

🏗️ **Winston (Architect)**: Right. Let me cut through the noise here. Michael, you've identified the exact problem I'd flag in a design review — the current `AdaptiveNoteStrategy` uses a *fixed multiplicative factor* (`narrowingFactor = 0.95`, i.e. 5% reduction per correct answer). Starting at 100 cents, that means:

- After 10 correct answers: 100 × 0.95^10 = **59.9 cents**
- After 20 correct answers: 100 × 0.95^20 = **35.8 cents**
- After 40 correct answers: 100 × 0.95^40 = **12.9 cents**
- After 60 correct answers: **4.6 cents**

That's **60 consecutive correct answers** to reach the 5-cent range. Nobody's going to feel the training is responsive. The algorithm converges linearly in log-space — same percentage every step regardless of where you are. That's the fundamental design flaw.

Now, this Kazez paper is elegant. The formulas use `√P` as a scaling factor:

- **Correct**: `N = P × [1 - (0.05 × √P)]`
- **Incorrect**: `N = P × [1 + (0.09 × √P)]`

At P=100: `N = 100 × [1 - 0.05×10] = 100 × 0.5 = 50` — that's a **50% drop** in one step.
At P=50: `N = 50 × [1 - 0.05×7.07] = 50 × 0.646 = 32.3` — still aggressive.
At P=10: `N = 10 × [1 - 0.05×3.16] = 10 × 0.842 = 8.4` — now it's gentler, only 16%.
At P=5: `N = 5 × [1 - 0.05×2.24] = 5 × 0.888 = 4.4` — even gentler, 11%.

This is *exactly* the convergence profile you want: fast when the intervals are easy, fine-grained when you're near the user's threshold. I strongly support adopting this.

As for simplifying to a **single global difficulty** instead of per-note tracking — pragmatically, I agree. The per-note system is premature complexity. We don't even have enough data to know if per-note difficulty varies meaningfully for users yet. Ship simple, measure, then add complexity if the data warrants it.

---

💻 **Amelia (Dev)**: `AdaptiveNoteStrategy.swift:32-48` — current `DifficultyParameters`. Here's what changes:

**Kill**: `narrowingFactor`, `wideningFactor`, `regionalRange`, per-note `currentDifficulty` tracking.
**Add**: Kazez formulas as the sole difficulty engine. Single `currentDifficulty: Double` on the strategy or passed through settings.

Implementation surface:
1. `AdaptiveNoteStrategy.determineCentDifference()` — replace factor multiplication with Kazez formula
2. `PerceptualProfile.setDifficulty(note:difficulty:)` — no longer per-note, single global value
3. `TrainingSettings` — `noteRangeMin: 48` (C3), `noteRangeMax: 72` (C5)
4. `PerceptualProfile.PerceptualNote.currentDifficulty` — either remove or ignore

Question is: do we keep the `NextNoteStrategy` protocol and just change the implementation, or do we write a new strategy class? I'd say new class — `KazezNoteStrategy` — so we can A/B test later and the old code stays intact.

---

🧪 **Murat (QA/Test Architect)**: Risk calculation time. The Kazez formulas have an interesting property — let me verify the edge cases:

- At P=1 (minimum): `N = 1 × [1 - 0.05×1] = 0.95` — converges toward zero. Need a floor clamp.
- At P=0.5: `N = 0.5 × [1 - 0.05×0.707] = 0.482` — still valid, but we should enforce `minCentDifference`.
- **Incorrect at P=1**: `N = 1 × [1 + 0.09×1] = 1.09` — grows slowly from the floor. Good.
- **Incorrect at P=100**: `N = 100 × [1 + 0.09×10] = 190` — needs a ceiling clamp at `maxCentDifference`.

Test matrix I'd want:
1. **Convergence test**: 10 consecutive correct from 100 → verify reaches ~5 cents
2. **Recovery test**: Incorrect at low difficulty → verify reasonable recovery
3. **Boundary tests**: Floor and ceiling clamping
4. **Deterministic seeding**: Fix random direction for reproducible tests
5. **Global vs per-note**: Verify single difficulty is used regardless of note

The existing `AdaptiveNoteStrategyTests.swift` has good structure — we adapt it for the new class.

---

📋 **John (PM)**: WHY does this matter for the product? Because user perception of progress is *everything* in a training app. If a user plays perfectly and the app doesn't noticeably get harder within the first 10-15 comparisons, they'll think it's broken — exactly what Michael experienced. The Kazez algorithm gets to the challenge zone in about **6-8 correct answers** from the starting 100 cents. That's one training session. That's the "aha, this app gets me" moment.

The simplification to global difficulty is also the right product call. Per-note difficulty is a feature for power users who've been training for months. We're not there yet. Ship the thing that makes the first 5 minutes feel magical.

One thing though — the Kazez paper also mentions a **termination condition**: "two incorrect responses out of three consecutive intervals, then the test is finished." Are we adopting that too, or just the difficulty formulas?

---

**John asks: Michael, should we also adopt the Kazez termination condition (end session after 2 incorrect out of 3 consecutive), or just the difficulty adjustment formulas for now?**

Also — the range change from C2-C6 to C3-C5 (MIDI 48-72). That makes total sense for a focused training experience. Amelia, Winston — any concerns there?

🏗️ **Winston**: None. Two octaves centered around the middle of the piano is the sweet spot for pitch discrimination. The extremes of the range (C2, C6) are harder to perceive for physiological reasons — not what we want to train on yet.

---

Continue the discussion naturally, or:

`[E] Exit Party Mode - End the collaborative session`

### 🧑 Human (08:55:03)

To be very clear, for the finished product I still want the per note difficulty! But I want it to work properly. So my suggestion is that for evaluation of how narrowing/widening of difficulty works and feels we implement _another_ simpler strategy. That's why we have a protocol.

### 🤖 Assistant (08:55:26)

💻 **Amelia**: Crystal clear. `NextNoteStrategy` protocol stays. `AdaptiveNoteStrategy` stays untouched. New file: `KazezNoteStrategy.swift` — implements the same protocol, zero per-note tracking, single global difficulty, Kazez formulas. Clean separation.

The protocol already supports this perfectly:

```swift
protocol NextNoteStrategy {
    func nextComparison(
        profile: PerceptualProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Comparison
}
```

New strategy receives the profile but simply *doesn't use* per-note difficulty from it. It maintains its own single `currentDifficulty` as internal state. Note selection becomes trivial — random note within MIDI 48-72 range, apply Kazez formula for cent difference, random direction. Done.

Then in `TrainingSession` initialization, we swap which strategy gets injected. One line change at the call site.

---

🏗️ **Winston**: This is the correct architectural call. The protocol exists precisely for this. Two observations:

1. **The new strategy can be stateful** — it only needs to track one `Double` for global difficulty. That's fine for an evaluation strategy. The existing `AdaptiveNoteStrategy` is stateless by design (reads from profile), but there's no protocol requirement for statelessness.

2. **Or** — and this might be cleaner — we keep it stateless too: store the global difficulty on `TrainingSettings` or pass it through `lastComparison`. The `CompletedComparison` already carries `centDifference` — that *is* the previous interval `P` in the Kazez formula. So: `P = lastComparison.comparison.centDifference`, apply the formula, done. No state needed at all.

Option 2 means the strategy is a pure function: previous cent difference + correctness → next cent difference. Elegant. Testable. No state management.

---

🧪 **Murat**: Winston's option 2 is significantly more testable. Pure input → output. I can write deterministic tests without worrying about internal state. 

But one edge case: first comparison has no `lastComparison`. We need a starting difficulty. The Kazez paper starts at 100 cents. We could use `settings.maxCentDifference` as the initial value — that's already 100.0 by default. Clean.

For note selection — if it's just random within range, I'd want the test to verify uniform distribution isn't biased, but honestly for an evaluation strategy, `Int.random(in: 48...72)` is fine.

---

📋 **John**: Good. So we're building a *parallel track* — an evaluation strategy to validate the Kazez feel, while the production per-note strategy stays intact for future refinement. That's smart product development. Test the core mechanic in isolation before integrating it into the complex system.

One more product question that affects implementation:

**John asks: Michael, when you say "for evaluation" — do you want a UI toggle to switch between strategies, or is swapping the strategy injection in code sufficient? And should we revert your uncommitted changes to `AdaptiveNoteStrategy` and `TrainingSettings` so the production code stays clean?**

---

`[E] Exit Party Mode - End the collaborative session`

### 🧑 Human (09:05:50)

* I don't need a toggle, just hardwire the new strategy for now.
* I think the new strategy should be stateless. All required parameters can be calculated on the fly from the PerceptualProfile. This is a bit inefficient, but remember that it is only for evaluation.

Before you start the implementation, write the appropriate documentation. We're on a special missioni right now and I want the docs to reflect that we haven't gone rogue but are addressing a major issue that came up during development.

### 🤖 Assistant (09:06:08)

📋 **John**: Smart. Document the mission before executing. Paper trail keeps us honest.

💻 **Amelia**: Agreed. Let me check the existing doc structure so we match conventions.

---

Let me look at the existing documentation to match the format.

### 🤖 Assistant (09:06:52)

Good, I have a thorough understanding of the doc conventions. Let me read the key reference files to get the exact format right.

### 🤖 Assistant (09:06:58)

Now let me read the actual current source files to understand the implementation details precisely.

### 🤖 Assistant (09:07:04)

Let me check the exact uncommitted changes and the existing test mock.

### 🤖 Assistant (09:07:25)

Good. Now I have the full picture. Let me continue the party mode discussion and converge on the documentation + plan.

---

💻 **Amelia**: Got it. Stateless, using `lastComparison.comparison.centDifference` as `P` in the Kazez formula. No internal state needed. `PerceptualProfile` is passed but only used for... actually, what *do* we use it for in the simple strategy?

🏗️ **Winston**: Nothing. The Kazez evaluation strategy is purely: previous interval + correctness → next interval. Note selection is random within range. The profile parameter satisfies the protocol signature but goes unused. That's fine — the protocol was designed for the general case. A simpler implementation doesn't need all inputs.

📋 **John**: Good. Now about documentation — Michael wants this on the record. We need to document *why* we're pausing the epic roadmap to build an evaluation strategy. This isn't scope creep, it's a quality gate. The adaptive algorithm doesn't converge properly, and shipping Epics 5-7 on top of a broken foundation is waste.

Here's what I'd write:

1. **A story document** following the existing `docs/implementation-artifacts/` convention — something like `hotfix-kazez-evaluation-strategy.md` to signal this is out-of-band from the epic sequence
2. **An update to `future-work.md`** documenting the convergence issue as a known algorithm deficiency in `AdaptiveNoteStrategy`

💻 **Amelia**: The story doc should reference the Kazez paper formulas explicitly. And note that `AdaptiveNoteStrategy` and its tests remain untouched — we're adding, not modifying.

🧪 **Murat**: And revert those uncommitted changes to `AdaptiveNoteStrategy.swift` and `NextNoteStrategy.swift`. Those were Michael's manual experiments. The production code should stay clean at the committed values (`narrowingFactor: 0.95`, `wideningFactor: 1.3`, range `36-84`).

---

📋 **John asks: Michael, for the documentation — should we frame this as a "hotfix" story outside the epic numbering (e.g., `hotfix-kazez-evaluation-strategy.md`), or assign it a proper story number like Story 4.4 extending Epic 4? And should I draft the story document now before implementation begins?**

---

`[E] Exit Party Mode - End the collaborative session`

### 🧑 Human (09:12:44)

Go with the hotfix numbering and draft the story.

### 🤖 Assistant (09:12:53)

📋 **John**: On it. Drafting the story document now.

### 🤖 Assistant (09:13:39)

Now let me update `future-work.md` to document the convergence issue.

### 🤖 Assistant (09:14:00)

---

📋 **John**: Story document is drafted at `docs/implementation-artifacts/hotfix-kazez-evaluation-strategy.md` and `future-work.md` has been updated with the convergence issue.

💻 **Amelia**: Clean. Story covers all the bases — motivation, Kazez formulas with the convergence table, clear AC, task breakdown. Ready to implement.

🏗️ **Winston**: The architecture is sound. One protocol, two implementations, swap at the injection site. Textbook strategy pattern.

🧪 **Murat**: Test matrix looks right. I especially want that convergence test — 10 consecutive correct from 100, verify we reach ~5 cents.

---

Michael, the documentation is in place:

- **Story**: `docs/implementation-artifacts/hotfix-kazez-evaluation-strategy.md` — full story with motivation, Kazez formulas, convergence table, ACs, and task breakdown
- **Future work**: Updated with the convergence issue and the path to resolution

Ready for implementation when you give the word. Should I proceed with the 5 tasks in the story, starting with reverting the uncommitted changes?

`[E] Exit Party Mode - End the collaborative session`

### 🧑 Human (09:17:51)

I've removed my experimental changes that you noticed. As for the docs, go ahead.

### 🤖 Assistant (09:17:55)

Let me verify the revert and then start implementing.

### 🤖 Assistant (09:18:00)

Good — algorithm files are clean, only the docs are changed. Let me create the task list and start implementing.

### 🤖 Assistant (09:18:22)

Now let me implement the KazezNoteStrategy.

### 🤖 Assistant (09:18:43)

Those diagnostics are just SourceKit indexing — the types exist in other files in the same target. Let me wire it into PeachApp.

### 🤖 Assistant (09:18:51)

SourceKit indexing noise — these are all types from the same Peach module. Now let me look at the existing test structure to match conventions, then write the tests.

### 🤖 Assistant (09:18:56)

Let me also check how `CompletedComparison` is constructed in tests.

### 🤖 Assistant (09:19:02)

Good. Now I have everything to write the tests.

---

[← Previous (d2864556e1)](d2864556e1.md) | [Index](index.md) | [Next (e92dd618f6) →](e92dd618f6.md)
