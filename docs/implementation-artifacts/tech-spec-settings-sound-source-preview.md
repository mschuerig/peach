---
title: 'Settings Sound Source Preview Button'
slug: 'settings-sound-source-preview'
created: '2026-03-06'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['SwiftUI', 'AVAudioEngine', 'SF2', 'Swift Testing']
files_to_modify: ['Peach/Core/Training/TrainingConstants.swift', 'Peach/App/EnvironmentKeys.swift', 'Peach/App/PeachApp.swift', 'Peach/Settings/SettingsScreen.swift']
code_patterns: ['@Environment closure injection (dataStoreResetter pattern)', 'NotePlayer.play(frequency:duration:velocity:amplitudeDB:)', 'NotePlayer.stopAll()', 'TuningSystem.frequency(for:referencePitch:)', 'SoundFontNotePlayer reads userSettings.soundSource on each play()']
test_patterns: ['Swift Testing @Test/@Suite', 'MockNotePlayer with call tracking', 'async tests', 'struct-based suites with factory methods']
---

# Tech-Spec: Settings Sound Source Preview Button

**Created:** 2026-03-06

## Overview

### Problem Statement

There is no way to hear what a sound source sounds like before starting a training session. Users must leave Settings, start training, and listen — then go back to Settings if they want a different sound.

### Solution

Add a `speaker.wave.2` icon button to the right of the Sound picker in the Settings screen. Tapping it plays a 2-second preview of the selected sound at the current concert pitch (A4). Tapping again while playing stops the preview. The preview action is injected via `@Environment` as a closure from the composition root, keeping `NotePlayer` out of the view layer.

### Scope

**In Scope:**
- Preview button with `speaker.wave.2` SF Symbol icon next to the Sound picker
- Plays selected sound source at concert pitch (A4) for 2 seconds
- Tap-to-stop if already playing
- Preview closure injected via `@Environment` from composition root
- Constant for preview duration

**Out of Scope:**
- Visual feedback during playback (e.g., animated speaker icon)
- Preview for other settings (duration, tuning system)
- Playing multiple notes or a sequence

## Context for Development

### Codebase Patterns

- Views must not reference `NotePlayer` directly — inject a closure or lightweight abstraction via `@Environment`
- `@Entry` macro on `EnvironmentValues` for new environment keys (in `App/EnvironmentKeys.swift`)
- All service wiring happens in `PeachApp.swift`
- `SoundFontNotePlayer` reads `userSettings.soundSource` on each `play()` call — so the preview automatically uses whichever sound source is currently selected in the picker, no need to pass it explicitly
- `NotePlayer.play(frequency:duration:velocity:amplitudeDB:)` plays a note for a given duration then stops automatically
- `NotePlayer.stopAll()` stops all currently playing notes immediately
- `TuningSystem.frequency(for:referencePitch:)` converts `MIDINote` to `Frequency` — requires explicit `tuningSystem` and `referencePitch` parameters
- Constants go in domain-appropriate files — `TrainingConstants` already holds `feedbackDuration` and `velocity`
- Existing pattern to follow: `dataStoreResetter` in `EnvironmentKeys.swift` — a `(() throws -> Void)?` closure injected from `PeachApp.swift`
- `AppUserSettings` reads `UserDefaults.standard` — stays in sync with `@AppStorage` writes from `SettingsScreen`
- `AmplitudeDB(0)` = unity gain, standard for preview playback

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `Peach/Settings/SettingsScreen.swift` | Settings UI — sound picker in `soundSection` (line 208). Preview button goes here |
| `Peach/Core/Audio/NotePlayer.swift` | `NotePlayer` protocol — `play(frequency:duration:velocity:amplitudeDB:)` and `stopAll()` |
| `Peach/Core/Audio/SoundFontNotePlayer.swift` | Production `NotePlayer` — reads `userSettings.soundSource` on each `play()` |
| `Peach/App/EnvironmentKeys.swift` | `@Entry` environment key definitions — new environment keys go here |
| `Peach/App/PeachApp.swift` | Composition root — wires preview closures with captured `notePlayer` reference |
| `Peach/Core/Training/TrainingConstants.swift` | Training constants — `previewDuration` constant goes here |
| `Peach/Core/Audio/TuningSystem.swift` | `frequency(for:referencePitch:)` — converts MIDINote to Frequency |
| `PeachTests/PitchComparison/MockNotePlayer.swift` | Mock with call tracking — reuse for preview tests |

