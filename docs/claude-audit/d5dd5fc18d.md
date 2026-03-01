---
commit: "d5dd5fc18da775e56806a747fae256d583b2459e"
date: "2026-02-17T19:40:38+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Code review fixes for Story 5.2: fix accessibility, previews, singular cents"
sessions: ["bef56148-b466-4435-80db-6caa6b9b875b"]
prev: "69db2898bd.md"
next: "f3763d3280.md"
---

[← Previous (69db2898bd)](69db2898bd.md) | [Index](index.md) | [Next (f3763d3280) →](f3763d3280.md)

# Commit d5dd5fc18d

**Date:** 2026-02-17 19:40:38 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Code review fixes for Story 5.2: fix accessibility, previews, singular cents

- Fix empty string "" polluting Localizable.xcstrings, use "Summary statistics" label
- Add TrendAnalyzer with data to previews so trend arrow is visible
- Handle singular "1 cent" vs plural "cents" in formatting and accessibility
- Simplify redundant sign computation in TrendAnalyzer.comparisonCompleted
- Remove test-only formatMean/formatStdDev non-optional overloads
- Add trendSymbol SF Symbol mapping test
- Update story File List and task 2.7 description to match implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
Peach/Core/Profile/TrendAnalyzer.swift             |  4 +--
 Peach/Profile/ProfileScreen.swift                  | 11 ++++++++
 Peach/Profile/SummaryStatisticsView.swift          | 33 +++++++++++++---------
 Peach/Resources/Localizable.xcstrings              |  7 +++--
 PeachTests/Profile/SummaryStatisticsTests.swift    | 11 +++++++-
 .../5-2-summary-statistics-with-trend-indicator.md |  6 ++--
 docs/implementation-artifacts/sprint-status.yaml   |  2 +-
 7 files changed, 51 insertions(+), 23 deletions(-)
