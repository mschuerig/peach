# Story 5.1: Profile Screen with Perceptual Profile Visualization

Status: ready-for-dev

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

- [ ] Task 1: Expose PerceptualProfile via SwiftUI Environment (AC: all)
  - [ ] 1.1 Add `PerceptualProfileKey` environment key in `Profile/` directory
  - [ ] 1.2 Inject `PerceptualProfile` into environment in `PeachApp.swift` alongside existing `TrainingSession`
- [ ] Task 2: Build piano keyboard renderer using SwiftUI Canvas (AC: 1, 2)
  - [ ] 2.1 Create `PianoKeyboardView` in `Profile/` — renders white and black keys as simple rectangles with standard piano proportions
  - [ ] 2.2 Show note names at octave boundaries (C2, C3, C4, etc.)
  - [ ] 2.3 Span the training range (default MIDI 36–84, C2–C6)
- [ ] Task 3: Build confidence band overlay using Swift Charts AreaMark (AC: 1, 3)
  - [ ] 3.1 Create `ConfidenceBandView` using `Chart` with `AreaMark` — plots per-note detection thresholds from PerceptualProfile
  - [ ] 3.2 Invert Y-axis (lower cents = better = closer to keyboard)
  - [ ] 3.3 Band width represents uncertainty: use `mean ± stdDev` for the area range
  - [ ] 3.4 Fade out where no data exists (no interpolation across gaps)
  - [ ] 3.5 System semantic colors: `.blue`/`.tint` fill with opacity for confidence range
- [ ] Task 4: Implement cold start / empty state (AC: 2)
  - [ ] 4.1 Keyboard renders fully even with no data
  - [ ] 4.2 Show faint placeholder band at 100-cent level OR no band at all
  - [ ] 4.3 Center text: "Start training to build your profile"
- [ ] Task 5: Compose full ProfileScreen (AC: 1, 2, 3, 4, 5)
  - [ ] 5.1 Replace placeholder ProfileScreen with real implementation
  - [ ] 5.2 Stack: visualization (keyboard + band) as main element
  - [ ] 5.3 Preserve `.navigationTitle("Profile")` and `.navigationBarTitleDisplayMode(.inline)`
- [ ] Task 6: Accessibility (AC: 4)
  - [ ] 6.1 Add `.accessibilityLabel()` with aggregate summary to the visualization container
  - [ ] 6.2 Summary includes note range and average threshold
- [ ] Task 7: Tests (AC: all)
  - [ ] 7.1 Test PerceptualProfile environment key injection
  - [ ] 7.2 Test piano keyboard note layout calculations
  - [ ] 7.3 Test confidence band data preparation from PerceptualProfile data
  - [ ] 7.4 Test empty/cold start state rendering
  - [ ] 7.5 Test sparse data handling (gaps, no interpolation)

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

### Debug Log References

### Completion Notes List

### File List