### Technical Decisions

- **Icon:** `speaker.wave.2` SF Symbol
- **Preview note:** A4 (`MIDINote(69)`) converted to Hz via `TuningSystem.equalTemperament.frequency(for:referencePitch:)` using the current concert pitch from `@AppStorage`
- **Preview duration:** 2 seconds, defined as `TrainingConstants.previewDuration` (`TimeInterval`)
- **Velocity:** `TrainingConstants.velocity` (63, mezzo-piano) — consistent with training playback
- **Amplitude:** `AmplitudeDB(0)` — unity gain, no boost or cut
- **Injection approach:** Two closures injected via `@Environment`:
  - `soundPreviewPlay: (() async -> Void)?` — plays preview note for `TrainingConstants.previewDuration`
  - `soundPreviewStop: (() async -> Void)?` — calls `NotePlayer.stopAll()`
- **Play/stop toggle:** `SettingsScreen` tracks `@State private var previewTask: Task<Void, Never>?`. Tap while `nil` → start a `Task` that calls the play closure, nils out the task on completion. Tap while non-nil → cancel the task and call the stop closure
- **Tuning system:** Always uses `.equalTemperament` for preview — the preview is about timbre, not tuning

## Implementation Plan

### Tasks

- [ ] Task 1: Add `previewDuration` constant to `TrainingConstants`
  - File: `Peach/Core/Training/TrainingConstants.swift`
  - Action: Add `static let previewDuration: TimeInterval = 2.0` to the `TrainingConstants` enum
  - Notes: Uses `TimeInterval` (not `Duration`) because `NotePlayer.play(frequency:duration:)` takes `TimeInterval`

- [ ] Task 2: Add environment keys for preview closures
  - File: `Peach/App/EnvironmentKeys.swift`
  - Action: Add two `@Entry` keys to the Core Environment Keys section:
    ```swift
    @Entry var soundPreviewPlay: (() async -> Void)? = nil
    @Entry var soundPreviewStop: (() async -> Void)? = nil
    ```
  - Notes: Optional closures, defaulting to `nil` (safe for previews). Follows `dataStoreResetter` pattern

- [ ] Task 3: Wire preview closures in composition root
  - File: `Peach/App/PeachApp.swift`
  - Action: Add `.environment(\.soundPreviewPlay, ...)` and `.environment(\.soundPreviewStop, ...)` to the `ContentView()` environment chain. The play closure:
    1. Reads `referencePitch` from `userSettings` (already captured as `AppUserSettings`)
    2. Computes frequency: `TuningSystem.equalTemperament.frequency(for: MIDINote(69), referencePitch: userSettings.referencePitch)`
    3. Calls `notePlayer.play(frequency:duration:velocity:amplitudeDB:)` with `TrainingConstants.previewDuration`, `TrainingConstants.velocity`, `AmplitudeDB(0)`
    The stop closure calls `notePlayer.stopAll()`
  - Notes: `notePlayer` and `userSettings` are already local variables in `PeachApp.init()`. The closures need to capture them. Since `notePlayer` is created as a local `let` in `init()`, store it as a `@State` property or capture it directly in the closure. Looking at the code, `notePlayer` is a local `let` — it needs to be stored. Create a `@State private var notePlayer: NotePlayer` property to make it available in `body`. Alternatively, create the closures in `init()` and store them as `@State`

