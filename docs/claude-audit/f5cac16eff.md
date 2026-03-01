---
commit: "f5cac16eff070227abfc0dff40d6154b614b4cbb"
date: "2026-02-27T22:18:32+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Fix code review findings for 20-10-inject-trainingdatastore-into-settingsscreen and mark done"
sessions: ["4b9b352b-f4cf-457c-bce7-9b5d2d88a578"]
prev: "f0e15b8976.md"
next: "aeab05f4eb.md"
---

[← Previous (f0e15b8976)](f0e15b8976.md) | [Index](index.md) | [Next (aeab05f4eb) →](aeab05f4eb.md)

# Commit f5cac16eff

**Date:** 2026-02-27 22:18:32 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Fix code review findings for 20-10-inject-trainingdatastore-into-settingsscreen and mark done

Move reset orchestration from SettingsScreen to PeachApp closure,
removing ComparisonSession/PerceptualProfile/TrainingDataStore
dependencies from the view. Make Resettable.reset() throwing,
add TrainingDataStore Resettable conformance, make
ComparisonSession.resetTrainingData() throwing.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
Peach/App/EnvironmentKeys.swift                    |  2 +-
 Peach/App/PeachApp.swift                           |  6 ++++-
 Peach/Comparison/ComparisonSession.swift           |  6 +++--
 Peach/Core/Data/TrainingDataStore.swift            |  8 +++++++
 Peach/Core/Training/Resettable.swift               |  2 +-
 Peach/Settings/SettingsScreen.swift                | 12 ++--------
 .../Comparison/ComparisonSessionResetTests.swift   | 22 +++++++++---------
 PeachTests/Core/Training/ResettableTests.swift     | 20 ++++++++---------
 ...inject-trainingdatastore-into-settingsscreen.md | 26 +++++++++++++---------
 docs/implementation-artifacts/sprint-status.yaml   |  2 +-
 10 files changed, 59 insertions(+), 47 deletions(-)
```

## Session `4b9b352b…`

*2026-02-27 20:27:03 UTC → 2026-02-27 21:18:39 UTC*

### 🧑 Human (20:27:03)

<command-message>bmad-bmm-code-review</command-message>
<command-name>/bmad-bmm-code-review</command-name>
<command-args>20.10</command-args>

### 🤖 Assistant (20:27:06)

I'll start by loading the workflow execution framework and the code review workflow configuration.

### 🤖 Assistant (20:27:11)

Now let me load the config source and the instructions/checklist files.

### 🤖 Assistant (20:27:21)

Good. Workflow loaded and variables resolved. This is an **action-workflow** (no template). Let me begin executing the instructions.

## Step 1: Load Story and Discover Changes

Let me find and load the story file for 20.10.

### 🤖 Assistant (20:27:30)

Working tree is clean. The story was committed in `aeab05f`. Let me read the story and see the actual files changed in that commit.

### 🤖 Assistant (20:27:41)

Story loaded. **story_key** = `20-10-inject-trainingdatastore-into-settingsscreen`

**Git vs Story File List:** ✅ All 5 files match perfectly. No discrepancies.

Now let me execute the `discover_inputs` protocol and load project context.

### 🤖 Assistant (20:27:53)

Let me load Epic 20 from the epics file.

### 🤖 Assistant (20:27:59)

Good. Now I have all the context. Let me proceed to **Step 2: Build Review Attack Plan** and then immediately execute **Step 3: Adversarial Review**. Let me read all the implementation files.

### 🤖 Assistant (20:29:13)

Now let me verify a few implementation details more closely.

### 🤖 Assistant (20:29:20)

Good. `deleteAll()` exists on `TrainingDataStore`. And the project-context.md rule at line 64 indeed says views should **never** reference `TrainingDataStore`. Let me check one more thing — the original SettingsScreen before this commit to see if it was already violating this rule.

### 🤖 Assistant (20:30:01)

I've completed my analysis. Now presenting findings.

---

## Step 4: Code Review Findings

**Story:** `20-10-inject-trainingdatastore-into-settingsscreen.md`
**Git vs Story Discrepancies:** 0 found
**Issues Found:** 1 High, 2 Medium, 3 Low

---

### CRITICAL / HIGH ISSUES

**H1: project-context.md rule violated — Views should never reference `TrainingDataStore`**
`docs/project-context.md:64` explicitly states:
> "Views only interact with `ComparisonSession`, `PitchMatchingSession`, `PerceptualProfile`, and `TrainingSession` — never import or reference `NotePlayer`, `NextComparisonStrategy`, or **`TrainingDataStore`** from views"

This story introduces `@Environment(\.trainingDataStore) private var dataStore` into `SettingsScreen.swift:22`, directly contradicting this rule. The *original* code also violated the spirit of this rule (constructing `TrainingDataStore(modelContext:)` directly), but this story solidifies the violation as an environment-injected pattern. Either:
- **Option A:** Update `project-context.md` line 64 to add `TrainingDataStore` as an allowed dependency for `SettingsScreen` (since it's a settings/admin screen, not a training view).
- **Option B:** Delegate the reset operation to `ComparisonSession` (which already has access to the data store as an observer), keeping `SettingsScreen` decoupled.

---

### MEDIUM ISSUES

**M1: AC #6 not fully satisfied — Preview does not inject in-memory `TrainingDataStore`**
AC #6 states: *"The `#Preview` block injects an in-memory `TrainingDataStore` via `.environment(\.trainingDataStore, ...)`."*
Actual implementation at `SettingsScreen.swift:172-176`:
```swift
#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
```
No injection. Reset button is non-functional in preview. The Dev Agent Record documents the deviation, but the **AC text in the story header was not updated** to match reality. The AC still claims an in-memory store is injected.

