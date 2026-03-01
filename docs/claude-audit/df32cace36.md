---
commit: "df32cace36ec6fec0bb71d4c7655fe1b25ed00cf"
date: "2026-02-24T23:16:59+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Fix code review findings for 10-2-rename-amplitude-to-velocity"
sessions: ["34c53b09-42eb-48aa-b7d8-e7c9009fe6c9"]
prev: "4747cdb5f9.md"
next: "ba8a9839ec.md"
---

[← Previous (4747cdb5f9)](4747cdb5f9.md) | [Index](index.md) | [Next (ba8a9839ec) →](ba8a9839ec.md)

# Commit df32cace36

**Date:** 2026-02-24 23:16:59 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Fix code review findings for 10-2-rename-amplitude-to-velocity

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
Peach/Training/TrainingSession.swift                   |  2 +-
 PeachTests/Core/Audio/SoundFontNotePlayerTests.swift   | 18 +++++++++++++++++-
 .../10-2-rename-amplitude-to-velocity.md               |  7 ++++---
 docs/implementation-artifacts/sprint-status.yaml       |  2 +-
 4 files changed, 23 insertions(+), 6 deletions(-)
```

## Session `34c53b09…`

*2026-02-24 22:07:47 UTC → 2026-02-24 22:17:18 UTC*

### 🧑 Human (22:07:47)

<command-message>bmad-bmm-code-review</command-message>
<command-name>/bmad-bmm-code-review</command-name>
<command-args>10-2</command-args>

### 🤖 Assistant (22:07:50)

I'll start by loading the workflow execution framework and the code review workflow configuration.

### 🤖 Assistant (22:07:55)

Now let me load the config source and the instructions file, plus the validation checklist.

### 🤖 Assistant (22:08:07)

Good. All variables resolved:
- **user_name**: Michael
- **communication_language**: English
- **user_skill_level**: intermediate
- **planning_artifacts**: `docs/planning-artifacts`
- **implementation_artifacts**: `docs/implementation-artifacts`
- **sprint_status**: `docs/implementation-artifacts/sprint-status.yaml`
- **epic_num**: 10, **story_num**: 2 (from argument "10-2")
- **template**: false → action-workflow

---

## Step 1: Load story and discover changes

Let me find the story file, discover git changes, and load all input files.

### 🤖 Assistant (22:08:17)

Now let me load the story file, architecture, project context, and check the commit changes for story 10.2.

### 🤖 Assistant (22:08:34)

Good. Git working tree is clean — all changes were committed in `ba8a983`. The story File List matches git exactly (10 files). No discrepancies.

**Input Discovery Results:**
- ✓ Loaded architecture from `docs/planning-artifacts/architecture.md`
- ✓ Loaded project context from `docs/project-context.md`
- ✓ Epic file found at `docs/planning-artifacts/epics.md` (need to load for epic 10)
- ○ No sharded architecture or UX files

Now let me load all source files for the adversarial review.

### 🤖 Assistant (22:08:43)

Good, all 8 source files loaded. Now let me verify the "no remaining amplitude references" claim and check sprint status.

### 🤖 Assistant (22:11:03)

All files loaded. Now executing **Step 2: Build review attack plan** and **Step 3: Adversarial review**.

---

## Step 2: Review Attack Plan

**Acceptance Criteria to validate:**
1. AC#1: Protocol signature → `play(frequency:duration:velocity:)` with `velocity: UInt8`
2. AC#2: `midiVelocity(forAmplitude:)` helper removed, velocity passed directly
3. AC#3: Velocity validation 0-127, error renamed `AudioError.invalidVelocity`
4. AC#4: `TrainingSession.amplitude: Double = 0.5` → `velocity: UInt8 = 63`
5. AC#5: `MockNotePlayer.lastAmplitude` → `lastVelocity`, history tuple retyped
6. AC#6: All tests pass, no audible behavior changes

**Task audit:** All 9 tasks marked `[x]`

**Git vs Story File List:** Exact match — 10 files in both. No discrepancies.

---

## Step 3: Adversarial Review Execution

### AC Validation

| AC | Status | Evidence |
|---|---|---|
| AC#1 | IMPLEMENTED | `NotePlayer.swift:38` — `func play(frequency: Double, duration: TimeInterval, velocity: UInt8) async throws` |
| AC#2 | IMPLEMENTED | `SoundFontNotePlayer.swift:155` — `sampler.startNote(midiNote, withVelocity: velocity, onChannel: Self.channel)`. No `midiVelocity` helper exists. |
| AC#3 | PARTIAL | `SoundFontNotePlayer.swift:130-134` validates **1-127**, not 0-127 as AC states. Error renamed correctly. Design decision documented in Dev Notes, but AC wording doesn't match implementation. |
| AC#4 | IMPLEMENTED | `TrainingSession.swift:139` — `private let velocity: UInt8 = 63`. Both play() calls at lines 401, 412 pass `velocity: velocity`. |
| AC#5 | IMPLEMENTED | `MockNotePlayer.swift:12-13,34-39,67` — all properties renamed, tuple retyped, reset updated. |
| AC#6 | IMPLEMENTED | Zero "amplitude" references in Swift files. Git working tree clean (commit made). |

### Task Audit

All 9 tasks checked — evidence confirms each is genuinely complete. No false `[x]` marks found.

### Grep Verification

Zero "amplitude" references remain in `.swift` files. Story claim verified.

---

**CODE REVIEW FINDINGS, Michael!**

**Story:** `docs/implementation-artifacts/10-2-rename-amplitude-to-velocity.md`
**Git vs Story Discrepancies:** 0 found
**Issues Found:** 0 High, 3 Medium, 3 Low

## MEDIUM Issues

### M1: Missing velocity boundary test for values > 127

`SoundFontNotePlayerTests.swift` — Tests cover velocity 0 (rejected), 63 (valid), and 127 (max valid). But `UInt8` allows 128-255, and there's **no test verifying these out-of-range values are rejected**. The guard at `SoundFontNotePlayer.swift:130` handles it (`velocity <= 127`), but the new velocity validation tests don't exercise this upper boundary.

**Fix:** Add a test like `velocity128_rejected()` that passes `velocity: 128` and expects `AudioError.invalidVelocity`.

### M2: Test assertion doesn't match test description

`SoundFontNotePlayerTests.swift:98-103` — Test is named "Velocity 0 is rejected with **invalidVelocity** error" but the assertion only checks `throws: AudioError.self`, not the specific error case. If the engine threw `.engineStartFailed` for some reason, this test would still pass. The test title promises more specificity than the assertion delivers.

**Fix:** Use a closure-based assertion to verify the specific `AudioError.invalidVelocity` case.

### M3: AC#3 wording doesn't match implementation

AC#3 says "validation checks velocity in the range **0-127**" but `SoundFontNotePlayer.swift:130` validates **1-127** (rejecting velocity 0). The Dev Notes explicitly document this design decision ("reject velocity 0 to preserve the current safety floor"), which is the correct behavior. But the AC should be updated to reflect what was actually implemented.

**Fix:** Update AC#3 to say "1-127" instead of "0-127".

## LOW Issues

### L1: TrainingSession velocity comment says (0-127) but valid range is (1-127)

`TrainingSession.swift:138` — Comment reads `/// MIDI velocity for note playback (0-127)` but the app rejects velocity 0 at the `SoundFontNotePlayer` level. Mildly misleading.

