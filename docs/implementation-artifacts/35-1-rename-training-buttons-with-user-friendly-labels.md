# Story 35.1: Rename Training Buttons with User-Friendly Labels

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want the training buttons to have approachable, descriptive names,
so that I understand what each training mode does without needing music theory knowledge.

## Acceptance Criteria

1. **Given** the Start Screen training buttons **When** they are displayed **Then** the labels use user-friendly names instead of the current technical names. Suggested names (final names to be confirmed during implementation):
   - "Comparison" → "Hear & Compare" / "Hören & Vergleichen"
   - "Pitch Matching" → "Tune & Match" / "Stimmen & Treffen"
   - "Interval Comparison" → "Hear Intervals" / "Intervalle hören"
   - "Interval Pitch Matching" → "Tune Intervals" / "Intervalle stimmen"

2. **Given** the German localization **When** the Start Screen is displayed in German **Then** the button labels are appropriately translated with natural, approachable German phrasing.

3. **Given** all navigation and accessibility labels **When** buttons are renamed **Then** VoiceOver labels accurately describe each training mode (VoiceOver should read the full button label; no separate `.accessibilityLabel` needed since the `Text` content is already descriptive).

## Tasks / Subtasks

- [ ] Task 1: Rename button labels in StartScreen.swift (AC: #1, #3)
  - [ ] 1.1 Change the four `Text()` strings in `StartScreen.swift` from current technical names to new user-friendly names
  - [ ] 1.2 Confirm the new names are self-explanatory and consistent (discuss with user if needed)
- [ ] Task 2: Update localization for both languages (AC: #2)
  - [ ] 2.1 Update English strings in `Localizable.xcstrings` (new keys will auto-generate when old Text values change)
  - [ ] 2.2 Add/update German translations using `bin/add-localization.py`
  - [ ] 2.3 Remove orphaned localization keys for old button names if they are no longer used anywhere
- [ ] Task 3: Verify VoiceOver accessibility (AC: #3)
  - [ ] 3.1 Confirm no explicit `.accessibilityLabel` overrides exist on training buttons that would need updating (currently none exist — the Text content IS the accessibility label)
- [ ] Task 4: Update tests (AC: #1)
  - [ ] 4.1 Update any test assertions in `StartScreenTests.swift` that reference old button label strings
- [ ] Task 5: Build and run full test suite
  - [ ] 5.1 Run `bin/build.sh` to verify no build errors
  - [ ] 5.2 Run `bin/test.sh` to verify all tests pass

## Dev Notes

### Current Implementation

The Start Screen is at `Peach/Start/StartScreen.swift` (110 lines). It contains four `NavigationLink` buttons in a `VStack`:

```swift
// Current button labels (lines 34, 41, 52, 60):
Text("Comparison")              // → NavigationDestination.comparison(intervals: [.prime])
Text("Pitch Matching")          // → NavigationDestination.pitchMatching(intervals: [.prime])
Text("Interval Comparison")     // → NavigationDestination.comparison(intervals: intervalSelection.intervals)
Text("Interval Pitch Matching") // → NavigationDestination.pitchMatching(intervals: intervalSelection.intervals)
```

All buttons use `.controlSize(.large)` and `.frame(maxWidth: .infinity)`. The first button uses `.borderedProminent`, the rest use `.bordered`.

### Architecture & Constraints

- **Localization**: App uses String Catalogs (`Localizable.xcstrings`). When you change a `Text("...")` string in SwiftUI, Xcode auto-extracts the new key. Old keys become orphaned and should be cleaned up.
- **Use `bin/add-localization.py`** to add German translations. Single mode: `bin/add-localization.py "Hear & Compare" "Hören & Vergleichen"`. Or use `--batch` for multiple at once.
- **No `.accessibilityLabel` on training buttons currently** — SwiftUI `Text` content serves as the VoiceOver label automatically. The new names should be descriptive enough for VoiceOver without needing separate labels.
- **NavigationDestination enum** (`Peach/App/NavigationDestination.swift`) is not affected — it uses typed enum cases, not string labels.
- **No cross-feature coupling** — this change is entirely within `Peach/Start/StartScreen.swift` and localization resources.

### Key Files to Modify

| File | Change |
|------|--------|
| `Peach/Start/StartScreen.swift` | Update 4 `Text()` string literals |
| `Peach/Resources/Localizable.xcstrings` | New English keys auto-extracted; add German translations |
| `PeachTests/Start/StartScreenTests.swift` | Update any string-based assertions if present |

### Testing Standards

- **Swift Testing** framework only (`@Test`, `@Suite`, `#expect`)
- **Behavioral descriptions**: `@Test("displays user-friendly button labels")`
- Run full test suite with `bin/test.sh` — never just specific files

### What NOT to Do

- Do NOT rename the `NavigationDestination` enum cases — those are code identifiers, not user-facing
- Do NOT add `.accessibilityLabel` modifiers — the `Text` content already serves as the VoiceOver label
- Do NOT change button styles, layout, or spacing — that's Story 35.3
- Do NOT add icons — that's Story 35.2
- Do NOT restructure the StartScreen view — keep changes minimal to button label text only

### Project Structure Notes

- Alignment: Fully aligned with project structure. Changes are localized to `Peach/Start/` and `Peach/Resources/`.
- No conflicts or variances detected.

### References

- [Source: docs/planning-artifacts/epics.md#Epic 35, Story 35.1]
- [Source: Peach/Start/StartScreen.swift — current button implementation]
- [Source: docs/project-context.md#Framework-Specific Rules — localization via String Catalogs]
- [Source: docs/project-context.md#Code Quality — naming conventions]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
