---
commit: "82abbdb92dff83c4dbf581a77a57b0069c55de62"
date: "2026-02-17T20:39:29+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Code review fixes for Story 5.3: extract shared threshold, fix tests, add NaN guard"
sessions: ["fb97f80f-c9ef-4eae-a3c6-9897c204b08f"]
prev: "4aad36a0dc.md"
next: "60f1777e0c.md"
---

[← Previous (4aad36a0dc)](4aad36a0dc.md) | [Index](index.md) | [Next (60f1777e0c) →](60f1777e0c.md)

# Commit 82abbdb92d

**Date:** 2026-02-17 20:39:29 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Code review fixes for Story 5.3: extract shared threshold, fix tests, add NaN guard

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
Peach/Core/Profile/PerceptualProfile.swift         | 11 +++++
 Peach/Profile/ProfileScreen.swift                  |  3 +-
 Peach/Resources/Localizable.xcstrings              |  4 --
 Peach/Start/ProfilePreviewView.swift               | 10 ++--
 PeachTests/Start/ProfilePreviewViewTests.swift     | 53 +++++++++++-----------
 ...ofile-preview-on-start-screen-and-navigation.md | 10 ++--
 docs/implementation-artifacts/sprint-status.yaml   |  2 +-
 7 files changed, 52 insertions(+), 41 deletions(-)
```

## Session `fb97f80f…`

*2026-02-17 19:15:47 UTC → 2026-02-17 19:39:34 UTC*

### 🧑 Human (19:15:47)

<command-message>bmad-bmm-code-review</command-message>
<command-name>/bmad-bmm-code-review</command-name>

### 🤖 Assistant (19:15:50)

I'll start by loading the workflow engine and the code review workflow configuration.

### 🤖 Assistant (19:15:55)

Now let me load the config source and the instructions file.

### 🤖 Assistant (19:16:08)

Good, I've loaded all workflow components. Let me resolve the variables:

- **user_name:** Michael
- **communication_language:** English
- **user_skill_level:** intermediate
- **planning_artifacts:** `/Users/michael/Projekte/peach/docs/planning-artifacts`
- **implementation_artifacts:** `/Users/michael/Projekte/peach/docs/implementation-artifacts`
- **sprint_status:** `/Users/michael/Projekte/peach/docs/implementation-artifacts/sprint-status.yaml`
- **template:** false (action-workflow, no output file needed)

This is an **adversarial code review** workflow. I need to identify which story to review. Let me check what stories are available.

### 🤖 Assistant (19:16:14)

I found the story files. Based on the recent git history, the most recent implementation is story 5.3. Which story would you like me to review?

### 🤖 Assistant (19:16:44)

## Step 1: Load Story and Discover Changes

Let me load the story file and discover the actual git changes.

### 🤖 Assistant (19:16:59)

Good. I've loaded the story and discovered git changes. Let me note the initial findings:

**Story Key:** `5-3-profile-preview-on-start-screen-and-navigation`
**Status:** review

**Git vs Story File List Cross-Reference:**
- Story File List matches git commit `60f1777` exactly (6 files)
- **Discrepancy:** `Peach/Resources/Localizable.xcstrings` is modified (uncommitted) but NOT in the story File List

Now let me discover input files (architecture, UX, epics) and read all implementation files.

### 🤖 Assistant (19:17:08)

Now let me load the planning artifacts and check the related source files for the full review.

### 🤖 Assistant (19:17:52)

Let me also check the uncommitted Localizable.xcstrings change and the sprint status.

### 🤖 Assistant (19:20:25)

I've now loaded all components. Let me summarize the discovery results:

- ✓ Loaded epic 5.3 acceptance criteria from epics.md
- ✓ Loaded UX spec for Profile Preview (comprehensive)
- ✓ Loaded all implementation files (4 source + 1 test)
- ✓ Git changes analyzed
- ○ No project-context.md found

## Step 2: Building Review Attack Plan

**Acceptance Criteria to verify:**
1. Profile Preview displayed — compact, same band shape, no labels, ~60-80pt
2. Tapping navigates to Profile Screen
3. Cold start placeholder looks intentional
4. VoiceOver: "Your pitch profile. Tap to view details." + threshold
5. Back navigation returns to Start Screen
6. Same rendering logic as full visualization (single implementation reuse)

**Tasks to audit:** 5 tasks, all marked `[x]`

**Review plan:**
1. AC Validation — verify each against implementation
2. Task Audit — verify each `[x]` is real
3. Code Quality — security, performance, maintainability
4. Test Quality — real assertions vs fakes

## Step 3: Executing Adversarial Review

Let me now deep-dive every file, cross-reference every claim, and find what's wrong.

### 🤖 Assistant (19:21:20)

## Step 4: Presenting Findings

---

**🔥 CODE REVIEW FINDINGS, Michael!**

**Story:** 5-3-profile-preview-on-start-screen-and-navigation.md
**Git vs Story Discrepancies:** 1 found
**Issues Found:** 2 High, 4 Medium, 3 Low

---

### 🔴 HIGH ISSUES (must fix)

**H1. `trainedAccessibilityLabel` test is a sham — doesn't test ProfilePreviewView at all**
`PeachTests/Start/ProfilePreviewViewTests.swift:30-44`

The test creates a `PerceptualProfile` with training data and sets up `EnvironmentValues`, but **never creates a ProfilePreviewView with that profile injected**. Instead, it independently computes the expected threshold and asserts `Int(avgThreshold) == 40`. This tests basic arithmetic, not the view's accessibility label in a trained state. The `#expect` on line 43 never touches ProfilePreviewView.

