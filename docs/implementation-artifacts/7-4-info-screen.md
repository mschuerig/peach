# Story 7.4: Info Screen

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to view basic information about the app,
so that I know the version, who made it, and where to find the project.

## Acceptance Criteria

1. Given the Start Screen, when the user taps the Info button (`info.circle` SF Symbol), then an Info Screen is presented as a `.sheet()`
2. Given the Info Screen, when displayed, then it shows the following information:
   - App name (Peach)
   - Developer name and email address (Michael Schürig, michael@schuerig.de)
   - App version number (pulled from bundle via `CFBundleShortVersionString`)
   - Project website on GitHub (https://github.com/mschuerig/peach) as a tappable link
   - License (MIT)
   - Copyright year (2026)
3. Given the Info Screen, when displayed, then it uses stock SwiftUI layout with clear visual hierarchy
4. Given the Info Screen, when dismissed (swipe down or tap Done), then the user returns to the Start Screen
5. Given the Info Screen text, when localization is active, then static labels are localized (app name, developer name, email, and URL remain as-is)
6. Given the GitHub link, when the user taps it, then it opens in the system browser via `Link` (SwiftUI) or `openURL`

## Tasks / Subtasks

- [x] Task 1: Update InfoScreen.swift with new content (AC: #2, #3, #6)
  - [x] Add developer email address below or alongside developer name
  - [x] Add GitHub project URL as a tappable `Link` component
  - [x] Add license line showing "MIT License"
  - [x] Ensure copyright year displays as "© 2026"
  - [x] Maintain stock SwiftUI layout with clear section grouping
  - [x] Verify layout works in both light and dark mode

- [x] Task 2: Update localization strings (AC: #5)
  - [x] Add new localized strings for any new labels (e.g., "License", "Website", email-related labels)
  - [x] Add German translations for all new strings
  - [x] Verify existing Info screen strings remain correct
  - [x] App name, developer name, email address, and URL are NOT localized (proper nouns / identifiers)

- [x] Task 3: Update tests (AC: #1–#6)
  - [x] Verify InfoScreen still presents as sheet from StartScreen (existing behavior, spot-check)
  - [x] Add any relevant unit tests for new content if testable logic exists (e.g., bundle version extraction)
  - [x] Run full test suite: `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [x] Verify zero regressions across all existing tests

## Dev Notes

### Architecture & Patterns

- **InfoScreen location:** `Peach/Info/InfoScreen.swift` — the only file in the `Info/` feature group. Per architecture doc, FR43 maps to `InfoScreen` in `Info/` directory.
- **Presentation:** `.sheet()` from StartScreen, triggered by `showInfoSheet` state variable. Already implemented and working — this story only modifies content within the existing sheet.
- **Navigation:** Hub-and-spoke model — Info Screen returns to Start Screen when dismissed. Already implemented via sheet dismissal.
- **Stock SwiftUI only:** No custom components. Use `Text`, `Link`, `VStack`, standard layout. Per UX spec: "Presented as a standard SwiftUI sheet. Minimal content, stock presentation."
- **Liquid Glass:** Accept iOS 26 default appearance. No custom styles.
- **`@Observable` pattern:** Not needed — InfoScreen has no observable state. It reads from bundle and displays static content.
- **Error handling:** Not applicable — no service calls, no failure modes.

### Current Implementation (What Exists)

The current `InfoScreen.swift` already displays:
- App title "Peach" in `.largeTitle` bold
- "Developer: Michael" with `.headline` font
- "© 2026" as copyright in `.subheadline` secondary color
- Version number from `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` in `.subheadline` secondary color
- "Done" dismiss button in toolbar
- Navigation title "Info" with `.inline` display mode
- Centered VStack layout with `spacing: 20`

### Changes Required

**Add to the existing InfoScreen:**
1. **Email address** — add `michael@schuerig.de` below or alongside the developer name. Use `Text` (not a mailto: link unless user requests it).
2. **GitHub project URL** — `https://github.com/mschuerig/peach`. Use SwiftUI `Link` component for tappable link that opens in Safari.
3. **License** — display "MIT License" as a text line.
4. **Copyright year** — already shows "© 2026", confirm this satisfies the requirement.

### Implementation Guidance

- Use SwiftUI `Link("GitHub", destination: URL(string: "https://github.com/mschuerig/peach")!)` or similar for the website link.
- Group related information visually (e.g., app identity at top, developer info in middle, legal/project info at bottom) using spacing or subtle section breaks.
- Keep the existing `.navigationTitle("Info")` and `.toolbar` dismiss button.
- Maintain the existing localization pattern: use `String(localized:)` for label text, leave proper nouns unlocalized.
- The email address and GitHub URL are string literals, not localized values.

### Localization Notes

**Strings to localize (labels only):**
- Any new label text like "License:" or "Website" (if used as separate labels)
- Existing strings: "Info", "Done", "Developer: %@", "Version %@", "© 2026" — already localized in English and German

**Strings NOT to localize:**
- "Peach" (app name)
- "Michael Schürig" (developer name)
- "michael@schuerig.de" (email)
- "https://github.com/mschuerig/peach" (URL)
- "MIT License" (license name — this is a proper noun, but the word "License" as a label should be localized)

### What NOT To Change

- Do NOT modify StartScreen.swift — the Info button and sheet presentation already work correctly
- Do NOT change the sheet presentation mechanism (`.sheet()`)
- Do NOT add any custom styles, colors, or fonts — stock SwiftUI only
- Do NOT add navigation (e.g., NavigationLink) within the Info screen — it's a simple informational sheet
- Do NOT add any third-party dependencies
- Do NOT break existing localization strings — only add new ones

### Project Structure Notes

- Only file to modify: `Peach/Info/InfoScreen.swift`
- Localization file to update: `Peach/Resources/Localizable.xcstrings` (add new label strings with German translations)
- No new files needed
- No structural changes to the project

### References

- [Source: docs/planning-artifacts/epics.md#Story 7.4] — Original acceptance criteria (modified per user request)
- [Source: docs/planning-artifacts/prd.md#FR43] — "User can view an Info Screen from the Start Screen showing app name, developer, copyright, and version number"
- [Source: docs/planning-artifacts/architecture.md#Project Organization] — `Info/InfoScreen.swift` file location
- [Source: docs/planning-artifacts/architecture.md#Requirements to Structure Mapping] — "Info Screen (FR43) → InfoScreen → Info/"
- [Source: docs/planning-artifacts/ux-design-specification.md#Info Screen] — "Presented as a standard SwiftUI sheet. Minimal content, stock presentation."
- [Source: docs/planning-artifacts/ux-design-specification.md#Component Strategy] — "Info button: Button with Image(systemName: 'info.circle')"
- [Source: docs/planning-artifacts/ux-design-specification.md#Navigation Patterns] — "Sheets for lightweight screens: Info Screen presented as .sheet()"
- [Source: Peach/Info/InfoScreen.swift] — Current implementation with VStack, spacing: 20, largeTitle, Done button
- [Source: Peach/Start/StartScreen.swift] — Info button triggers showInfoSheet state, presents InfoScreen as sheet
- [Source: README.md] — Project URL: https://github.com/mschuerig/peach, Author: Michael Schürig
- [Source: LICENSE] — MIT License, Copyright 2026 Michael Schürig

### Previous Story Learnings (7.3, 7.2, 7.1)

- **Localization pattern:** All strings use `String(localized:)` for non-view-context strings. SwiftUI view `Text("literal")` auto-extracts to string catalog. New label strings must have both English and German translations.
- **Testing pattern:** Swift Testing framework (`@Test`, `#expect()`). Run full suite, not just new tests.
- **Code review pattern:** Three-commit pattern: story creation → implementation → code review fixes.
- **Extract testable helpers:** If any logic warrants testing (e.g., version string formatting), extract to a static method. For this story, minimal logic — mostly static content display.
- **Test count baseline:** 264 tests pass (from Story 7.3). Maintain zero regressions.
- **Accessibility:** All stock SwiftUI components are auto-labeled. The `Link` component is VoiceOver-accessible by default. No custom accessibility work needed for this story.

### Git Intelligence

Recent commits:
- `c6863f3` — Add README, MIT license, NOTICE, and sample library research; set version to 0.1
- `78ecd19` — Code review fixes for Story 7.3: extract layout helpers, add tests, single source of truth
- `b8b148b` — Implement story 7.3: iPhone, iPad, Portrait, and Landscape Support

The README and LICENSE files were added in the most recent commit, confirming: developer is "Michael Schürig", license is "MIT", project URL is "https://github.com/mschuerig/peach", version is 0.1.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None — no errors or debugging required.

### Completion Notes List

- Updated InfoScreen.swift with full developer info (name "Michael Schürig", email), GitHub `Link` component, "License: MIT" label, and visual grouping into two VStack sections (developer info + project/legal info)
- Added `static let gitHubURL` property to InfoScreen for testability
- Used `Text(verbatim:)` for email address to prevent localization lookup
- Used `Text("License: \("MIT")")` pattern to localize the "License:" label while keeping "MIT" as a proper noun
- Added "GitHub" and "License: %@" → "Lizenz: %@" to Localizable.xcstrings with German translations
- Added unit test `infoScreenHasCorrectGitHubURL()` to verify the static URL property
- All 265 tests pass (264 baseline + 1 new), zero regressions

### Change Log

- 2026-02-18: Implemented Story 7.4 — added developer email, GitHub link, MIT license, and copyright to Info Screen with localization

### File List

- Peach/Info/InfoScreen.swift (modified)
- Peach/Resources/Localizable.xcstrings (modified)
- PeachTests/Start/StartScreenTests.swift (modified)
- docs/implementation-artifacts/7-4-info-screen.md (modified)
- docs/implementation-artifacts/sprint-status.yaml (modified)