**M2: Wrong story number in Git Intelligence section**
`Story file line 86`: `Commit message: Implement story 20.9: Inject TrainingDataStore into SettingsScreen`
Should be `20.10`, not `20.9`. Copy-paste error from the previous story.

---

### LOW ISSUES

**L1: Silent failure on nil `dataStore`**
`SettingsScreen.swift:159`: `guard let dataStore else { return }` — silently does nothing if `dataStore` is nil. In production this is impossible (PeachApp always injects), but adding a log via `os.Logger` would help catch configuration mistakes during development.

**L2: Optional `TrainingDataStore` inconsistency in `@Entry` declarations**
In `EnvironmentKeys.swift`, all other non-session entries (`soundFontLibrary`, `trendAnalyzer`, `thresholdTimeline`, `perceptualProfile`) are non-optional. `trainingDataStore` is optional solely due to the `@Entry` eager evaluation constraint. This creates an API inconsistency — consumers must guard-let for a value that is always present at runtime. Documented in Dev Agent Record, but worth noting.

**L3: Dev Notes "Existing Code to Reference" section shows pre-change code**
`Story file lines 69-71`: References `SettingsScreen.swift:~160` with `let dataStore = TrainingDataStore(modelContext: modelContext)`, which is the **old** code that was removed. Not incorrect (it was reference info used during implementation), but misleading as post-implementation documentation.

---

What should I do with these issues?

1. **Fix them automatically** — I'll update the code, story, and docs
2. **Create action items** — Add to story Tasks/Subtasks for later
3. **Show me details** — Deep dive into specific issues

Choose [1], [2], or specify which issue to examine:

### 🧑 Human (20:32:02)

H1: I very much favor Option B.

### 🤖 Assistant (20:32:20)

Good call — that keeps `SettingsScreen` decoupled. Let me explore how `ComparisonSession.resetTrainingData()` works now to understand the implementation path.

### 🤖 Assistant (20:32:39)

Let me see how `ComparisonSession` is initialized and what it has access to.

### 🤖 Assistant (20:32:47)

Let me check `PitchMatchingSession` too, since the reset also needs `profile.resetMatching()`.

### 🤖 Assistant (20:33:13)