- [ ] Task 4: Add preview button to `SettingsScreen`
  - File: `Peach/Settings/SettingsScreen.swift`
  - Action:
    1. Add `@Environment(\.soundPreviewPlay) private var soundPreviewPlay`
    2. Add `@Environment(\.soundPreviewStop) private var soundPreviewStop`
    3. Add `@State private var previewTask: Task<Void, Never>?`
    4. Add a computed `private var isPreviewPlaying: Bool { previewTask != nil }`
    5. In `soundSection`, add an `HStack` wrapping the Sound `Picker` with a `Button` to its right:
       ```swift
       HStack {
           Picker(String(localized: "Sound"), selection: $soundSource) {
               ForEach(soundSourceProvider.availableSources, id: \.self) { source in
                   Text(soundSourceProvider.displayName(for: source)).tag(source.rawValue)
               }
           }
           Button {
               togglePreview()
           } label: {
               Image(systemName: isPreviewPlaying ? "stop.fill" : "speaker.wave.2")
           }
       }
       ```
    6. Add a `togglePreview()` method:
       ```swift
       private func togglePreview() {
           if let task = previewTask {
               task.cancel()
               previewTask = nil
               Task { await soundPreviewStop?() }
           } else {
               previewTask = Task {
                   await soundPreviewPlay?()
                   previewTask = nil
               }
           }
       }
       ```
    7. Stop any playing preview when the view disappears — add `.onDisappear { previewTask?.cancel(); previewTask = nil; Task { await soundPreviewStop?() } }` to the `soundSection` or the `Form`
    8. Stop any playing preview when sound source changes — add `.onChange(of: soundSource) { previewTask?.cancel(); previewTask = nil; Task { await soundPreviewStop?() } }` so switching sounds stops the current preview
  - Notes: `stop.fill` icon while playing gives clear visual affordance. The `togglePreview` method handles the play/stop toggle

### Acceptance Criteria

- [ ] AC 1: Given the Settings screen is showing, when the user looks at the Sound section, then a `speaker.wave.2` icon button is visible to the right of the Sound picker
- [ ] AC 2: Given no preview is playing, when the user taps the preview button, then a 2-second note plays using the currently selected sound source at the current concert pitch
- [ ] AC 3: Given a preview is playing, when the user taps the preview button again, then the playing sound stops immediately
- [ ] AC 4: Given a preview is playing, when the user changes the sound source in the picker, then the playing preview stops
- [ ] AC 5: Given a preview is playing, when the user navigates away from Settings, then the playing preview stops
- [ ] AC 6: Given the preview button is tapped and the note finishes its 2-second duration naturally, then the button returns to its default `speaker.wave.2` icon (not stuck in stop state)

## Additional Context

### Dependencies

- No new external dependencies. Uses existing `NotePlayer`, `TuningSystem`, and `TrainingConstants`
- Depends on `notePlayer` instance already created in `PeachApp.init()`

### Testing Strategy

**Unit Tests:**
- `TrainingConstants.previewDuration` equals `2.0`
- `togglePreview()` logic: verify that calling it once starts a task (non-nil `previewTask`), calling it again cancels and nils it

**Integration Tests (manual):**
- Tap preview button → hear the selected sound for 2 seconds
- Switch sound source → tap preview → hear the new sound
- Tap preview → tap again before 2 seconds → sound stops
- Tap preview → navigate back → sound stops
- Change concert pitch → tap preview → pitch matches the new setting

### Notes

- The `NotePlayer` is shared between training sessions and the preview. If a training session is active and the user opens Settings to preview a sound, `stopAll()` will also stop the training session's notes. This is acceptable because Settings is only accessible when no session is active (the user must be on the Start screen to navigate to Settings)
- `SoundFontNotePlayer.ensurePresetLoaded()` is called on every `play()` — if the user changes the sound source in the picker and immediately taps preview, the correct preset will load automatically
- The preview uses `equalTemperament` for frequency calculation regardless of the tuning system setting. For a single A4 note, the tuning system makes no difference (A4 is the reference in all systems), but using `equalTemperament` explicitly avoids any confusion
