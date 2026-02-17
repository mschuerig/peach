# Story 7.1: English and German Localization

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to use the app in English or German,
so that the interface is in my preferred language.

## Acceptance Criteria

1. Given all user-facing strings in the app, when localization is applied, then every string is externalized to String Catalogs (`Localizable.xcstrings`) and English and German translations are provided for all strings
2. Given the device language is set to German, when the app is launched, then all UI text appears in German
3. Given the device language is set to English (or any unsupported language), when the app is launched, then all UI text appears in English (default)
4. Given custom components (profile visualization, profile preview, feedback indicator), when they display text (e.g., "Start training to build your profile", statistics labels), then that text is also localized

## Tasks / Subtasks

- [x] Task 1: Fix non-localizable string patterns in SummaryStatisticsView (AC: #1, #4)
  - [x] Change `statItem(label:value:)` to accept `LocalizedStringKey` for the `label` parameter so that "Mean", "Std Dev" labels are localized when passed through to `Text(label)`
  - [x] Replace manual "cent"/"cents" pluralization in `formatMean()` and `formatStdDev()` with `String(localized:)` using a single interpolated key that leverages String Catalog "Vary by Plural" (e.g., `String(localized: "\(rounded) cents")` with plural variants in catalog)
  - [x] Replace hardcoded accessibility strings in `accessibilityMean()`, `accessibilityStdDev()`, `accessibilityTrend()` with `String(localized:)` calls so they are picked up by the localization system
  - [x] Ensure the container `.accessibilityLabel("No training data yet")` and `.accessibilityLabel("Summary statistics")` remain auto-extracted (they already use string literals in SwiftUI modifiers — no change needed)

- [x] Task 2: Fix non-localizable accessibility strings in ProfileScreen (AC: #1, #4)
  - [x] Replace the `String` return in `accessibilitySummary(profile:midiRange:)` with `String(localized:)` calls for both the empty state ("Perceptual profile. No training data available.") and the data state ("Perceptual profile showing detection thresholds from \(lowestName) to \(highestName)...")

- [x] Task 3: Fix non-localizable accessibility strings in ProfilePreviewView (AC: #1, #4)
  - [x] Replace the `String` return in `accessibilityLabel(profile:midiRange:)` with `String(localized:)` calls for both variants ("Your pitch profile. Tap to view details." and "Your pitch profile. Tap to view details. Average threshold: \(threshold) cents.")

- [x] Task 4: Fix InfoScreen "Developer:" label for localization (AC: #1)
  - [x] Change `Text("Developer: Michael")` to use a localized format string like `Text("Developer: \(developerName)")` where `developerName` is "Michael" (the "Developer:" prefix localizes, the name stays as-is per Story 7.4 AC)

- [x] Task 5: Add German translations to Localizable.xcstrings (AC: #1, #2, #3)
  - [x] Build the project once after code changes to ensure all new/changed string keys are extracted into the String Catalog
  - [x] Add German translations for all string keys (see Translation Table in Dev Notes)
  - [x] Configure pluralization for "cent"/"cents" keys using "Vary by Plural" (German uses "Cent" for both singular and plural)
  - [x] Verify no string keys are marked stale or missing

- [x] Task 6: Write tests (AC: #2, #3)
  - [x] Test that `SummaryStatisticsView.formatMean()` returns a localized string (verify the string uses localization APIs, not hardcoded English)
  - [x] Test that `SummaryStatisticsView.formatStdDev()` returns a localized string
  - [x] Test that `ProfileScreen.accessibilitySummary()` returns a localized string
  - [x] Test that `ProfilePreviewView.accessibilityLabel()` returns a localized string
  - [x] Test that `SummaryStatisticsView.accessibilityTrend()` returns a localized string
  - [x] Note: Testing actual German translations requires setting the test locale — verify at minimum that `String(localized:)` is used (the localization system itself is tested by Apple)

## Dev Notes

### Architecture & Patterns

- **SwiftUI auto-extraction is already working:** Most strings in `Text("literal")`, `Button("literal")`, `.navigationTitle("literal")`, `.accessibilityLabel("literal")`, `Section("literal")`, `.alert("literal")`, and `.confirmationDialog("literal")` are already auto-extracted into `Localizable.xcstrings` (37 keys exist). No code changes needed for these.
- **The problem: `String` return values bypass localization.** When a function returns a `String` and that string is passed to `Text(variable)` or `.accessibilityLabel(variable)`, SwiftUI uses the non-localizing `StringProtocol` initializer instead of the `LocalizedStringKey` initializer. This affects:
  - `SummaryStatisticsView.formatMean()` / `formatStdDev()` — display strings
  - `SummaryStatisticsView.accessibilityMean()` / `accessibilityStdDev()` / `accessibilityTrend()` — VoiceOver strings
  - `ProfileScreen.accessibilitySummary()` — VoiceOver string
  - `ProfilePreviewView.accessibilityLabel()` — VoiceOver string
- **Fix pattern: use `String(localized:)`** for all strings constructed in methods that return `String`. This registers them with the localization system and ensures they appear in the String Catalog after build.
- **Pluralization:** German uses "Cent" for both singular and plural, unlike English "cent"/"cents". Replace the manual ternary-based pluralization (`rounded == 1 ? "cent" : "cents"`) with String Catalog plural variants. Use a single key like `"\(rounded) cents"` and configure "Vary by Plural" in the catalog.

### Translation Table

| English Key | German Translation | Notes |
|---|---|---|
| Settings | Einstellungen | |
| Peach | Peach | App name — do not translate |
| Training | Training | Same in German |
| Profile | Profil | |
| Info | Info | Same in German |
| Start Training | Training starten | |
| Higher | Höher | |
| Lower | Tiefer | |
| Algorithm | Algorithmus | |
| Natural vs. Mechanical | Natürlich vs. Mechanisch | Slider accessibility label |
| Natural | Natürlich | |
| Mechanical | Mechanisch | |
| Note Range | Tonumfang | |
| Lower: %@ | Untere Grenze: %@ | Settings stepper |
| Upper: %@ | Obere Grenze: %@ | Settings stepper |
| Audio | Audio | Same in German |
| Duration: %.1fs | Dauer: %.1fs | |
| Reference Pitch: %lld Hz | Referenztonhöhe: %lld Hz | |
| Sound Source | Klangquelle | |
| Sine Wave | Sinuswelle | |
| Data | Daten | |
| Reset All Training Data | Alle Trainingsdaten löschen | |
| Reset Training Data | Trainingsdaten löschen | Confirmation dialog title |
| Reset | Zurücksetzen | Destructive button |
| This will permanently delete all training data and reset your profile. This cannot be undone. | Alle Trainingsdaten werden unwiderruflich gelöscht und dein Profil wird zurückgesetzt. | |
| Reset Failed | Zurücksetzen fehlgeschlagen | |
| Could not delete training records. Please try again. | Trainingsdaten konnten nicht gelöscht werden. Bitte versuche es erneut. | |
| OK | OK | Same in German |
| Done | Fertig | |
| Mean | Mittelwert | |
| Std Dev | Std.abw. | Short for Standardabweichung |
| Trend | Trend | Same in German |
| Start training to build your profile | Trainiere, um dein Profil aufzubauen | |
| Developer: %@ | Entwickler: %@ | Format string with name |
| © 2026 | © 2026 | Same in German |
| Version %@ | Version %@ | Same in German |
| No training data yet | Noch keine Trainingsdaten | Accessibility |
| Summary statistics | Zusammenfassung | Accessibility |
| Correct | Richtig | Feedback indicator |
| Incorrect | Falsch | Feedback indicator |
| Your pitch profile. Tap to view details. | Dein Tonhöhenprofil. Tippe für Details. | ProfilePreview accessibility |
| Your pitch profile. Tap to view details. Average threshold: %lld cents. | Dein Tonhöhenprofil. Tippe für Details. Durchschnittliche Schwelle: %lld Cent. | ProfilePreview accessibility |
| Perceptual profile. No training data available. | Wahrnehmungsprofil. Keine Trainingsdaten vorhanden. | ProfileScreen accessibility |
| Perceptual profile showing detection thresholds from %@ to %@. Average threshold: %lld cents. | Wahrnehmungsprofil mit Erkennungsschwellen von %@ bis %@. Durchschnittliche Schwelle: %lld Cent. | ProfileScreen accessibility |
| Mean detection threshold: %lld cents | Mittlere Erkennungsschwelle: %lld Cent | Accessibility (plural-varied) |
| Standard deviation: %lld cents | Standardabweichung: %lld Cent | Accessibility (plural-varied) |
| Trend: improving | Trend: verbessernd | Accessibility |
| Trend: stable | Trend: stabil | Accessibility |
| Trend: declining | Trend: nachlassend | Accessibility |
| %lld cents (display) | %lld Cent | Pluralization: German "Cent" for both singular/plural |
| ±%lld cents (display) | ±%lld Cent | Pluralization: German "Cent" for both singular/plural |

### Key Code Changes

**SummaryStatisticsView.swift — statItem label parameter:**
```swift
// BEFORE (not localizable):
private func statItem(label: String, value: String) -> some View {
    VStack(spacing: 2) {
        Text(value)    // StringProtocol init — NOT localized
        Text(label)    // StringProtocol init — NOT localized
    }
}

// AFTER (localizable):
private func statItem(label: LocalizedStringKey, value: String) -> some View {
    VStack(spacing: 2) {
        Text(value)    // value still String (it's computed data, not a translatable key)
        Text(label)    // LocalizedStringKey init — LOCALIZED
    }
}
```

**SummaryStatisticsView.swift — formatMean/formatStdDev:**
```swift
// BEFORE (hardcoded English pluralization):
static func formatMean(_ value: Double?) -> String {
    guard let value else { return "—" }
    let rounded = Int(value.rounded())
    return "\(rounded) \(rounded == 1 ? "cent" : "cents")"
}

// AFTER (localized with plural support):
static func formatMean(_ value: Double?) -> String {
    guard let value else { return "—" }
    let rounded = Int(value.rounded())
    return String(localized: "\(rounded) cents")
    // String Catalog entry with "Vary by Plural":
    //   en: one → "1 cent", other → "%lld cents"
    //   de: one → "1 Cent", other → "%lld Cent"
}
```

**SummaryStatisticsView.swift — accessibility methods:**
```swift
// BEFORE:
static func accessibilityMean(_ value: Double?) -> String {
    guard let value else { return "No training data yet" }
    let rounded = Int(value.rounded())
    return "Mean detection threshold: \(rounded) \(rounded == 1 ? "cent" : "cents")"
}

// AFTER:
static func accessibilityMean(_ value: Double?) -> String {
    guard let value else { return String(localized: "No training data yet") }
    let rounded = Int(value.rounded())
    return String(localized: "Mean detection threshold: \(rounded) cents")
    // Plural-varied in catalog
}
```

**ProfileScreen.swift — accessibilitySummary:**
```swift
// BEFORE:
return "Perceptual profile showing detection thresholds from \(lowestName) to \(highestName). Average threshold: \(roundedThreshold) cents."

// AFTER:
return String(localized: "Perceptual profile showing detection thresholds from \(lowestName) to \(highestName). Average threshold: \(roundedThreshold) cents.")
```

**ProfilePreviewView.swift — accessibilityLabel:**
```swift
// BEFORE:
return "Your pitch profile. Tap to view details. Average threshold: \(threshold) cents."

// AFTER:
return String(localized: "Your pitch profile. Tap to view details. Average threshold: \(threshold) cents.")
```

**InfoScreen.swift — developer label:**
```swift
// BEFORE:
Text("Developer: Michael")

// AFTER:
Text("Developer: \("Michael")")
// The "Developer:" prefix is extracted as part of the format string and translated
// "Michael" stays as-is as the interpolated value
```

### What NOT To Change

- **SwiftUI `Text("literal")` views** — already auto-extracted. Do not wrap in `String(localized:)`.
- **SwiftUI `.accessibilityLabel("literal")` on views** — already auto-extracted. No change needed.
- **Button labels, section headers, navigation titles** — already auto-extracted. No change needed.
- **SettingsScreen.swift** — all strings are already in SwiftUI views. No changes needed.
- **TrainingScreen.swift** — "Higher", "Lower" are `Text("literal")`, already extracted. No changes needed.
- **StartScreen.swift** — all strings are SwiftUI literals. No changes needed.
- **FeedbackIndicator.swift** — "Correct"/"Incorrect" are `.accessibilityLabel("literal")`, already extracted. No changes needed.
- **PianoKeyboardView.swift / ConfidenceBandView.swift** — no user-facing strings (note names are not localized — C4, D#5 are universal).
- **Core/ services** (TrainingSession, NotePlayer, etc.) — no user-facing strings.

### Risks & Edge Cases

- **Note names (C4, D#5, etc.) are NOT localized.** Musical note names are internationally standardized. German musicians use the same names (with the exception of B/H — German uses H for B natural and B for Bb). However, this is a pitch training app using MIDI note names from `PianoKeyboardLayout.noteName()`, and the standard C-D-E-F-G-A-B convention is universally understood. Changing to German note names (H instead of B) would be a separate feature decision, not part of this localization story.
- **"cent" / "Cent" capitalization:** German capitalizes the noun ("Cent"), English does not ("cent"/"cents"). The String Catalog pluralization handles this correctly per language.
- **Format specifier ordering:** All format strings use arguments in the same order between English and German, so no positional specifiers (%1$@, %2$@) are needed.
- **"—" (em dash) for empty stats:** This is a universal symbol and does not need localization.
- **App name "Peach" is NOT translated.** It's a proper noun / brand name.
- **Informal "du" form in German:** The translations use the informal "du" form (e.g., "dein Profil"), which is standard for consumer apps targeting musicians. This is consistent with Apple's own German UI conventions.

### Project Structure Notes

- Files to modify: `Peach/Profile/SummaryStatisticsView.swift`, `Peach/Profile/ProfileScreen.swift`, `Peach/Start/ProfilePreviewView.swift`, `Peach/Info/InfoScreen.swift`
- File to edit: `Peach/Resources/Localizable.xcstrings` (add German translations)
- Test file to modify: `PeachTests/Profile/SummaryStatisticsViewTests.swift` (if exists), or create if needed
- No new Swift files needed
- No structural changes to the project

### References

- [Source: docs/planning-artifacts/epics.md#Story 7.1] — BDD acceptance criteria
- [Source: docs/planning-artifacts/prd.md#FR37] — "User can use the app in English or German"
- [Source: docs/planning-artifacts/architecture.md#Technology Decisions] — "String Catalogs (Xcode 26 native) for English/German"
- [Source: docs/planning-artifacts/architecture.md#Project Organization] — "Resources/Localizable.xcstrings"
- [Source: docs/planning-artifacts/ux-design-specification.md#Accessibility Strategy] — Custom component accessibility labels must be localized
- [Source: Peach/Resources/Localizable.xcstrings] — Existing String Catalog with 37 auto-extracted keys, only "Peach" translated to German
- [Source: Peach/Profile/SummaryStatisticsView.swift:107-117] — formatMean/formatStdDev with hardcoded English pluralization
- [Source: Peach/Profile/SummaryStatisticsView.swift:121-139] — Accessibility methods returning plain String
- [Source: Peach/Profile/ProfileScreen.swift:81-95] — accessibilitySummary returning plain String
- [Source: Peach/Start/ProfilePreviewView.swift:34-39] — accessibilityLabel returning plain String
- [Source: Peach/Info/InfoScreen.swift:16] — "Developer: Michael" hardcoded
- [Source: Peach.xcodeproj/project.pbxproj:171] — knownRegions = (en, Base, de) already configured

### Previous Story Learnings (6.2)

- `@AppStorage` inside `@Observable` conflicts — uses direct `UserDefaults.standard` reads. Not relevant to this story but shows awareness of Swift macro interactions.
- Pattern: implementation commit → code review fixes commit. Follow same pattern.
- 234 total tests pass — maintain zero regressions.
- Test helpers use `settingsOverride:` for deterministic behavior — maintain this pattern for any new tests.

### Git Intelligence

Recent commits (Story 6.2 completion):
- `01ed969` — Code review fixes for Story 6.2: cache duration, add mid-training test, fix docs
- `9112342` — Implement story 6.2: Apply Settings to Training in Real Time
- `f2b1026` — Add story 6.2: Apply Settings to Training in Real Time

Pattern: story creation commit → implementation commit → code review fixes commit. Swift Testing framework (`@Test`, `#expect()`). All 234 tests currently pass.

### Web Research: String Catalog Best Practices (Xcode 26)

- **Auto-extraction:** SwiftUI `Text("literal")` and all modifiers accepting `LocalizedStringKey` are automatically extracted into the String Catalog at build time. No manual registration needed.
- **`String(localized:)` for non-SwiftUI contexts:** When constructing strings in methods returning `String` (e.g., accessibility labels), use `String(localized:)` to register with the localization system.
- **Pluralization:** String Catalogs support "Vary by Plural" natively. Right-click a key in Xcode → "Vary by Plural" to add `one`/`other` variants per language. English needs `one` and `other`; German also needs `one` and `other`.
- **String interpolation:** `Text("Value: \(x)")` is auto-extracted with format specifiers (e.g., `%lld`, `%@`). Translators can reorder arguments using positional specifiers.
- **Xcode 26 new features:** Format version 1.1, automatic comment generation, type-safe Swift symbols via "Generate String Catalog Symbols" build setting.
- **Testing locale:** Change app language in scheme settings (Product → Scheme → Edit Scheme → Run → Options → App Language → German) to test localization.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- German simulator locale caused initial test failures — resolved by making tests locale-independent using `String(localized:)` in expectations

### Completion Notes List

- Task 1: Changed `statItem(label:)` from `String` to `LocalizedStringKey`; replaced hardcoded English pluralization in `formatMean`/`formatStdDev` with `String(localized:)` and plural-varied catalog entries; converted all accessibility methods (`accessibilityMean`, `accessibilityStdDev`, `accessibilityTrend`) to use `String(localized:)`
- Task 2: Converted `ProfileScreen.accessibilitySummary()` to use `String(localized:)` for both empty and data states
- Task 3: Converted `ProfilePreviewView.accessibilityLabel()` to use `String(localized:)` for both cold start and trained states
- Task 4: Changed `Text("Developer: Michael")` to `Text("Developer: \("Michael")")` so the "Developer:" prefix is localized via format string
- Task 5: Rewrote `Localizable.xcstrings` with German translations for all 50+ string keys; added "Vary by Plural" for `%lld cents`, `±%lld cents`, and all accessibility strings containing "cents"; removed stale `Developer: Michael` key, added new `Developer: %@` key
- Task 6: Added 4 new localization tests (formatMean, formatStdDev, accessibilityTrend, accessibilitySummary empty state); updated 5 existing tests to be locale-independent using `String(localized:)` in expectations. Total: 238 tests pass, 0 failures.

### Change Log

- 2026-02-18: Implemented Story 7.1 — English and German localization with plural support, accessibility localization, and full String Catalog translations

### File List

- Peach/Profile/SummaryStatisticsView.swift (modified — LocalizedStringKey for statItem label, String(localized:) for formatMean/formatStdDev/accessibility methods)
- Peach/Profile/ProfileScreen.swift (modified — String(localized:) for accessibilitySummary)
- Peach/Start/ProfilePreviewView.swift (modified — String(localized:) for accessibilityLabel)
- Peach/Info/InfoScreen.swift (modified — format string interpolation for Developer label)
- Peach/Resources/Localizable.xcstrings (modified — added German translations for all keys, plural variants for cent/cents)
- PeachTests/Profile/SummaryStatisticsTests.swift (modified — locale-independent assertions, added localization tests)
- PeachTests/Profile/ProfileScreenTests.swift (modified — locale-independent assertions, added localization test)
- PeachTests/Start/ProfilePreviewViewTests.swift (modified — locale-independent assertions using String(localized:))
- docs/implementation-artifacts/sprint-status.yaml (modified — story status updated)
- tools/parse-xcresult.py (new — tool for parsing xcresult test failure details)
