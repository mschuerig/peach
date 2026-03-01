---
commit: "bc67fdd5fc614e5e2fb8ef49422b74ab7acf00e5"
date: "2026-02-27T17:20:08+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Insert story 20.3: Move NoteDuration to Core/Audio, renumber 20.3–20.10 to 20.4–20.11"
sessions: ["9195567b-8c9f-43d9-9c4b-0d2f9f466aed"]
prev: "e3b4a695e7.md"
next: "a1c7568942.md"
---

[← Previous (e3b4a695e7)](e3b4a695e7.md) | [Index](index.md) | [Next (a1c7568942) →](a1c7568942.md)

# Commit bc67fdd5fc

**Date:** 2026-02-27 17:20:08 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Insert story 20.3: Move NoteDuration to Core/Audio, renumber 20.3–20.10 to 20.4–20.11

NoteDuration was overlooked in story 20.1 when shared domain types were moved to
Core/. This adds a new story to complete the pattern (identical to the SoundSourceID
move in 20.2) and renumbers all subsequent stories in Epic 20 across story files,
sprint-status.yaml, and epics.md.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
...inject-trainingdatastore-into-settingsscreen.md |  97 +++++++++++++++
 .../20-10-update-documentation.md                  | 125 --------------------
 .../20-11-update-documentation.md                  | 125 ++++++++++++++++++++
 .../20-3-move-noteduration-to-core-audio.md        | 107 +++++++++++++++++
 ...-cross-feature-feedback-icon-size-dependency.md |  72 ------------
 ...-cross-feature-feedback-icon-size-dependency.md |  72 ++++++++++++
 .../20-4-use-protocols-in-profile-views.md         |  78 -------------
 ...0-5-extract-entry-environment-keys-from-core.md | 130 ---------------------
 .../20-5-use-protocols-in-profile-views.md         |  78 +++++++++++++
 ...0-6-extract-entry-environment-keys-from-core.md | 130 +++++++++++++++++++++
 ...e-uikit-from-audiosessioninterruptionmonitor.md |  99 ----------------
 ...e-uikit-from-audiosessioninterruptionmonitor.md |  99 ++++++++++++++++
 ...-7-resettable-protocol-for-comparisonsession.md | 110 -----------------
 ...ove-mockhapticfeedbackmanager-to-test-target.md |  84 -------------
 ...-8-resettable-protocol-for-comparisonsession.md | 110 +++++++++++++++++
 ...inject-trainingdatastore-into-settingsscreen.md |  97 ---------------
 ...ove-mockhapticfeedbackmanager-to-test-target.md |  84 +++++++++++++
 docs/implementation-artifacts/sprint-status.yaml   |  17 +--
 docs/planning-artifacts/epics.md                   |  29 +++--
 19 files changed, 932 insertions(+), 811 deletions(-)