Let me check the `Resettable` protocol and how `profile.reset()` works vs `profile.resetMatching()`.

### 🤖 Assistant (20:34:01)

Let me check who calls `resetTrainingData()` and understand the dependency graph better.

### 🤖 Assistant (20:34:35)

Good. `resetTrainingData()` is only called from `SettingsScreen` in production. Let me see the full ComparisonSession init and the test factory.

### 🤖 Assistant (20:34:41)

Let me read the test factory and the reset tests.

### 🤖 Assistant (20:35:29)

Good choice. Here's my plan for implementing Option B:

**The approach:** Wire a `dataDeleter` closure into `ComparisonSession` at the composition root, so `SettingsScreen` never touches `TrainingDataStore`.

**Changes needed:**

| File | Change |
|---|---|
| `ComparisonSession.swift` | Add `dataDeleter: (() throws -> Void)?` param to init; `resetTrainingData()` becomes `throws`, calls `try dataDeleter?()` first |
| `PeachApp.swift` | Pass `dataDeleter: { try dataStore.deleteAll() }` to `createComparisonSession`; revert `dataStore` from `@State` to local (no longer needed in body); remove `.environment(\.trainingDataStore, ...)` |
| `SettingsScreen.swift` | Remove `@Environment(\.trainingDataStore)`; `resetAllTrainingData()` calls `try comparisonSession.resetTrainingData()` + `profile.resetMatching()` |
| `EnvironmentKeys.swift` | Remove `@Entry var trainingDataStore` |
| `ComparisonSessionResetTests.swift` | Add `try` to 6 `resetTrainingData()` calls, add `throws` to function signatures |
| `ResettableTests.swift` | Add `try` to 1 call, add `throws` |
| New test | Verify `dataDeleter` closure is called during `resetTrainingData()` |

`profile.resetMatching()` stays in `SettingsScreen` — `PerceptualProfile` is in the allowed view dependency list.

Shall I proceed with fixing all issues (H1 with Option B + M1, M2, L1–L3), or just H1?

### 🧑 Human (20:45:46)

Why do dataDelete and ComparisonSession need any relationship? When the user choose to delete all data on the Data Screen, this should only affect TrainingDataStore. Suggestion: Make TrainingDataStore conform to Resettable, add it to the environment as dataStoreResetter, and use that in SettingsScreen. What do you think?

### 🤖 Assistant (20:46:20)

You're right — the data deletion has nothing to do with ComparisonSession. I was overcomplicating it. Your approach is much cleaner:

- No changes to `ComparisonSession` at all
- `SettingsScreen` depends only on `Resettable` (an abstraction), never `TrainingDataStore`
- The architecture rule is satisfied

**One tradeoff to flag:** `Resettable.reset()` is non-throwing, but `deleteAll()` throws. The `TrainingDataStore.reset()` conformance would need to catch internally and log, which means SettingsScreen loses the error alert (`showResetError`). In practice, a SwiftData batch delete on local SQLite essentially never fails, so this seems acceptable. Worth it?

### 🧑 Human (20:48:10)

What would be the repercussions of making reset() throwing?

### 🤖 Assistant (20:48:44)

The blast radius is fairly contained:

