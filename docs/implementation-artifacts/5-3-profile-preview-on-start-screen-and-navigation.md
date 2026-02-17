# Story 5.3: Profile Preview on Start Screen and Navigation

Status: review

## Story

As a **musician using Peach**,
I want to see a miniature of my pitch profile on the Start Screen that I can tap to see details,
so that I can glance at my progress without navigating away.

## Acceptance Criteria

1. The Start Screen displays a Profile Preview — a compact, simplified version of the full profile visualization (same confidence band shape, no axis labels, no note names, no numerical values), sized ~full width, ~60-80pt tall
2. Tapping the Profile Preview navigates to the full Profile Screen
3. When no training data exists (cold start), the preview shows a placeholder shape that looks intentional, not broken
4. VoiceOver announces "Your pitch profile. Tap to view details." (with threshold data if available)
5. Dismissing the Profile Screen (back navigation or swipe) returns to the Start Screen
6. The preview shares the same rendering logic as the full visualization, scaled down and stripped of labels (single implementation reuse)

## Tasks / Subtasks

- [x] Task 1: Create `ProfilePreviewView` component (AC: #1, #3, #6)
  - [x] Create `Peach/Start/ProfilePreviewView.swift`
  - [x] Reuse `ConfidenceBandData.prepare()` and `ConfidenceBandData.segments()` for data
  - [x] Reuse `PianoKeyboardLayout(midiRange: 36...84)` for x-position alignment
  - [x] Render confidence band using same `AreaMark`/`LineMark` pattern as `ConfidenceBandView`
  - [x] Strip all axis labels, note names, and numerical values
  - [x] Render a simplified mini piano keyboard (no note labels, no octave boundary text)
  - [x] Frame at ~60-80pt tall, full width
  - [x] Cold start: show mini keyboard with intentional empty-state styling (no icon, no text — just the keyboard strip looking ready)
- [x] Task 2: Make preview tappable with navigation (AC: #2, #5)
  - [x] Wrap in `NavigationLink(value: NavigationDestination.profile)`
  - [x] Verify back navigation returns to Start Screen (already works via NavigationStack)
- [x] Task 3: Replace placeholder in `StartScreen` (AC: #1, #2)
  - [x] Remove `profilePreviewPlaceholder` computed property
  - [x] Replace with `ProfilePreviewView()` in the VStack
  - [x] Inject `@Environment(\.perceptualProfile)` in `StartScreen`
- [x] Task 4: Add VoiceOver accessibility (AC: #4)
  - [x] Add `.accessibilityLabel` that says "Your pitch profile. Tap to view details."
  - [x] When training data exists, append threshold info: "Average threshold: X cents."
  - [x] Add `.accessibilityAddTraits(.isButton)` for tap hint
- [x] Task 5: Write tests (AC: #1-#6)
  - [x] Test ProfilePreviewView renders without crashing (cold start and with data)
  - [x] Test accessibility label text for cold start vs. trained states
  - [x] Test that ProfilePreviewView uses same data pipeline as ProfileScreen

## Dev Notes

### Architecture & Patterns

- **@Observable pattern:** PerceptualProfile is `@Observable @MainActor` — access via `@Environment(\.perceptualProfile)`
- **Environment injection:** Already wired in `PeachApp.swift` line 65 — no new wiring needed
- **NavigationStack routing:** Uses `NavigationDestination.profile` enum value — already defined and handled in `StartScreen.swift` line 50-58
- **MIDI range:** Always `36...84` (C1-C6) — same constant used across ProfileScreen, ConfidenceBandView, PianoKeyboardView

### Reuse Existing Components — DO NOT Reinvent

- **`ConfidenceBandData.prepare(from:midiRange:)`** — extracts data points from profile [Source: Peach/Profile/ConfidenceBandView.swift:31-57]
- **`ConfidenceBandData.segments(from:)`** — groups trained points into contiguous segments [Source: Peach/Profile/ConfidenceBandView.swift:61-83]
- **`PianoKeyboardLayout`** — all x-position and key type calculations [Source: Peach/Profile/PianoKeyboardView.swift:5-68]
- **`ConfidenceBandView`** — reference for Chart rendering pattern (AreaMark + LineMark, log scale, hidden axes) [Source: Peach/Profile/ConfidenceBandView.swift:89-138]
- **`PianoKeyboardView`** — Canvas-based keyboard rendering, already has configurable `height` parameter [Source: Peach/Profile/PianoKeyboardView.swift:72-126]
- **`ProfileScreen.accessibilitySummary(profile:midiRange:)`** — static method for threshold text, reuse for VoiceOver label augmentation [Source: Peach/Profile/ProfileScreen.swift:81-96]

### Implementation Guidance

**ProfilePreviewView structure:**
```
VStack(spacing: 0) {
    if hasTrainingData {
        ConfidenceBandView(dataPoints: ..., layout: ...)  // mini, stripped
            .frame(height: ~40-50pt)
        PianoKeyboardView(midiRange: 36...84, height: ~20-30pt)  // no labels
    } else {
        PianoKeyboardView(midiRange: 36...84, height: ~20-30pt)  // keyboard only
    }
}
```

**Key decisions:**
- The `ConfidenceBandView` already hides all axes (`.chartXAxis(.hidden)`, `.chartYAxis(.hidden)`) — it works as-is for the preview, just needs a smaller frame
- The `PianoKeyboardView` already accepts a `height` parameter — pass ~20-30pt for compact rendering
- The octave boundary labels (note names below keyboard) are part of `PianoKeyboardView` — to strip them for the preview, either: (a) add a `showLabels: Bool` parameter to `PianoKeyboardView`, or (b) use only the Canvas portion. Option (a) is cleaner.
- Total height target: 60-80pt (band ~40-50pt + keyboard ~20-30pt)

**Cold start:** When `profile.overallMean == nil`, show just the mini keyboard strip. No icon, no text — the keyboard itself is the intentional placeholder. This matches the UX spec: "placeholder shape that looks intentional, not broken."

**Navigation:** Wrap entire `ProfilePreviewView` in `NavigationLink(value: NavigationDestination.profile)`. The `.profile` case is already handled in `StartScreen`'s `.navigationDestination` modifier (line 56).

### File Locations

| Action | Path |
|--------|------|
| CREATE | `Peach/Start/ProfilePreviewView.swift` |
| MODIFY | `Peach/Start/StartScreen.swift` — replace placeholder with ProfilePreviewView |
| MODIFY | `Peach/Profile/PianoKeyboardView.swift` — add `showLabels` parameter (optional, for label stripping) |
| CREATE | `PeachTests/Start/ProfilePreviewViewTests.swift` |

### Testing Standards

- Use Swift Testing framework (`@Test`, `#expect()`) — NOT XCTest
- Mirror source structure: tests for `Peach/Start/` go in `PeachTests/Start/`
- Test cold start rendering (no crash, correct accessibility label)
- Test trained-state rendering (data points generated, correct accessibility label)
- Test that `ConfidenceBandData.prepare` is used (same data pipeline as ProfileScreen)

### Previous Story Learnings (5.2)

- Used `abs()` for mean computation to avoid signed cancellation — already handled in `ConfidenceBandData.prepare`
- Environment injection pattern: access `@Environment(\.perceptualProfile)` in the view, no manual wiring needed
- Preview data setup pattern: create a `PerceptualProfile()`, call `.update()` with sample data in `#Preview` blocks
- Singular/plural "cent"/"cents" handled in `SummaryStatisticsView.formatMean` — not needed here but pattern established

### Git Intelligence

Recent commits show Story 5.1 and 5.2 implementation patterns:
- `d5dd5fc` — Code review fixes for 5.2: accessibility, previews, singular cents
- `f3763d3` — Implement story 5.2
- `c13910f` — Code review fixes for 5.1: align chart to keyboard, fix accessibility summary
- `e033d9f` — Implement story 5.1

Pattern: stories are implemented in a single commit, then code review fixes follow in a separate commit.

### References

- [Source: docs/planning-artifacts/epics.md#Story 5.3] — BDD acceptance criteria
- [Source: docs/planning-artifacts/ux-design-specification.md#Profile Preview] — UX spec: compact, simplified, ~full width, ~60-80pt tall, tappable, same rendering logic scaled down
- [Source: docs/planning-artifacts/prd.md#FR22] — User can view a stylized Profile Preview on the Start Screen
- [Source: docs/planning-artifacts/prd.md#FR23] — User can navigate from the Start Screen to the full Profile Screen
- [Source: docs/planning-artifacts/architecture.md#Project Organization] — Start/ folder for start screen components
- [Source: Peach/Start/StartScreen.swift] — Current placeholder at lines 65-81 to replace
- [Source: Peach/Profile/ConfidenceBandView.swift] — Reusable band rendering and data preparation
- [Source: Peach/Profile/PianoKeyboardView.swift] — Reusable keyboard with configurable height
- [Source: Peach/Profile/ProfileScreen.swift:81-96] — Reusable accessibility summary method

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

No issues encountered during implementation.

### Completion Notes List

- Created `ProfilePreviewView` as a compact profile visualization reusing `ConfidenceBandView` (45pt) + `PianoKeyboardView` (25pt, no labels) = ~70pt total height
- Added `showLabels: Bool` parameter to `PianoKeyboardView` (defaults to `true`) to allow label stripping for preview
- Wrapped preview in `NavigationLink(value: .profile)` in `StartScreen` for tap-to-navigate
- Removed old `profilePreviewPlaceholder` from `StartScreen`
- Cold start shows just the mini keyboard strip — intentional empty-state, no icon/text
- VoiceOver: "Your pitch profile. Tap to view details." with `.isButton` trait; trained state appends "Average threshold: X cents."
- 8 new tests in `ProfilePreviewViewTests` covering instantiation, accessibility labels, data pipeline reuse, showLabels parameter, and MIDI range consistency
- All 217 tests pass (0 failures, 0 regressions)

### Change Log

- 2026-02-17: Implemented story 5.3 — Profile Preview on Start Screen and Navigation

### File List

- `Peach/Start/ProfilePreviewView.swift` (NEW)
- `Peach/Start/StartScreen.swift` (MODIFIED — replaced placeholder with ProfilePreviewView + NavigationLink)
- `Peach/Profile/PianoKeyboardView.swift` (MODIFIED — added showLabels parameter)
- `PeachTests/Start/ProfilePreviewViewTests.swift` (NEW)
- `docs/implementation-artifacts/5-3-profile-preview-on-start-screen-and-navigation.md` (MODIFIED — status, tasks, dev agent record)
- `docs/implementation-artifacts/sprint-status.yaml` (MODIFIED — status updated to review)
