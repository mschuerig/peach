# Story 5.1: Profile Screen with Perceptual Profile Visualization

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to see my pitch discrimination ability visualized as a confidence band over a piano keyboard,
so that I can understand where my hearing is strong and where it needs work.

## Acceptance Criteria

1. **Given** the Profile Screen **When** it is displayed with training data **Then** it shows a piano keyboard along the X-axis spanning the training range with note names at octave boundaries (C2, C3, C4, etc.) **And** a confidence band (filled area chart) overlaid above the keyboard showing detection thresholds per note **And** the band's width represents uncertainty — wider where data is sparse, narrower where many comparisons exist **And** the Y-axis is inverted so improvement (smaller cent differences) moves the band downward toward the keyboard **And** it uses system semantic colors (system blue/tint for band fill, opacity for confidence range) **And** it renders within 1 second including computation (NFR5)

2. **Given** the Profile Screen **When** there is no training data (cold start) **Then** the piano keyboard renders fully **And** the confidence band is absent or shown as a faint uniform placeholder at the 100-cent level **And** text "Start training to build your profile" appears centered above the keyboard

3. **Given** the Profile Screen with sparse data **When** only some notes have been trained **Then** the confidence band renders where data exists and fades out where it doesn't **And** no interpolation across large data gaps

4. **Given** the profile visualization **When** VoiceOver is active **Then** it provides an aggregate summary: "Perceptual profile showing detection thresholds from [lowest note] to [highest note]. Average threshold: [X] cents."

5. **Given** the profile visualization **When** rendered in dark mode **Then** it uses system semantic colors and maintains sufficient contrast

## Tasks / Subtasks

- [x] Task 1: Expose PerceptualProfile via SwiftUI Environment (AC: all)
  - [x] 1.1 Add `PerceptualProfileKey` environment key in `Profile/` directory
  - [x] 1.2 Inject `PerceptualProfile` into environment in `PeachApp.swift` alongside existing `TrainingSession`
- [x] Task 2: Build piano keyboard renderer using SwiftUI Canvas (AC: 1, 2)
  - [x] 2.1 Create `PianoKeyboardView` in `Profile/` — renders white and black keys as simple rectangles with standard piano proportions
  - [x] 2.2 Show note names at octave boundaries (C2, C3, C4, etc.)
  - [x] 2.3 Span the training range (default MIDI 36–84, C2–C6)
- [x] Task 3: Build confidence band overlay using Swift Charts AreaMark (AC: 1, 3)
  - [x] 3.1 Create `ConfidenceBandView` using `Chart` with `AreaMark` — plots per-note detection thresholds from PerceptualProfile
  - [x] 3.2 Invert Y-axis (lower cents = better = closer to keyboard)
  - [x] 3.3 Band width represents uncertainty: use `mean ± stdDev` for the area range
  - [x] 3.4 Fade out where no data exists (no interpolation across gaps)
  - [x] 3.5 System semantic colors: `.blue`/`.tint` fill with opacity for confidence range
- [x] Task 4: Implement cold start / empty state (AC: 2)
  - [x] 4.1 Keyboard renders fully even with no data
  - [x] 4.2 Show faint placeholder band at 100-cent level OR no band at all
  - [x] 4.3 Center text: "Start training to build your profile"
- [x] Task 5: Compose full ProfileScreen (AC: 1, 2, 3, 4, 5)
  - [x] 5.1 Replace placeholder ProfileScreen with real implementation
  - [x] 5.2 Stack: visualization (keyboard + band) as main element
  - [x] 5.3 Preserve `.navigationTitle("Profile")` and `.navigationBarTitleDisplayMode(.inline)`
- [x] Task 6: Accessibility (AC: 4)
  - [x] 6.1 Add `.accessibilityLabel()` with aggregate summary to the visualization container
  - [x] 6.2 Summary includes note range and average threshold
- [x] Task 7: Tests (AC: all)
  - [x] 7.1 Test PerceptualProfile environment key injection
  - [x] 7.2 Test piano keyboard note layout calculations
  - [x] 7.3 Test confidence band data preparation from PerceptualProfile data
  - [x] 7.4 Test empty/cold start state rendering
  - [x] 7.5 Test sparse data handling (gaps, no interpolation)

## Dev Notes

### Architecture & Patterns

- **Profile visualization is a custom component** — the only truly custom visual element in the app. Built with SwiftUI Canvas (keyboard) + Swift Charts AreaMark (confidence band). Both are first-party Apple frameworks.
- **Single implementation shared**: The same rendering logic will be reused in Story 5.3 (Profile Preview on Start Screen), scaled down and stripped of labels. Design for reuse now.
- **PerceptualProfile is @Observable @MainActor** — already works with SwiftUI observation. No adapters needed.
- **Views are thin**: observe state, render, send actions. No business logic in views. Profile Screen is read-only — no interactions beyond viewing and navigating back.