**Fix:** Change comment to `/// MIDI velocity for note playback (1-127)`.

### L2: Architecture doc has outdated NotePlayer signature

`architecture.md:290` — Still says `play(frequency:, duration:, envelope:)`. Should now say `play(frequency:, duration:, velocity:)`. Pre-existing issue (was already wrong before this story), not a regression.

### L3: Validation order in SoundFontNotePlayer.play()

`SoundFontNotePlayer.swift:104-134` — Input validation (frequency, duration, velocity) happens **after** preset loading (which includes a 20ms sleep). Invalid inputs still trigger the expensive preset load before being rejected. Pre-existing issue maintained, not a regression from this story.

---

What should I do with these issues?

1. **Fix them automatically** — I'll update the code and tests
2. **Create action items** — Add to story Tasks/Subtasks for later
3. **Show me details** — Deep dive into specific issues

Choose [1], [2], or specify which issue to examine:

### 🧑 Human (22:12:19)

1

### 🤖 Assistant (22:13:12)

Fixing all HIGH and MEDIUM issues now. I'll also fix L1 since it's trivial.

### 🤖 Assistant (22:13:57)

Good. All fixes applied. Now let me run the full test suite to verify.

### 🤖 Assistant (22:14:48)

**TEST SUCCEEDED** — all tests pass including the new `velocity128_rejected` test.

Now let me update the story file with the review fixes in the Dev Agent Record.

### 🤖 Assistant (22:15:05)

Now let me proceed to **Step 5: Update story status and sync sprint tracking**.

All 3 MEDIUM issues are fixed, all ACs are now fully implemented, and all tests pass. Setting status to **done**.

### 🤖 Assistant (22:15:19)

Sprint status synced: `10-2-rename-amplitude-to-velocity` → done

---

## Review Complete!

**Story Status:** done
**Issues Fixed:** 3 (all MEDIUM)
**Action Items Created:** 0

### Fixes Applied

| Issue | Fix | File |
|---|---|---|
| **M1**: Missing velocity > 127 test | Added `velocity128_rejected()` test with specific error case verification | `SoundFontNotePlayerTests.swift` |
| **M2**: Weak test assertion | Updated `velocity0_rejected()` to verify `AudioError.invalidVelocity` case, not just `AudioError.self` | `SoundFontNotePlayerTests.swift` |
| **M3**: AC#3 says 0-127, impl is 1-127 | Updated AC wording to say "1-127" with explanation | `10-2-rename-amplitude-to-velocity.md` |
| **L1**: Comment says (0-127) | Changed to (1-127) | `TrainingSession.swift:138` |

### LOW Issues Not Fixed (out of scope)

- **L2**: Architecture doc outdated `play(frequency:, duration:, envelope:)` — pre-existing, not introduced by this story
- **L3**: Validation order after preset loading — pre-existing performance issue

Full test suite passes. Code review complete!

### 🧑 Human (22:16:50)

commit this

### 🤖 Assistant (22:17:02)

Committed as `df32cac`. Working tree clean.

### 🧑 Human (22:17:18)

<command-name>/exit</command-name>
            <command-message>exit</command-message>
            <command-args></command-args>

### 🧑 Human (22:17:18)

<local-command-stdout>See ya!</local-command-stdout>

---

[← Previous (4747cdb5f9)](4747cdb5f9.md) | [Index](index.md) | [Next (ba8a9839ec) →](ba8a9839ec.md)