```

## Session `9195567b…`

*2026-02-27 16:06:34 UTC → 2026-02-27 16:20:50 UTC*

### 🧑 Human (16:06:34)

<command-message>bmad-bmm-create-story</command-message>
<command-name>/bmad-bmm-create-story</command-name>
<command-args>In story 20.1 there was an oversight: NoteDuration was still left in Settings, when it ought to have been moved to Core/Audio. Insert a story to fix this after the last story marked as "done". Look for further domain types that should be moved to Core.</command-args>

### 🤖 Assistant (16:06:37)

I'll start by loading the workflow engine and the specific workflow configuration.

### 🤖 Assistant (16:06:42)

Now I'll load the config source and all workflow components in parallel.

### 🤖 Assistant (16:06:59)

Now I have all workflow components loaded. Let me resolve the variables and proceed with **Step 1: Determine target story**.

The user wants to **insert a new story** in Epic 20 after the last "done" story. Let me load the sprint status and epics file to understand the current state.

### 🤖 Assistant (16:07:13)

Good. I can see that in Epic 20, stories 20.1 and 20.2 are "done", and 20.3 through 20.10 are "ready-for-dev". The user wants to insert a new story after 20.2 (the last "done" story). Let me now load the relevant artifacts in parallel.

### 🤖 Assistant (16:11:58)

Now let me load the Epic 20 section from the epics file and the previous story files.

### 🤖 Assistant (16:12:43)

Excellent. I have all the context I need. Let me verify the exact locations of `NoteDuration` files.

### 🤖 Assistant (16:12:48)

Let me quickly read the `NoteDuration` files to understand their exact content.

### 🤖 Assistant (16:13:12)

All analysis is complete. Here's the summary of my findings:

**NoteDuration Analysis:**
- `NoteDuration` is a pure domain value type (Hashable, Comparable, Sendable) in `Peach/Settings/NoteDuration.swift`
- Identical in nature to `SoundSourceID`, `MIDINote`, `Frequency`, `Cents`, `AmplitudeDB`, `MIDIVelocity` — all of which already live in `Core/Audio/`
- Used by `ComparisonSession` and `PitchMatchingSession` via `UserSettings` protocol — no Settings-specific logic
- `NoteDurationTests.swift` exists in `PeachTests/Settings/`
- This follows the exact same pattern as story 20.2 (SoundSourceID move)

**Domain type scan:** `NoteDuration` is the **only** remaining domain type misplaced outside Core/. All other types in Settings/ and feature folders are correctly positioned.

**New story:** 20.3 — Move NoteDuration to Core/Audio (existing 20.3–20.10 shift to 20.4–20.11)

---

Now proceeding to **Step 5: Create the story file**.

Here's the **story header and requirements** section:

---

**Story 20.3: Move NoteDuration to Core/Audio/**

As a **developer maintaining Peach**,
I want `NoteDuration` moved from `Settings/` to `Core/Audio/`,
So that all audio domain value types are co-located in `Core/Audio/`, the `UserSettings` protocol references only `Core/` types, and no Core/ consumer depends on Settings/.

**Acceptance Criteria:**

1. **`NoteDuration.swift` lives in `Core/Audio/`** — `Peach/Settings/NoteDuration.swift` is moved to `Peach/Core/Audio/NoteDuration.swift`. The original file no longer exists.
2. **`NoteDurationTests.swift` lives in test mirror** — `PeachTests/Settings/NoteDurationTests.swift` is moved to `PeachTests/Core/Audio/NoteDurationTests.swift`.
3. **`UserSettings` protocol references only Core/ types** — After the move, every type in the `UserSettings` protocol signature (`SoundSourceID`, `NoteDuration`, `MIDINote`, `Frequency`, `UnitInterval`) is defined in `Core/`.
4. **Zero code changes required** — Single-module app; types resolved by name.
5. **All existing tests pass** — Full test suite passes with zero regressions.

---

[a] Advanced Elicitation, [c] Continue, [p] Party-Mode, [y] YOLO the rest of this document only?

### 🧑 Human (16:13:59)

y

### 🤖 Assistant (16:14:04)

YOLO mode activated. Generating the complete story file and handling all updates.

### 🤖 Assistant (16:14:56)

Story file created. Now handling **Step 6: Update sprint status and renumber existing stories**.

Since this is an insertion, I need to renumber existing stories 20.3–20.10 to 20.4–20.11. Let me rename the story files and update sprint-status.yaml.

### 🤖 Assistant (16:15:38)

The glob matched multiple files. Let me rename them explicitly by full name.

### 🤖 Assistant (16:15:52)

Most renames succeeded. Just need to rename the old 20-3 to 20-4.

### 🤖 Assistant (16:15:56)

All files renamed correctly. Now let me update the story titles inside each renamed file and update sprint-status.yaml.

### 🤖 Assistant (16:16:11)

Now updating story numbers in all renamed files and sprint-status.yaml in parallel.

### 🤖 Assistant (16:16:21)

All story titles updated. Now updating sprint-status.yaml with the new story and renumbered keys.

### 🤖 Assistant (16:16:29)

Now let me also update the epics.md to reflect the new story and renumbered stories.

### 🤖 Assistant (16:16:42)

Now renumber the remaining stories in epics.md (20.3→20.4 through 20.10→20.11).

### 🤖 Assistant (16:17:48)

Now let me verify the final state of sprint-status.yaml for Epic 20 and do a quick consistency check.

### 🤖 Assistant (16:17:55)

Everything is consistent. Let me verify the story files also match.

### 🤖 Assistant (16:18:10)

All 11 story files have correct numbering. Everything is consistent across all three artifacts.

---

**ULTIMATE BMad Method STORY CONTEXT CREATED, Michael!**

**Story Details:**
- Story ID: 20.3
- Story Key: `20-3-move-noteduration-to-core-audio`
- File: `docs/implementation-artifacts/20-3-move-noteduration-to-core-audio.md`
- Status: ready-for-dev

**Domain Type Scan Result:** `NoteDuration` is the **only** remaining domain type misplaced outside Core/. No further candidates found — all other types in Settings/ and feature folders are correctly positioned.

**Renumbering Applied:**
- New story 20.3 inserted (Move NoteDuration to Core/Audio/)
- Former stories 20.3–20.10 renumbered to 20.4–20.11
- Updated: 8 story files (titles), `sprint-status.yaml` (keys), `epics.md` (section headers)

**Next Steps:**
1. Review the story in `docs/implementation-artifacts/20-3-move-noteduration-to-core-audio.md`
2. Run `dev-story` for implementation
3. Run `code-review` when complete

### 🧑 Human (16:19:50)

commit

### 🤖 Assistant (16:20:15)

Committed as `bc67fdd`. Git correctly detected the renames (98-99% similarity). Working tree is clean.

### 🧑 Human (16:20:50)

<command-name>/exit</command-name>
            <command-message>exit</command-message>
            <command-args></command-args>

### 🧑 Human (16:20:50)

<local-command-stdout>Bye!</local-command-stdout>

---

[← Previous (e3b4a695e7)](e3b4a695e7.md) | [Index](index.md) | [Next (a1c7568942) →](a1c7568942.md)