**H2. `trainedStateInstantiation` test is identical to cold start — doesn't inject training data**
`PeachTests/Start/ProfilePreviewViewTests.swift:17-19`

The test claims to verify "ProfilePreviewView can be instantiated with training data" but the body is `let _ = ProfilePreviewView()` — identical to `coldStartInstantiation`. No training data is injected into the environment. This test is redundant and falsely claims trained-state coverage. Task 5 is marked `[x]` but this subtask is not actually fulfilled.

---

### 🟡 MEDIUM ISSUES (should fix)

**M1. `Localizable.xcstrings` modified but uncommitted and not in File List**
`Peach/Resources/Localizable.xcstrings`

The old placeholder's accessibility string "Profile preview: Start training to build your profile" was removed from the strings catalog (correct — the placeholder was removed), but this file is:
- Not listed in the story's File List
- Not included in commit `60f1777`
- Sitting as an uncommitted modification

This is incomplete documentation and an incomplete commit.

**M2. Duplicated threshold computation — violates story's own reuse guidance**
`Peach/Start/ProfilePreviewView.swift:32-33` vs `Peach/Profile/ProfileScreen.swift:92`

ProfilePreviewView computes the average threshold independently:
```swift
let avgThreshold = trainedNotes.map { abs(profile.statsForNote($0).mean) }.reduce(0.0, +) / Double(trainedNotes.count)
```
This is identical logic to `ProfileScreen.accessibilitySummary()` (line 92). The story's own Dev Notes explicitly say "Reuse ProfileScreen.accessibilitySummary for VoiceOver label augmentation." If the threshold computation logic changes in ProfileScreen, ProfilePreviewView won't be updated.

**M3. Missing empty-trainedNotes guard — potential crash via `Int(NaN)`**
`Peach/Start/ProfilePreviewView.swift:32-34`

`hasTrainingData` checks `profile.overallMean != nil`, which covers ALL 128 MIDI notes. But the accessibility label filters only notes 36...84. If a note outside that range is trained (e.g., via direct `update()` call), `trainedNotes` would be empty → division by zero → `Double.nan` → `Int(NaN)` **crashes at runtime**. ProfileScreen guards against this on line 84-87 with a `guard !trainedNotes.isEmpty`. ProfilePreviewView does not.

**M4. `usesConfidenceBandDataPipeline` test doesn't verify ProfilePreviewView's usage**
`PeachTests/Start/ProfilePreviewViewTests.swift:48-66`

The test calls `ConfidenceBandData.prepare` twice with the same profile and compares results. Since `prepare` is deterministic, this always passes — it tests ConfidenceBandData's determinism, not that ProfilePreviewView actually calls it. The test name and task claim are misleading.

---

### 🟢 LOW ISSUES (nice to fix)

**L1. Cold start preview height is only 25pt vs spec's 60-80pt**
`Peach/Start/ProfilePreviewView.swift:18-19`

When `hasTrainingData` is false, only the 25pt PianoKeyboardView renders. The old placeholder was 150pt with a background and icon. The AC says "~60-80pt tall" and the UX spec says the preview should be "roughly ~60-80pt tall" overall. In cold start, 25pt is significantly shorter and may appear visually lost in the layout. The dev notes justify this as intentional, but it doesn't match the sizing spec.

**L2. Typo in test function name: "samesMidiRange"**
`PeachTests/Start/ProfilePreviewViewTests.swift:69`

Should be `sameMidiRange` (extra 's').

**L3. VoiceOver label ordering differs from UX spec**
`Peach/Start/ProfilePreviewView.swift:34`