```

## Session `bef56148…`

*2026-02-17 18:14:27 UTC → 2026-02-17 18:40:43 UTC*

### 🧑 Human (18:14:27)

<command-message>bmad-bmm-code-review</command-message>
<command-name>/bmad-bmm-code-review</command-name>

### 🤖 Assistant (18:14:37)

Now let me load the config source and the instructions file.

### 🤖 Assistant (18:14:52)

Good, I've loaded the workflow configuration. All variables resolved:

- **user_name**: Michael
- **communication_language**: English
- **user_skill_level**: intermediate
- **planning_artifacts**: `docs/planning-artifacts`
- **implementation_artifacts**: `docs/implementation-artifacts`
- **template**: false (action-workflow)

This is an **adversarial code review** workflow. Let me begin executing the instructions.

---

## Step 1: Load story and discover changes

No `{{story_path}}` was provided. Let me find available story files.

### 🤖 Assistant (18:15:07)

I found the story files. The working directory is clean (no uncommitted changes). Based on recent commit history, the most recently implemented story is **5.2: Summary Statistics with Trend Indicator**.

Which story would you like me to review? The most recent ones are:

- `5-2-summary-statistics-with-trend-indicator.md` (most recent - just committed)
- `5-1-profile-screen-with-perceptual-profile-visualization.md`

Or specify another story from the list.

### 🤖 Assistant (18:17:21)

Reviewing **Story 5.2: Summary Statistics with Trend Indicator**. Let me load the story file and discover all changes.

### 🤖 Assistant (18:17:41)

Good. I've loaded the story. Let me cross-reference git changes with the story's File List:

**Git changes (c146eaf..f3763d3):** 9 files
**Story File List:** 8 files

**Discrepancy found:** `Peach/Resources/Localizable.xcstrings` appears in git diff but is **missing from the Dev Agent Record File List** — despite being mentioned in the story's own Project Structure Notes section!

Now let me execute the `discover_inputs` protocol and load all implementation files for review.

### 🤖 Assistant (18:18:27)

Let me check a few more files for the deep review.

### 🤖 Assistant (18:22:10)

I've now read all implementation files, the story, the planning artifacts, and cross-referenced git changes. I have everything I need for the adversarial review.

---

## Step 2: Review Attack Plan

**Acceptance Criteria to validate:**
1. Mean, StdDev, trend indicator displayed with training data
2. Dashes and hidden trend on cold start
3. Statistics derived from stored per-answer data (FR26)

**Tasks to audit:** 7 tasks, 30 subtasks, all marked [x]

**Review dimensions:** AC validation, task audit, code quality, test quality, git/story consistency

---

## Step 3: Adversarial Review Execution

### Git vs Story File List Cross-Reference

| File | In Git | In Story File List |
|------|--------|--------------------|
| `Peach/Profile/SummaryStatisticsView.swift` | Yes | Yes |
| `Peach/Core/Profile/TrendAnalyzer.swift` | Yes | Yes |
| `PeachTests/Profile/TrendAnalyzerTests.swift` | Yes | Yes |
| `PeachTests/Profile/SummaryStatisticsTests.swift` | Yes | Yes |
| `Peach/Profile/ProfileScreen.swift` | Yes | Yes |
| `Peach/App/PeachApp.swift` | Yes | Yes |
| `Peach/Resources/Localizable.xcstrings` | Yes | **MISSING** |
| `docs/implementation-artifacts/sprint-status.yaml` | Yes | Yes |

**1 discrepancy found.**

### AC Validation
- **AC 1**: IMPLEMENTED - Mean, StdDev, and trend all display correctly with training data
- **AC 2**: IMPLEMENTED - Cold start shows "—" dashes, trend hidden via `if let`
- **AC 3**: IMPLEMENTED - TrendAnalyzer uses raw ComparisonRecords; PerceptualProfile populated from stored records at startup

### Task Audit Findings
- **Task 2.7** marked [x]: "Store baseline and recent statistics for efficient incremental computation" — **NOT DONE AS DESCRIBED**. Implementation stores ALL raw offsets in a growing `[Double]` array and recomputes from scratch every time. No baseline/recent split is stored.
- **Task 4.4** marked [x]: "Update previews to include statistics with various data states" — **PARTIALLY DONE**. No preview injects a `TrendAnalyzer` with records, so the trend indicator is never visible in any preview.

---

**Here are my findings, Michael:**

## **CODE REVIEW FINDINGS**

**Story:** 5-2-summary-statistics-with-trend-indicator.md
**Git vs Story Discrepancies:** 1 found
**Issues Found:** 0 High, 5 Medium, 3 Low

---

### MEDIUM ISSUES

**M1. `Localizable.xcstrings` missing from Dev Agent File List**
File changed in git (3 new string entries added) but not documented in the story's Dev Agent Record File List. The story's own "Project Structure Notes" section says to modify it, but the completion record omits it.
- File: `docs/implementation-artifacts/5-2-summary-statistics-with-trend-indicator.md` (File List section)

**M2. Empty string key `""` polluting Localizable.xcstrings**
An empty string key `"" : {}` was added to the string catalog. This is noise caused by `SummaryStatisticsView.swift:38`:
```swift
.accessibilityLabel(stats == nil ? "No training data yet" : "")
```
The `""` literal gets extracted by Xcode as a localizable string. Fix: conditionally apply the modifier instead of passing an empty string.
- File: `Peach/Profile/SummaryStatisticsView.swift:38`

**M3. Task 2.7 description mismatch — no incremental computation**
Task 2.7 claims "Store baseline and recent statistics for efficient incremental computation" but the implementation stores ALL raw offsets in `absOffsets: [Double]` and calls `recompute()` from scratch on every `comparisonCompleted()`. The task checkbox is misleading about what was actually implemented. While the Dev Notes mention this simpler approach as acceptable for MVP, the task text should reflect reality.
- File: `Peach/Core/Profile/TrendAnalyzer.swift:33,44-71,80`

**M4. No preview demonstrates the trend indicator**
Task 4.4 claims "Update previews to include statistics with various data states" but neither `ProfileScreen` nor `SummaryStatisticsView` previews inject a `TrendAnalyzer` with sufficient records. The default environment TrendAnalyzer has no records → `trend == nil` → arrow never visible. There is no way to preview the trend arrow in Xcode.
- File: `Peach/Profile/SummaryStatisticsView.swift:146-160`, `Peach/Profile/ProfileScreen.swift:99-119`

**M5. "1 cents" — no singular form handling**
`formatMean(1.2)` returns `"1 cents"`. While "cents" as a music theory unit is sometimes used uncountably, the test at `SummaryStatisticsTests.swift:71` explicitly asserts `"1 cents"` as correct. For localized apps (especially German with different pluralization rules), this should use proper plural handling or at minimum the singular form "1 cent".
- File: `Peach/Profile/SummaryStatisticsView.swift:108-109`

---

### LOW ISSUES

**L1. Redundant sign computation in `TrendAnalyzer.comparisonCompleted()`**
```swift
let centOffset = comparison.isSecondNoteHigher ? comparison.centDifference : -comparison.centDifference
absOffsets.append(abs(centOffset))
```
`Comparison.centDifference` is documented as "always positive magnitude" (`Comparison.swift:19`). This code computes a signed value then immediately takes `abs()`, which always yields `centDifference`. The entire block simplifies to `absOffsets.append(comparison.centDifference)`.
- File: `Peach/Core/Profile/TrendAnalyzer.swift:78-80`

**L2. Non-optional `formatMean(_: Double)` / `formatStdDev(_: Double)` overloads are test-only convenience**
These overloads wrap the value in `Optional()` and delegate. They're never called in production code — only from `SummaryStatisticsTests.swift:70-76`. Adds unnecessary public API surface to the view.
- File: `Peach/Profile/SummaryStatisticsView.swift:112-114,121-123`

**L3. No test coverage for `trendSymbol()` SF Symbol mapping**
The AC explicitly defines which SF Symbol corresponds to each trend (arrow.down.right = improving, arrow.right = stable, arrow.up.right = declining). There's no test verifying this mapping is correct. A simple parameterized test would lock it down.
- File: `PeachTests/Profile/TrendAnalyzerTests.swift` (missing test)

---

What should I do with these issues?

1. **Fix them automatically** — I'll update the code and tests
2. **Create action items** — Add to story Tasks/Subtasks for later
3. **Show me details** — Deep dive into specific issues

Choose [1], [2], or specify which issue to examine.

### 🧑 Human (18:25:44)

1

### 🤖 Assistant (18:27:50)

Fixing all HIGH and MEDIUM issues automatically, plus the LOW issues since they're straightforward. Let me read one more file then start applying fixes.

### 🤖 Assistant (18:28:03)

Now applying all fixes. Let me do the source code changes in parallel.

### 🤖 Assistant (18:33:21)

Those diagnostics are stale SourceKit errors (can't resolve cross-file types outside Xcode). Continuing with the remaining fixes.

### 🤖 Assistant (18:33:26)

Now fix the preview to include TrendAnalyzer (M4).

### 🤖 Assistant (18:33:36)

Now fix the remaining files in parallel.

### 🤖 Assistant (18:33:57)

Now update the tests.

### 🤖 Assistant (18:34:03)

Now add the trendSymbol test (L3).

### 🤖 Assistant (18:34:12)

Good. All source code and test fixes applied. Now let me run the full test suite to verify.

### 🤖 Assistant (18:36:04)

**ALL TESTS PASSED.** Now let me update the story file with the review fixes.

### 🤖 Assistant (18:36:08)

Now let me update the story file with all the review fixes: M1 (File List), M3 (Task 2.7 text), and the dev agent record.

### 🤖 Assistant (18:36:28)

Good. Now let me proceed to **Step 5: Update story status and sync sprint tracking**.

### 🤖 Assistant (18:36:31)

Now check and sync the sprint status.

### 🤖 Assistant (18:36:52)

Sprint status synced: 5-2-summary-statistics-with-trend-indicator → done

---

## Review Complete!

**Story Status:** done
**Issues Fixed:** 5 Medium + 3 Low = 8 total
**Action Items Created:** 0

### Summary of fixes applied:

| Issue | Fix |
|-------|-----|
| **M1** File List missing `Localizable.xcstrings` | Added to Dev Agent File List |
| **M2** Empty string `""` in Localizable.xcstrings | Changed to `"Summary statistics"` accessibility label; removed `""` key from xcstrings |
| **M3** Task 2.7 description mismatch | Updated text to reflect actual simple-recompute implementation |
| **M4** No preview shows trend indicator | Injected `TrendAnalyzer` with 20 records into both SummaryStatisticsView and ProfileScreen "With Data" previews |
| **M5** "1 cents" grammatical error | Added singular/plural handling: "1 cent" vs "N cents" in display and accessibility labels |
| **L1** Redundant sign computation | Simplified `comparisonCompleted` to `absOffsets.append(completed.comparison.centDifference)` |
| **L2** Test-only format overloads | Removed non-optional `formatMean(_: Double)` and `formatStdDev(_: Double)` overloads |
| **L3** No trendSymbol test | Added `trendSymbols()` test verifying all 3 SF Symbol mappings |

**All tests pass** (full suite). Test count: 20 in story scope (8 SummaryStatistics + 12 TrendAnalyzer).

### 🧑 Human (18:40:24)

commit this

### 🤖 Assistant (18:40:43)

Committed as `d5dd5fc`. All 7 files staged, working tree clean.

---

[← Previous (69db2898bd)](69db2898bd.md) | [Index](index.md) | [Next (f3763d3280) →](f3763d3280.md)
