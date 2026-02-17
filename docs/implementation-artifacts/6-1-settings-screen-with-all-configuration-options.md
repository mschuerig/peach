# Story 6.1: Settings Screen with All Configuration Options

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to customize algorithm behavior, note range, note duration, reference pitch, and sound source,
so that the training experience matches my preferences and musical context.

## Acceptance Criteria

1. The Settings Screen displays the following controls in a stock SwiftUI `Form` with logical section grouping:
   - Natural vs. Mechanical slider (`Slider`)
   - Note range lower bound (`Stepper`, display as note name)
   - Note range upper bound (`Stepper`, display as note name)
   - Note duration (`Stepper` or `Slider`)
   - Reference pitch (`Stepper`, default A4 = 440Hz)
   - Sound source selection (`Picker`, MVP: sine wave only — single option)
2. Every setting change is persisted immediately via `@AppStorage` — no save/cancel buttons
3. All controls are bounded (sliders have min/max, steppers have ranges) — no form validation needed
4. Dismissing the Settings Screen (back navigation or swipe) returns to the Start Screen
5. When accessed from the Training Screen, training stops, the Settings Screen is shown, and dismissal returns to the Start Screen
6. A "Reset All Training Data" action is available, requiring confirmation before execution, which deletes all `ComparisonRecord` entries and resets the `PerceptualProfile` and `TrendAnalyzer`

## Tasks / Subtasks