### Critical: PerceptualProfile Environment Access

The `PerceptualProfile` is currently created in `PeachApp.swift` (line 23) and passed **only** into `TrainingSession` as a private dependency. It is NOT yet in the SwiftUI environment.

**Required change in PeachApp.swift:**
1. Store `profile` as `@State private var profile: PerceptualProfile` (like `trainingSession`)
2. Pass it into the environment: `.environment(\.perceptualProfile, profile)`
3. Add a `PerceptualProfileKey: EnvironmentKey` (follow the same pattern as `TrainingSessionKey` in `Peach/Training/TrainingScreen.swift:99-128`)

**Place the environment key definition** in `Peach/Profile/ProfileScreen.swift` (same pattern: environment key at bottom of the file where it's primarily consumed).

### PerceptualProfile Data Access

Reading from `PerceptualProfile` (already implemented in `Peach/Core/Profile/PerceptualProfile.swift`):
- `statsForNote(_ note: Int) -> PerceptualNote` — per-note stats (mean, stdDev, sampleCount)
- `overallMean: Double?` — nil if no data
- `overallStdDev: Double?` — nil or requires ≥2 trained notes
- `PerceptualNote.isTrained: Bool` — whether note has any data
- `PerceptualNote.mean` — signed mean (current implementation uses signed centOffset)
- `PerceptualNote.stdDev` — standard deviation
- `PerceptualNote.sampleCount` — number of comparisons

**Important:** There is a known hotfix (`hotfix-investigate-signed-mean`, status: ready-for-dev) that will change `PerceptualProfile` to use **absolute** cent values instead of signed values. Currently, `mean` can be close to 0 even with large cent differences (directional cancellation). For visualization purposes, use `abs(stats.mean)` to show detection threshold magnitude until the hotfix lands.

### Piano Keyboard Implementation

- Use SwiftUI `Canvas` for the keyboard rendering (architecture doc specifies this)
- Keys are stylized, not photorealistic — simple rectangles with standard piano proportions
- White keys: full height, natural proportions. Black keys: shorter, narrower, overlapping white keys
- Standard piano key pattern per octave: C(W), C#(B), D(W), D#(B), E(W), F(W), F#(B), G(W), G#(B), A(W), A#(B), B(W)
- Default training range: MIDI 36–84 (C2–C6 = 4 octaves, 49 notes) — matches `TrainingSettings` defaults
- Note names at octave boundaries only (C2, C3, C4, C5, C6) — not every key labeled
- The keyboard is a horizontal strip, not vertical

### Confidence Band Implementation

- Use Swift Charts `Chart` with `AreaMark` (architecture doc specifies this)
- Data source: iterate MIDI notes in training range, read `statsForNote()` for each
- **Y-axis inverted**: smaller cent difference = better = lower on screen (closer to keyboard)
- **Band area**: plot `abs(mean) - stdDev` to `abs(mean) + stdDev` per note (clamped to ≥ 0)
- **Sparse data gaps**: where `sampleCount == 0`, do NOT plot a point — let the area break naturally (Swift Charts handles discontinuities)
- **Colors**: system `.blue` or `.tint` for the band fill with reduced opacity. Use `AreaMark` with `.foregroundStyle()` using semantic color
- **Performance**: 128 data points max — trivially fast, no optimization needed

### Visualization Composition

- The keyboard and confidence band are **overlaid** — the band sits above the keyboard
- Use a `ZStack` or overlay composition to layer them
- Both must share the same X-axis coordinate space (MIDI note → horizontal position)
- The keyboard defines the X layout; the chart aligns to it

### UX Requirements (from UX Design Spec)

- "Data as landscape" pattern — the profile should feel like looking at a topographic map of your hearing, not a score sheet
- Calm, factual presentation. No celebratory animations. Understated.
- System semantic colors throughout. No custom color palette.
- Respect dark mode automatically via system colors
- No loading states — everything is local and instantaneous
- Profile Screen is read-only — no interactions beyond viewing and navigating back

### Project Structure Notes

**New/modified files:**
- `Peach/Profile/ProfileScreen.swift` — replace placeholder with real implementation + environment key
- `Peach/Profile/PianoKeyboardView.swift` — new: keyboard renderer
- `Peach/Profile/ConfidenceBandView.swift` — new: chart overlay
- `Peach/App/PeachApp.swift` — modify: add profile to environment
- `PeachTests/Profile/ProfileScreenTests.swift` — new: tests

**Existing file locations (do NOT move):**
- `Peach/Core/Profile/PerceptualProfile.swift` — data source, do not modify
- `Peach/Training/TrainingScreen.swift` — contains `TrainingSessionKey` pattern to follow

### References

- [Source: docs/planning-artifacts/epics.md#Story 5.1] — acceptance criteria and user story
- [Source: docs/planning-artifacts/architecture.md#Profile Computation] — "Computed on-the-fly for MVP"
- [Source: docs/planning-artifacts/architecture.md#Project Structure] — `Profile/ProfileScreen.swift` location
- [Source: docs/planning-artifacts/architecture.md#Data Flow] — "Profile Screen reads PerceptualProfile for visualization"
- [Source: docs/planning-artifacts/architecture.md#UI Boundaries] — "Views observe TrainingSession and PerceptualProfile"
- [Source: docs/planning-artifacts/ux-design-specification.md#Custom Components > Perceptual Profile Visualization] — full visual design spec
- [Source: docs/planning-artifacts/ux-design-specification.md#Custom Components > Profile Preview] — shared rendering logic for Story 5.3
- [Source: docs/planning-artifacts/ux-design-specification.md#Accessibility Strategy] — VoiceOver aggregate summary requirement
- [Source: docs/planning-artifacts/ux-design-specification.md#Empty States] — cold start design requirements
- [Source: Peach/Core/Profile/PerceptualProfile.swift] — data access API (statsForNote, overallMean, overallStdDev)
- [Source: Peach/Training/TrainingScreen.swift:99-128] — EnvironmentKey pattern to follow
- [Source: Peach/App/PeachApp.swift:23] — where PerceptualProfile is created, needs environment injection

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None — clean implementation, no debug issues encountered.

### Completion Notes List

- **Task 1:** Added `PerceptualProfileKey` environment key in `ProfileScreen.swift` following `TrainingSessionKey` pattern. Injected profile into SwiftUI environment in `PeachApp.swift` via `@State private var profile` and `.environment(\.perceptualProfile, profile)`.
- **Task 2:** Created `PianoKeyboardView` using SwiftUI `Canvas` with `PianoKeyboardLayout` struct for testable layout calculations. Renders white/black keys with standard proportions, note names at octave boundaries (C2-C6), spans MIDI 36-84.
- **Task 3:** Created `ConfidenceBandView` using Swift Charts `AreaMark` + `LineMark`. `ConfidenceBandData.prepare()` extracts per-note stats using `abs(mean)` for threshold (handles signed centOffset). Y-axis: 0 cents (best) at bottom near keyboard, higher values above. Logarithmic Y-axis scale to emphasize musically relevant low-cent range. Band = mean ± stdDev, clamped ≥ 0.5 (log floor). Segments break on untrained gaps — no interpolation across sparse data.
- **Task 4:** Cold start shows piano keyboard with centered "Start training to build your profile" text. No band rendered when no data exists (conditioned on `profile.overallMean != nil`).
- **Task 5:** Replaced placeholder ProfileScreen with full implementation. VStack composition: confidence band above, keyboard below. Preserved `.navigationTitle("Profile")` and `.navigationBarTitleDisplayMode(.inline)`.
- **Task 6:** Added `.accessibilityElement(children: .ignore)` with `.accessibilityLabel()` providing aggregate summary: note range and average threshold in cents.
- **Task 7:** 17 tests covering environment key, keyboard layout calculations, confidence band data preparation, segmentation, cold start, sparse data handling, and accessibility summary. All passing.

### Change Log

- 2026-02-17: Implemented Story 5.1 — Profile Screen with perceptual profile visualization
- 2026-02-17: Fixed visualization: Y-axis orientation (0 cents at bottom near keyboard), logarithmic Y-axis scale, sparse data segmentation (no interpolation across gaps)
- 2026-02-17: Code review fixes: chart X-axis aligned to keyboard layout positions, accessibility summary uses absolute per-note means (fixes directional cancellation), removed duplicate midiRange property, added accessibility summary test

### File List

- `Peach/Profile/ProfileScreen.swift` — replaced placeholder with full implementation + environment key
- `Peach/Profile/PianoKeyboardView.swift` — new: piano keyboard Canvas renderer + layout calculations
- `Peach/Profile/ConfidenceBandView.swift` — new: confidence band Chart overlay + data preparation
- `Peach/App/PeachApp.swift` — modified: added `@State profile` and environment injection
- `Peach/Resources/Localizable.xcstrings` — modified: added chart string entries, removed placeholder strings
- `PeachTests/Profile/ProfileScreenTests.swift` — new: 17 tests for all tasks
