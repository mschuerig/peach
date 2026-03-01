---
commit: "eec3fc00ca56e0f61ab54856605fbe0a1593121a"
date: "2026-03-01T18:52:21+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Update sprint status: close epics 21–24, add epics 25–27"
sessions: ["dab326fa-ebfa-4f2c-bd7c-9bac01c6ba25"]
prev: "337ef50447.md"
next: "2f8f96806b.md"
---

[← Previous (337ef50447)](337ef50447.md) | [Index](index.md) | [Next (2f8f96806b) →](2f8f96806b.md)

# Commit eec3fc00ca

**Date:** 2026-03-01 18:52:21 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Update sprint status: close epics 21–24, add epics 25–27

Epics 21–24 promoted to done (all stories complete). Added three
new epics: 25 (Directed Intervals), 26 (Pitch Matching UX), and
27 (SoundFontNotePlayer Quality) with 7 new stories in backlog.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
docs/implementation-artifacts/sprint-status.yaml | 76 +++++++++++++++---------
 1 file changed, 48 insertions(+), 28 deletions(-)
```

## Session `dab326fa…`

*2026-03-01 17:34:58 UTC → 2026-03-01 17:52:23 UTC*

### 🧑 Human (17:34:58)

<command-message>bmad-bmm-sprint-planning</command-message>
<command-name>/bmad-bmm-sprint-planning</command-name>
<command-args>I'd like to do another round of planning. I've found some issues -- UX and internally -- and I'd like to finish the interval-based training.

The issues:
* Pitch Matching
  * The targetNote should only start when the user touches the slider. Rationale: When it starts immediately after the referenceNote, it tends to mask the memory of the referenceNote. Instead, the user should listen to the referenceNote and take as long as they like to remember it.
  * On the PitchMatchingScreen, the finger dragging the slider often obscures the feedback indicator. The feedback indicator should be moved closer to the top of the screen.
  * The current range of -100...+100 cents is far too wide. It should be reduced to -20...+20 cents.
* SoundFontNotePlayer
  * the play() method is too long and needs decomposition. As a general rule, when I look at a method/function, all operations within it should be at the same level of abstraction.
* SoundFontNotePlayer
  * I've experienced crashes, especially with the "Grand Piano" preset. At first the crashes seemed to be perfectly reproducible, but now this isn't the case anymore. In order to find the root cause, wWe need one or more tests that iterate over all presets and play them at a range of notes and durations.

Finally, features:

We now have trainings base on intervals. Currently, it is fixed to a perfect fifth upward and now is the time to extend it to all intervals up to an octave and upward and downward direction. Direction is implicit, so far, and we need to make it explicit, therefore we need a domain enum Direction for .up and .down and we need DirectedInterval that combines an interval with a direction. In all the places where we're currently using Interval, they probably need to be replaced by DirectedInterval.

On the Settings Screen, the user needs a way to select intervals for training. I'm thinking of a selector control like this

+-+--+--+--+--+--+--+--+--+--+--+--+--+--+
|⏶|P1|m2|M2|m3|M3|P4|d5|P5|m6|M6|m7|M7|P8|
+-+--+--+--+--+--+--+--+--+--+--+--+--+--+
|⏷|P1|m2|M2|m3|M3|P4|d5|P5|m6|M6|m7|M7|P8|
+-+--+--+--+--+--+--+--+--+--+--+--+--+--+


Active intervals should be marked (inverted?) in some way. The interval shortcut names should not be localized, but they should have localized help texts.</command-args>

### 🤖 Assistant (17:35:02)

Let me load the workflow engine and configuration files.

### 🤖 Assistant (17:35:05)

Now let me load the config, instructions, and template files.

### 🤖 Assistant (17:35:11)

Good, all workflow components loaded. Now let me execute the workflow steps. Starting with **Step 0.5: Document Discovery** and loading project context.

### 🤖 Assistant (17:35:18)

Found the epics file. Let me load it along with the existing sprint status and story files.

### 🤖 Assistant (17:35:22)

The epics file is very large. Let me read it in sections and get the other files separately.

### 🤖 Assistant (17:35:27)

Let me extract all epic and story headers from the epics file to get the complete inventory.

### 🤖 Assistant (17:36:42)

Good. All workflow components loaded and resolved. Here's what I've discovered:

---

**Document Discovery Results:**
- ✓ Loaded project context from `docs/project-context.md`
- ✓ Loaded epics from `docs/planning-artifacts/epics.md` (24 epics, ~90 stories)
- ✓ Loaded existing `sprint-status.yaml` (last generated 2026-02-22)
- ✓ Found 85 story files in `docs/implementation-artifacts/`

---

## Step 1: Parse Epic Files & Current Status Analysis

Michael, I've parsed all 24 epics. Here's the key finding:

**Stale statuses detected** — The existing sprint-status.yaml has Epics 21–24 marked as `in-progress`, but **all their stories are done**:

| Epic | Stories | All Done? | Current Status | Should Be |
|------|---------|-----------|----------------|-----------|
| Epic 21 | 21.1, 21.2, 21.3 | Yes | in-progress | **done** |
| Epic 22 | 22.1–22.5 | Yes | in-progress | **done** |
| Epic 23 | 23.1–23.4 | Yes | in-progress | **done** |
| Epic 24 | 24.1, 24.2 | Yes | in-progress | **done** |

All earlier epics (1–20) plus hotfixes and infrastructure items are correctly marked as `done`.

---

## New Work Items from Your Input

Your input describes **three categories** of new work that aren't yet in the epics file. Before I generate the updated sprint-status.yaml, we need to organize these. Here's my proposed grouping:

### Epic 25: Pitch Matching UX Refinements
- **Story 25.1**: Delay targetNote until slider touch — targetNote should only begin playing when the user first touches the slider, not automatically after the referenceNote
- **Story 25.2**: Reposition feedback indicator above slider — move it closer to the top of the screen so the dragging finger doesn't obscure it
- **Story 25.3**: Reduce pitch matching range to ±20 cents — change from ±100 to ±20 cents

### Epic 26: SoundFontNotePlayer Quality
- **Story 26.1**: Decompose play() method — extract sub-operations so each is at the same level of abstraction
- **Story 26.2**: Preset crash investigation tests — write tests that iterate over all presets at a range of notes and durations to find the root cause of the intermittent "Grand Piano" crashes

### Epic 27: Directed Intervals — Full Interval Training
- **Story 27.1**: Direction enum and DirectedInterval type — domain enum `.up`/`.down`, `DirectedInterval` combining `Interval` + `Direction`; replace `Interval` with `DirectedInterval` throughout the codebase
- **Story 27.2**: Interval selector on Settings Screen — two-row grid (⏶ up / ⏷ down) × 13 intervals (P1–P8), toggle active intervals, non-localized shortcut names with localized help texts

---

Does this grouping look right to you, Michael? Some questions:

1. **Epic 25 scope** — Are the three pitch matching issues independent enough to be separate stories, or would you prefer them combined (they all touch PitchMatchingScreen)?
2. **Story 27.1 scope** — Introducing `DirectedInterval` and replacing `Interval` everywhere is potentially a large story. Should it be split into (a) domain types + (b) migration?
3. **Work order** — Any priority preferences? I'd suggest: Epic 26.2 first (crash investigation before more features), then Epic 25 (UX fixes), then Epic 27 (new features).

<AskUserQuestion>
What adjustments would you like to the proposed epic/story organization?
</AskUserQuestion>

### 🧑 Human (17:45:34)

1: keep the issues in separate stories
2: keep 27.1 in a single story
3: Order: 27, 25, 26. Change the numbering accordingly.

### 🤖 Assistant (17:45:44)

Got it. Renumbered:

### Epic 25: Directed Intervals — Full Interval Training
- **Story 25.1**: Direction enum, DirectedInterval type, and replace Interval with DirectedInterval throughout
- **Story 25.2**: Interval selector on Settings Screen

### Epic 26: Pitch Matching UX Refinements
- **Story 26.1**: Delay targetNote until slider touch
- **Story 26.2**: Reposition feedback indicator above slider
- **Story 26.3**: Reduce pitch matching range to ±20 cents

### Epic 27: SoundFontNotePlayer Quality
- **Story 27.1**: Decompose play() method
- **Story 27.2**: Preset crash investigation tests

---

## Steps 2–4: Build Status Structure, Apply Detection & Generate

Now generating the updated sprint-status.yaml. Key changes:
- Epics 21–24 upgraded from `in-progress` → `done`
- Epics 25–27 added as `backlog` with all new stories

### 🤖 Assistant (17:45:54)

Now writing the updated sprint-status.yaml.

### 🤖 Assistant (17:47:27)

Sprint status file updated. Now let me run **Step 5: Validate and Report**.

**Validation Checklist:**

- [x] Every epic in epics file (1–24) appears in sprint-status.yaml
- [x] Every story in epics file appears in sprint-status.yaml
- [x] Every epic has a corresponding retrospective entry
- [x] New epics 25–27 added with all their stories
- [x] No status downgrades (all done items preserved)
- [x] Epics 21–24 upgraded from `in-progress` → `done` (all stories complete)
- [x] Epic 24 gained missing retrospective entry
- [x] All status values are legal
- [x] File is valid YAML syntax

---

## Sprint Status Generated Successfully

**File Location:** `docs/implementation-artifacts/sprint-status.yaml`

| Metric | Count |
|--------|-------|
| Total Epics | 27 |
| Total Stories | ~95 |
| Epics Done | 24 |
| Epics Backlog | 3 (new) |
| Stories Done | ~90 |
| Stories Backlog | 7 (new) |
| Open Hotfix | 1 (`hotfix-profile-band-segmentation`) |

**Changes in this update:**
- **Date** updated to 2026-03-01
- **Epics 21–24** promoted from `in-progress` → `done`
- **Epic 24** gained missing retrospective entry
- **Epic 25** added: Directed Intervals — Full Interval Training (2 stories)
- **Epic 26** added: Pitch Matching UX Refinements (3 stories)
- **Epic 27** added: SoundFontNotePlayer Quality (2 stories)

**Next steps:**
1. Create detailed story files for the new stories (use the create-story workflow)
2. Start with Epic 25 (Directed Intervals) as prioritized
3. Stories will transition `backlog` → `ready-for-dev` as story files are created

Would you like to proceed with creating the detailed story files, Michael?

### 🧑 Human (17:50:58)

commit

### 🤖 Assistant (17:51:06)

Let me check the current state and recent commit style.

### 🤖 Assistant (17:52:23)

Committed as `eec3fc0`.

---

[← Previous (337ef50447)](337ef50447.md) | [Index](index.md) | [Next (2f8f96806b) →](2f8f96806b.md)