**Production (2 files):**
- `TrendAnalyzer.reset()` and `ThresholdTimeline.reset()` need `throws` added (they don't actually throw — just ceremony)
- `ComparisonSession.swift:143` — `resettables.forEach { $0.reset() }` needs error handling, which makes `resetTrainingData()` itself throwing → same cascade to `SettingsScreen` either way

**Tests (~12 call sites):**
- `ResettableTests.swift` — 4 calls need `try`
- `ComparisonSessionResetTests.swift` — 6 calls need `try` (+ `throws` on signatures)
- `ResettableTests.swift` — 1 more in the ComparisonSession test
- Direct `.reset()` calls on TrendAnalyzer/ThresholdTimeline in other test files — a handful more

**Not affected:**
- `profile.reset()` in ComparisonSession — that's through `PitchDiscriminationProfile`, a separate protocol
- `MockNotePlayer.reset()`, `PlaybackHandle.reset()` — unrelated methods

So it's roughly: 2 production conformances get `throws` added, `resetTrainingData()` becomes throwing, and ~12 test call sites get `try`. All mechanical. The question is whether it's worth adding `throws` to conformances that never throw, just so `TrainingDataStore` can propagate its error. I'd say yes — it's honest about the contract, and the test churn is trivial.

### 🧑 Human (20:49:58)

go ahead, fix all issues

### 🤖 Assistant (20:50:06)

I already have deep context from the code review. Let me verify a few remaining details before writing the plan.

### 🤖 Assistant (20:51:51)

I have all the context I need. Let me write the implementation plan.

### 🤖 Assistant (20:52:22)

Let me verify a couple of details before finalizing.

### 🤖 Assistant (20:52:57)

Good, I have all the details. Let me finalize the plan with precise file-level changes.

### 🤖 Assistant (20:54:32)

Let me create tasks and start implementing.

### 🤖 Assistant (20:54:56)

Now let me start implementing. Tasks 1-3 are production code changes that I'll do together, then task 4 for tests.

### 🤖 Assistant (20:55:36)

Wait — I just realized something important. In Swift, a **non-throwing** method satisfies a **throwing** protocol requirement. So `TrendAnalyzer.reset()` and `ThresholdTimeline.reset()` don't need to change at all. Direct calls to them won't need `try` either. Only calls through the `Resettable` protocol type need `try`.

This significantly reduces the blast radius. Let me implement.

### 🤖 Assistant (20:55:39)

Now add `Resettable` conformance to `TrainingDataStore`.

### 🤖 Assistant (20:55:50)

Those are SourceKit cross-file resolution artifacts, not real errors. Let me continue with the environment key and wiring changes.

### 🤖 Assistant (20:56:01)

Now update SettingsScreen.

### 🤖 Assistant (20:56:15)

Now update `ComparisonSession.resetTrainingData()`.

### 🤖 Assistant (20:56:24)

Now update the test files. Let me read and fix them.

### 🤖 Assistant (20:56:30)

`MockResettable` needs no change — non-throwing `reset()` satisfies the throwing protocol requirement. Now update `ResettableTests.swift` — only calls through `Resettable`-typed variables need `try`.

### 🤖 Assistant (20:57:00)

Now update `ComparisonSessionResetTests.swift` — 6 calls to `resetTrainingData()` need `try`.

### 🤖 Assistant (20:57:22)

Now add `try` to all 6 `session.resetTrainingData()` calls.

### 🤖 Assistant (20:57:27)

`SettingsTests.swift` and `ThresholdTimelineTests.swift` — calls are on concrete types (non-throwing), so no changes needed. Let me verify by reading the final state of the test files I changed.

### 🤖 Assistant (20:57:31)

All tests look correct. Let me verify the production files are clean too.

### 🤖 Assistant (20:57:35)

Now fix the documentation issues in the story file.

### 🤖 Assistant (20:57:45)

Let me fix all the documentation issues.

### 🤖 Assistant (20:57:51)

**M1:** Fix AC #6 text.

### 🤖 Assistant (20:57:56)

**M2:** Fix Git Intelligence "20.9" → "20.10".

### 🤖 Assistant (20:58:00)

**L3:** Update "Existing Code to Reference" to reflect post-implementation state.

### 🤖 Assistant (20:58:09)

Now update the File List and Change Log to reflect the code review fixes.

### 🤖 Assistant (20:58:31)

Now update the sprint status.

### 🤖 Assistant (20:58:44)

Now let me run the full test suite.

### 🤖 Assistant (21:01:18)

All tests pass. Let me count the tests to confirm.

### 🤖 Assistant (21:01:25)

All 598 tests pass. Let me also do a quick verification that `SettingsScreen` has no reference to `TrainingDataStore`.

### 🤖 Assistant (21:01:42)

**TEST SUCCEEDED** — 598 tests pass, zero regressions. `SettingsScreen` has zero references to `TrainingDataStore`, `SwiftData`, or `ModelContext`.

## Summary of all fixes applied

| Issue | Fix |
|---|---|
| **H1:** Views referencing `TrainingDataStore` | `TrainingDataStore` conforms to `Resettable`; injected as `@Entry var dataStoreResetter: (any Resettable)?`; `SettingsScreen` only sees the protocol |
| **M1:** AC #6 text didn't match reality | Updated AC text to reflect simplified preview with nil default |
| **M2:** Wrong story number in Git Intelligence | Fixed "20.9" → "20.10" |
| **L1:** Silent nil failure | Now inside do/catch block; nil skip is acceptable for `Resettable?` |
| **L2:** Optional inconsistency | Now uses `(any Resettable)?` which is naturally optional like `(any TrainingSession)?` |
| **L3:** Stale code references in Dev Notes | Updated to reflect post-implementation state |

**Files changed:** 10 files (4 production, 2 tests, 2 docs, 1 protocol, 1 data store conformance)

**Key architectural win:** Non-throwing `reset()` on `TrendAnalyzer`/`ThresholdTimeline` still satisfies the throwing protocol — no changes needed to those files or their direct call sites. Only calls through the `Resettable` protocol type require `try`.

### 🧑 Human (21:09:35)

I still don't like the implementation of SettingsScreen.resetAllTrainingData(). Effectively, it means that the screen has to know what it means to reset all data. But it should not know anything about it! There's currently only place in the app that ought to know what is involved and that is PeachApp. PeachApp should have a method that does the resetting and pass it in a closure (dataStoreResetter) to SettingsScreen.

### 🤖 Assistant (21:11:09)

You're absolutely right. SettingsScreen shouldn't orchestrate the reset at all — it should just call a closure that PeachApp provides. And then SettingsScreen won't even need `@Environment(\.comparisonSession)` or `@Environment(\.perceptualProfile)` for the reset.

### 🤖 Assistant (21:11:18)

Good — `comparisonSession` and `profile` are used **only** in `resetAllTrainingData()`. Moving the logic to PeachApp means SettingsScreen drops both dependencies.

### 🤖 Assistant (21:11:28)

Now simplify SettingsScreen — remove the two environment dependencies and simplify the reset method.

### 🤖 Assistant (21:11:39)

Now run the tests to verify.

### 🤖 Assistant (21:16:46)

All 598 tests pass. Let me verify the final state of SettingsScreen is clean.

### 🤖 Assistant (21:16:53)

Clean. SettingsScreen now has only 2 `@Environment` dependencies (`dataStoreResetter` and `soundFontLibrary`), no knowledge of `ComparisonSession`, `PerceptualProfile`, or `TrainingDataStore`. The reset is a single closure call.

Let me update the story file to reflect this final design.

### 🤖 Assistant (21:17:14)

Now update the "Existing Code to Reference" to match the final state.

### 🤖 Assistant (21:17:26)

Done. Here's what changed with this refinement:

**Before:** SettingsScreen orchestrated 3 calls (`dataStoreResetter?.reset()`, `comparisonSession.resetTrainingData()`, `profile.resetMatching()`) and needed 4 `@Environment` dependencies.

**After:** SettingsScreen calls `dataStoreResetter?()` — a single closure. It has only 2 `@Environment` dependencies (`dataStoreResetter` and `soundFontLibrary`). PeachApp owns the full reset orchestration, as the composition root should.

All 598 tests pass. `SettingsScreen` has zero knowledge of `ComparisonSession`, `PerceptualProfile`, `TrainingDataStore`, `SwiftData`, or `ModelContext`.

### 🧑 Human (21:18:15)

commit this

### 🤖 Assistant (21:18:39)

Committed as `f5cac16`. Working tree is clean.

---

[← Previous (f0e15b8976)](f0e15b8976.md) | [Index](index.md) | [Next (aeab05f4eb) →](aeab05f4eb.md)