UX spec says: "Your pitch profile. Average threshold: [X] cents. Tap to view details." (threshold before tap hint)
Implementation says: "Your pitch profile. Tap to view details. Average threshold: X cents." (threshold after tap hint)
The story AC matches the implementation, but the UX spec has a different order.

---

What should I do with these issues?

1. **Fix them automatically** — I'll update the code and tests
2. **Create action items** — Add to story Tasks/Subtasks for later
3. **Show me details** — Deep dive into specific issues

Choose [1], [2], or specify which issue to examine:

### 🧑 Human (19:22:22)

1

### 🤖 Assistant (19:23:57)

I'll fix all HIGH and MEDIUM issues now. Let me implement the fixes.

### 🤖 Assistant (19:24:10)

Starting with the foundation — extracting the shared threshold computation.

**Fix M2+M3: Add `averageThreshold(midiRange:)` to PerceptualProfile**

### 🤖 Assistant (19:24:31)

Now update **ProfilePreviewView** to use the shared method and add testability:

### 🤖 Assistant (19:24:37)

Now update **ProfileScreen** to use the shared method:

### 🤖 Assistant (19:24:52)

The code looks correct. SourceKit diagnostics are false positives (cross-file resolution issues). Let me now proceed to fix the tests.

### 🤖 Assistant (19:24:56)

**Fix H1+H2+M4+L2: Rewrite tests**

### 🤖 Assistant (19:25:14)

**Fix M1: Update story File List**

### 🤖 Assistant (19:25:24)

Now let me also update the story's change log and completion notes to reflect the review fixes:

### 🤖 Assistant (19:25:29)

Also need to update the File List to include files modified during review:

### 🤖 Assistant (19:25:41)

All fixes applied. Now let me run the full test suite to verify everything passes.

### 🤖 Assistant (19:33:54)

All tests pass. Now let me proceed to **Step 5: Update story status and sync sprint tracking**.

### 🤖 Assistant (19:35:18)

All **217 tests pass**. All HIGH and MEDIUM issues are fixed. Let me now update the story status and sync sprint tracking.

## Step 5: Update Story Status and Sync Sprint Tracking

All HIGH and MEDIUM issues are fixed, all ACs are implemented — setting status to **done**.

### 🤖 Assistant (19:35:36)

Sprint status synced: `5-3-profile-preview-on-start-screen-and-navigation` → done

---

**Review Complete!**

**Story Status:** done
**Issues Fixed:** 6 (2 High, 4 Medium)
**Action Items Created:** 0

### Summary of Fixes Applied

| Issue | Severity | Fix |
|-------|----------|-----|
| H1: `trainedAccessibilityLabel` test was a sham | HIGH | Rewrote to use static method with actual profile data |
| H2: `trainedStateInstantiation` identical to cold start | HIGH | Replaced with `accessibilityLabelNoNotesInRange` — tests NaN guard path |
| M1: `Localizable.xcstrings` not in File List | MEDIUM | Added to File List |
| M2: Duplicated threshold computation | MEDIUM | Extracted `PerceptualProfile.averageThreshold(midiRange:)`, used in both `ProfilePreviewView` and `ProfileScreen` |
| M3: Missing guard for `Int(NaN)` crash | MEDIUM | Fixed via `averageThreshold` returning `nil` when no trained notes in range |
| M4: Pipeline test didn't test ProfilePreviewView | MEDIUM | Renamed to honestly reflect what it tests |
| L2: Typo "samesMidiRange" | LOW | Fixed to `sameMidiRange` |

### Files Changed

- `Peach/Core/Profile/PerceptualProfile.swift` — added `averageThreshold(midiRange:)`
- `Peach/Start/ProfilePreviewView.swift` — extracted static `accessibilityLabel` method
- `Peach/Profile/ProfileScreen.swift` — uses shared `averageThreshold`
- `PeachTests/Start/ProfilePreviewViewTests.swift` — rewrote 3 broken/misleading tests
- `docs/implementation-artifacts/5-3-profile-preview-on-start-screen-and-navigation.md` — updated status, File List, Change Log
- `docs/implementation-artifacts/sprint-status.yaml` — synced to done

**217 tests pass, 0 failures, 0 regressions.**

### 🧑 Human (19:39:19)

Wrap it up.

### 🤖 Assistant (19:39:34)

Clean working tree. Committed as `82abbdb`.

---

[← Previous (4aad36a0dc)](4aad36a0dc.md) | [Index](index.md) | [Next (60f1777e0c) →](60f1777e0c.md)
