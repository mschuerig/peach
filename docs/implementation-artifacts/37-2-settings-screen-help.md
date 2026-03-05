# Story 37.2: Settings Screen Help

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to understand what each setting does,
So that I can configure the app to match my training goals.

## Acceptance Criteria

1. **Given** the Settings Screen **When** help is accessed (e.g., toolbar help button presenting a sheet) **Then** each setting group has a clear explanation of what it controls and why a user might change it

2. **Given** settings with non-obvious implications (e.g., tuning system, vary loudness, concert pitch) **When** their help is viewed **Then** the explanation includes practical context (e.g., "Most musicians use 440 Hz. Some orchestras tune to 442 Hz.")

3. **Given** the help content **When** displayed in English or German **Then** all text is properly localized

4. **Given** the help view **When** the user dismisses it **Then** they return to the Settings Screen without side effects

## Tasks / Subtasks

- [ ] Task 1: Design help content for each Settings section (AC: #1, #2)
  - [ ] 1.1 Write help text for "Training Range" section — explain lowest/highest note range and why a user might narrow/widen it
  - [ ] 1.2 Write help text for "Intervals" section — explain interval selection, what intervals are, and why to enable/disable specific ones
  - [ ] 1.3 Write help text for "Sound" section — explain sound source, note duration, concert pitch (with practical 440/442 Hz context), and tuning system (equal temperament vs just intonation with practical context)
  - [ ] 1.4 Write help text for "Difficulty" section — explain vary loudness and why it makes training harder/more realistic
  - [ ] 1.5 Write help text for "Data" section — explain export, import, and reset functionality

- [ ] Task 2: Add help button and sheet to SettingsScreen (AC: #1, #4)
  - [ ] 2.1 Add a `@State private var showHelpSheet = false` to `SettingsScreen`
  - [ ] 2.2 Add a toolbar button (e.g., `questionmark.circle` SF Symbol) that toggles `showHelpSheet`
  - [ ] 2.3 Add `.sheet(isPresented: $showHelpSheet)` presenting help content via `HelpContentView`
  - [ ] 2.4 Wrap help content in `NavigationStack` with "Settings Help" title and "Done" dismiss button (same pattern as `InfoScreen`)
  - [ ] 2.5 Define `static let helpSections: [HelpSection]` on `SettingsScreen` with all 5 section help texts using `String(localized:)` for each

- [ ] Task 3: Add localization for all help strings (AC: #3)
  - [ ] 3.1 Add all new English help strings as `String(localized:)` in SwiftUI (auto-detected by String Catalog)
  - [ ] 3.2 Add German translations for all new strings using `bin/add-localization.py`
  - [ ] 3.3 Verify with `bin/add-localization.py --missing` that no translations are missing

- [ ] Task 4: Write tests (AC: #1, #2, #3, #4)
  - [ ] 4.1 Test that `SettingsScreen.helpSections` returns expected count (5 sections — one per settings group)
  - [ ] 4.2 Test that each help section title matches the expected setting group name
  - [ ] 4.3 Test that help sections for non-obvious settings contain practical context (e.g., "440" in concert pitch help, tuning system help contains "Equal Temperament" or key term)

- [ ] Task 5: Build and verify (AC: #1, #2, #3, #4)
  - [ ] 5.1 Run `bin/build.sh` — clean build
  - [ ] 5.2 Run `bin/test.sh` — all tests pass
  - [ ] 5.3 Run `bin/check-dependencies.sh` — dependency rules pass
  - [ ] 5.4 Verify English and German help content manually in simulator

## Dev Notes

### Implementation Approach: HelpContentView Sheet on Settings Screen

The `HelpContentView` reusable component (created in the quick spec "Template-Based Localized Help Content") already exists at `Peach/App/HelpContentView.swift`. It takes `[HelpSection]` and renders each section as a `.headline` title + Markdown body text with `AttributedString(markdown:)`.

The approach is to add a toolbar help button to `SettingsScreen` that presents a `.sheet()` containing `HelpContentView` with settings-specific help sections. This mirrors how `InfoScreen` already uses `HelpContentView`.

**Proposed help presentation structure:**
```
.sheet {
  NavigationStack {
    ScrollView {
      VStack(spacing: 24) {
        HelpContentView(sections: Self.helpSections)
      }
      .padding()
    }
    .navigationTitle("Settings Help")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Done") { dismiss() }
      }
    }
  }
}
```

### Settings Sections and Their Help Content

The Settings Screen has 5 `Form` sections that each need help text:

| Section | Settings | Help Focus |
|---------|----------|------------|
| Training Range | Lowest Note, Highest Note | Note range for training, why narrow/widen |
| Intervals | Interval grid selector | What intervals are, why select specific ones |
| Sound | Sound source, Duration, Concert Pitch, Tuning System | Practical context for each (440 Hz, equal vs just) |
| Difficulty | Vary Loudness slider | What it does, why harder = better |
| Data | Export, Import, Reset | Data management, backup, reset warning |

### Help Content Guidelines

- **Tone:** Friendly, encouraging, non-technical — same as Story 37.1's InfoScreen help
- **Length:** Brief — 2-4 sentences per section. Settings help should be practical, not encyclopedic
- **Non-obvious settings need extra context:**
  - **Concert Pitch:** "Most musicians use 440 Hz. Some orchestras tune to 442 Hz."
  - **Tuning System:** Explain equal temperament vs just intonation in plain language
  - **Vary Loudness:** Explain that it adds realism by varying note volume
  - **Intervals:** Brief explanation for users unfamiliar with musical intervals
- **German translations:** Must be idiomatic German, not literal translations

### Key Files to Modify

| File | Change |
|------|--------|
| `Peach/Settings/SettingsScreen.swift` | Add `helpSections` static property, help button in toolbar, help sheet |
| `Peach/Resources/Localizable.xcstrings` | Add German translations for all new help strings |
| `PeachTests/Settings/SettingsTests.swift` | Add tests for help sections content |

### No New Files Needed

All changes go into existing files. The `HelpContentView` and `HelpSection` types already exist in `Peach/App/HelpContentView.swift`.

### Existing Patterns to Follow

- **`HelpContentView` usage:** `InfoScreen` uses `HelpContentView(sections: Self.helpSections)` with static `[HelpSection]` arrays — follow this pattern exactly
- **`String(localized:)` for help text:** Each section body is a `String(localized:)` with Markdown formatting for bold terms
- **Sheet presentation:** `InfoScreen` uses `.sheet(isPresented:)` with `NavigationStack`, title, and "Done" button — replicate this pattern
- **Toolbar button placement:** Use `.navigationBarTrailing` or another appropriate placement that doesn't conflict with the existing navigation bar title
- **Static constants:** Define help content as `static let` properties for testability

### Architecture & Constraints

- **No new dependencies** — pure SwiftUI text content, reuses existing `HelpContentView`
- **No cross-feature coupling** — changes stay within `Settings/` feature directory and shared `Resources/`; `HelpContentView` is in `App/` (shared layer), accessible from all features
- **No business logic** — static help text only
- **SwiftUI String Catalogs** — English strings defined in code, German translations added via `bin/add-localization.py`
- **Zero third-party dependencies** — do not add any external packages

### What NOT to Do

- Do NOT add per-setting inline help (footer text already exists for some sections — keep those, add the help sheet as a comprehensive reference)
- Do NOT create a separate `SettingsHelpScreen.swift` — build the help sheet directly in `SettingsScreen` using `HelpContentView`
- Do NOT add images or illustrations — text only
- Do NOT add interactive elements (tutorials, walkthroughs) — that would be a separate story
- Do NOT modify existing section footers — they serve a different purpose (immediate context)
- Do NOT change any setting behavior — help is read-only content

### Previous Story Intelligence

**From Story 37.1 (Start Screen Help) and Quick Spec (Template-Based Localized Help Content):**
- `HelpContentView` component lives at `Peach/App/HelpContentView.swift`
- `HelpSection` struct has `title: String` and `body: String` properties
- `HelpContentView` renders sections with `.headline` title + Markdown body via `AttributedString(markdown:)`
- Markdown supports **bold**, *italic*, [links](url), but NOT headers, lists, or block-level elements
- `\n\n` creates paragraph breaks within a section body
- `InfoScreen` defines `static let helpSections: [HelpSection]` and `static let acknowledgmentsSections: [HelpSection]`
- Sheet uses `ScrollView` with `VStack(spacing: 24)` and `.padding()`
- All tests pass (935 tests as of review fixes)
- Help content uses `String(localized:)` for all user-visible text

**From Story 36.1 (Localization and Wording Review):**
- German terminology settled: "Cent" singular/plural, "Übung" for training
- Settings labels: Sound (was Sound Source), Concert Pitch (was Reference Pitch), Lowest/Highest Note (was Lower/Upper)
- Section headers: "Training Range", "Intervals", "Sound", "Difficulty", "Data"
- Use `bin/add-localization.py` for adding translations, `--missing` to verify

### Git Intelligence

Recent commits (most recent first):
1. `1cee06b` Implement quick spec: Template-Based Localized Help Content — created `HelpContentView`, refactored `InfoScreen` to use it
2. `0f7feed` Create quick spec: Template-Based Localized Help Content
3. `7e20a3b` Review story 37.1: Fix dead code, dynamic copyright year, stronger tests
4. `0c66c03` Implement story 37.1: Start Screen Help

The codebase is clean and stable. The `HelpContentView` pattern is fresh and proven.

### Project Structure Notes

- Changes align with existing `Settings/` feature directory
- No new directories or files needed
- `HelpContentView` in `App/` is already accessible from `Settings/`
- Test coverage extends existing `PeachTests/Settings/SettingsTests.swift`

### References

- [Source: docs/planning-artifacts/epics.md#Epic 37, Story 37.2]
- [Source: docs/project-context.md#Framework-Specific Rules — SwiftUI Views, String Catalogs]
- [Source: Peach/Settings/SettingsScreen.swift — current SettingsScreen implementation with 5 sections]
- [Source: Peach/App/HelpContentView.swift — reusable HelpContentView component]
- [Source: Peach/Info/InfoScreen.swift — pattern for HelpContentView usage in a sheet]
- [Source: docs/implementation-artifacts/tech-spec-template-based-localized-help-content.md — HelpContentView creation spec]
- [Source: docs/implementation-artifacts/37-1-start-screen-help.md — previous story learnings]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