- [x] Task 1: Define @AppStorage keys and defaults (AC: #2, #3)
  - [x] Create `Peach/Settings/SettingsKeys.swift` with static constants for all @AppStorage keys
  - [x] Define default values matching existing `TrainingSettings` defaults: naturalVsMechanical = 0.5, noteRangeMin = 36, noteRangeMax = 84, noteDuration = 1.0, referencePitch = 440.0, soundSource = "sine"
  - [x] Ensure defaults are consistent with `TrainingSettings` struct in `NextNoteStrategy.swift`
- [x] Task 2: Build Settings Screen UI (AC: #1, #3)
  - [x] Replace placeholder in `Peach/Settings/SettingsScreen.swift` with stock SwiftUI `Form`
  - [x] Section "Algorithm": `Slider` for Natural vs. Mechanical (0.0...1.0), labels "Natural" / "Mechanical"
  - [x] Section "Note Range": `Stepper` for lower bound (MIDI note, display as note name e.g. "C2"), `Stepper` for upper bound (MIDI note, display as note name)
  - [x] Constraint: lower bound < upper bound (enforce minimum gap of at least 12 semitones)
  - [x] Note: MVP uses Steppers with note names. Future enhancement: interactive piano keyboard range picker (see Future Work section)
  - [x] Section "Audio": `Stepper` for note duration (0.3s–3.0s, step 0.1s), `Stepper` for reference pitch (380–500 Hz, step 1 Hz), `Picker` for sound source (MVP: "Sine Wave" only)
  - [x] All controls bound to `@AppStorage` properties — changes persist immediately
- [x] Task 3: Add "Reset All Training Data" action (AC: #6)
  - [x] Section "Data" at the bottom of the Form
  - [x] Destructive button "Reset All Training Data" styled with `.role(.destructive)`
  - [x] Confirmation dialog (`.confirmationDialog`) before execution: "This will permanently delete all training data and reset your profile. This cannot be undone."
  - [x] On confirm: delete all `ComparisonRecord` from SwiftData, reset `PerceptualProfile`, reset `TrendAnalyzer`
  - [x] Access `TrainingDataStore` via environment or initialization
- [x] Task 4: Verify navigation behavior (AC: #4, #5)
  - [x] Verify back navigation from Settings returns to Start Screen (already works via NavigationStack)
  - [x] Verify that navigating to Settings from Training Screen stops training (already handled by Story 3.4)
  - [x] Verify dismissal from Training Screen context returns to Start Screen (already works via hub-and-spoke)
- [x] Task 5: Write tests (AC: #1-#6)
  - [x] Test that all @AppStorage defaults match TrainingSettings defaults
  - [x] Test note range validation (lower < upper, minimum gap enforced)
  - [x] Test reset functionality clears ComparisonRecords and resets profile
  - [x] Test that SettingsScreen renders without crashing with default values

## Dev Notes

### Architecture & Patterns

- **@AppStorage for all settings:** Each setting gets its own `@AppStorage` property in SettingsScreen. Keys should be defined as static constants for consistency.
- **No custom persistence layer:** `@AppStorage` writes to UserDefaults synchronously — no save action needed.
- **Stock SwiftUI Form:** Use `Form` with `Section` for grouping. All controls are stock SwiftUI components.
- **@Observable pattern:** PerceptualProfile and TrendAnalyzer are `@Observable @MainActor` — access via environment keys.
- **Environment injection:** `@Environment(\.perceptualProfile)` and `@Environment(\.trendAnalyzer)` for reset functionality.

### Settings Keys & Defaults

| Setting | @AppStorage Key | Type | Default | Range |
|---------|----------------|------|---------|-------|
| Natural vs. Mechanical | `"naturalVsMechanical"` | `Double` | `0.5` | `0.0...1.0` |
| Note Range Lower | `"noteRangeMin"` | `Int` | `36` (C2) | `21...108` (A0-C8) |
| Note Range Upper | `"noteRangeMax"` | `Int` | `84` (C6) | `21...108` (A0-C8) |
| Note Duration | `"noteDuration"` | `Double` | `1.0` | `0.3...3.0` |
| Reference Pitch | `"referencePitch"` | `Double` | `440.0` | `380...500` |
| Sound Source | `"soundSource"` | `String` | `"sine"` | MVP: sine only |

### MIDI Note Display Helper

The Settings Screen needs to display MIDI note numbers as human-readable note names (e.g., MIDI 36 = "C2", MIDI 84 = "C6"). This is a pure function:

```swift
func noteName(for midiNote: Int) -> String {
    let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let octave = (midiNote / 12) - 1
    let note = noteNames[midiNote % 12]
    return "\(note)\(octave)"
}
```

This helper already exists partially in `PianoKeyboardLayout` — check if it can be reused or extracted to a shared utility.

### Reset Training Data Implementation

The reset action needs to:
1. Delete all `ComparisonRecord` entries via `TrainingDataStore`
2. Reset `PerceptualProfile` (clear all per-note data, set overallMean/overallStdDev to nil)
3. Reset `TrendAnalyzer` (clear historical snapshots)

**TrainingDataStore** already has access to the SwiftData `ModelContext`. Need to verify if a `deleteAll()` method exists or needs to be added.

**Important:** The reset should NOT reset settings themselves — only training data.

### Note Range Validation

Lower bound must always be less than upper bound with a minimum gap:
- If user increases lower bound past (upper - 12), clamp upper bound to lower + 12
- If user decreases upper bound past (lower + 12), clamp lower bound to upper - 12
- Display both as note names (e.g., "C2" to "C6") not MIDI numbers

### Sound Source Picker

MVP has only one option ("Sine Wave"). The Picker should still be present to establish the UI pattern for future sound sources. Display it as a disabled or single-option picker that communicates "more coming."

### Project Structure Notes

- All Settings code goes in `Peach/Settings/`
- Tests go in `PeachTests/Settings/`
- Follows existing feature-based organization pattern
- No new Core/ files expected — this story is primarily UI + @AppStorage

### References

- [Source: docs/planning-artifacts/epics.md#Story 6.1] — BDD acceptance criteria
- [Source: docs/planning-artifacts/ux-design-specification.md#Form Patterns] — Settings Form controls and behavior rules
- [Source: docs/planning-artifacts/ux-design-specification.md#Journey 5] — Settings UX journey
- [Source: docs/planning-artifacts/prd.md#FR30-FR36] — Settings functional requirements
- [Source: docs/planning-artifacts/architecture.md#Data Architecture] — @AppStorage for settings
- [Source: Peach/Core/Algorithm/NextNoteStrategy.swift:43-109] — TrainingSettings struct with existing defaults
- [Source: Peach/Core/Audio/FrequencyCalculation.swift:5-19] — Reference pitch validation (380-500Hz)
- [Source: Peach/Settings/SettingsScreen.swift] — Current placeholder stub to replace
- [Source: Peach/Training/TrainingSession.swift:106-115] — Current hardcoded settings to eventually replace (Story 6.2)
- [Source: Peach/App/PeachApp.swift] — App initialization and environment setup
- [Source: docs/implementation-artifacts/sprint-status.yaml] — Sprint note: "Include 'Reset all training data' action"

### Previous Story Learnings (5.3)

- Environment injection pattern: `@Environment(\.perceptualProfile)` works cleanly — use same pattern for accessing profile/trend in reset
- NavigationStack with `NavigationDestination` enum already handles Settings routing
- Tests use Swift Testing framework (`@Test`, `#expect()`)
- All 217 tests currently pass — maintain zero regressions
- Pattern: implementation commit → code review fixes commit

### Git Intelligence

Recent commits (Epic 5 completion):
- `82abbdb` — Code review fixes for Story 5.3: extract shared threshold, fix tests, add NaN guard
- `60f1777` — Implement story 5.3: Profile Preview on Start Screen and Navigation
- `d5dd5fc` — Code review fixes for Story 5.2: fix accessibility, previews, singular cents
- `f3763d3` — Implement story 5.2: Summary Statistics with Trend Indicator

Pattern: stories implemented in single commits, code review fixes in separate commits. SwiftUI views use environment injection for observable objects.

### Web Research Notes

- **SwiftUI Form (iOS 26):** Stock `Form` container with `Section` works as expected. Liquid Glass appearance applied automatically.
- **@AppStorage:** Supports `Int`, `Double`, `String`, `Bool`, `URL`, `Data` types directly. For custom types, use `RawRepresentable` conformance.
- **Slider:** `Slider(value:in:step:)` with optional `label` and `minimumValueLabel`/`maximumValueLabel` parameters.
- **Stepper:** `Stepper(value:in:step:)` with format parameter for display. Can use `Stepper("Label", value: $binding, in: range, step: stepSize, format: .number)`.
- **confirmationDialog:** Use `.confirmationDialog(_:isPresented:titleVisibility:actions:message:)` for destructive confirmation.

## Future Work

### Interactive Piano Keyboard Range Picker

Replace the Stepper-based note range controls with an interactive piano keyboard that makes range selection visually intuitive:

- Display a `PianoKeyboardView` (reuse existing component from `Peach/Profile/PianoKeyboardView.swift`) within the Note Range section
- **Drag from the left** to select the lower bound; **drag from the right** to select the upper bound
- Keys **outside** the selected training range get a **gray background** to visually distinguish in-range from out-of-range
- Show the **note names** of the lowest and highest in-range notes as a legend (e.g., "C2 — C6")
- Bind the selected bounds to `@AppStorage("noteRangeMin")` / `@AppStorage("noteRangeMax")`
- Maintain the minimum 12-semitone gap constraint during drag interaction

This enhancement requires adding drag gesture handling to the Canvas-based keyboard, visual state management for in/out-of-range keys, and boundary note labels — meaningful complexity best deferred past the initial Settings Screen MVP.

## Change Log

- 2026-02-17: Implemented Settings Screen with all configuration options — @AppStorage keys, Form UI with 4 sections (Algorithm, Note Range, Audio, Data), reset training data action with confirmation, and 9 unit tests. Added reset() methods to PerceptualProfile and TrendAnalyzer. 225 total tests pass (was 217).

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

- No blocking issues encountered during implementation.

### Completion Notes List

- Task 1: Created `SettingsKeys.swift` with static constants for all @AppStorage key names and default values. Defaults verified to match `TrainingSettings` struct.
- Task 2: Replaced placeholder `SettingsScreen.swift` with full Form-based UI. Four sections: Algorithm (Slider), Note Range (Steppers with note name display via `PianoKeyboardLayout.noteName`), Audio (Steppers + Picker), Data (reset button). Note range enforces 12-semitone minimum gap via Stepper range constraints.
- Task 3: Added "Reset All Training Data" destructive button with `.confirmationDialog`. Reset deletes all ComparisonRecords via `modelContext.delete(model:)`, calls `profile.reset()` and `trendAnalyzer.reset()`. Added `reset()` methods to both PerceptualProfile and TrendAnalyzer.
- Task 4: Verified existing hub-and-spoke navigation handles all scenarios — back navigation returns to Start Screen, training stops on navigation away (Story 3.4), NavigationStack path clearing works correctly.
- Task 5: 9 tests in `PeachTests/Settings/SettingsTests.swift` covering: default consistency with TrainingSettings, key name verification, note range gap clamping, note name display, profile reset, trend analyzer reset, SwiftData record deletion, and screen instantiation.

### File List

- Peach/Settings/SettingsKeys.swift (new)
- Peach/Settings/SettingsScreen.swift (modified)
- Peach/Core/Profile/PerceptualProfile.swift (modified — added reset() method)
- Peach/Core/Profile/TrendAnalyzer.swift (modified — added reset() method)
- PeachTests/Settings/SettingsTests.swift (new)
- docs/implementation-artifacts/6-1-settings-screen-with-all-configuration-options.md (modified)
- docs/implementation-artifacts/sprint-status.yaml (modified)
