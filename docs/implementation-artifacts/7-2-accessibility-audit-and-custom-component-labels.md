# Story 7.2: Accessibility Audit and Custom Component Labels

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want all screens to be fully accessible with VoiceOver, Dynamic Type, and sufficient contrast,
so that the app is usable with assistive technology.

## Acceptance Criteria

1. Given all stock SwiftUI components, when VoiceOver is active, then they are automatically labeled and navigable (no additional work needed)
2. Given custom components (profile visualization, profile preview, feedback indicator), when VoiceOver is active, then the profile visualization announces an aggregate summary of detection thresholds, and the profile preview announces "Your pitch profile. Tap to view details." (with threshold data if available), and the feedback indicator announces "Correct" or "Incorrect"
3. Given all text in the app, when Dynamic Type is set to the largest accessibility size, then text scales correctly and layout does not break
4. Given all UI elements, when tested for color contrast, then system semantic colors provide sufficient contrast in both light and dark mode
5. Given the Training Screen, when tested with eyes closed, then the audio-haptic loop works without visual feedback — a complete training session can be performed
6. Given system settings, when Reduce Motion is enabled, then any transitions (feedback indicator appearance/disappearance) respect the setting

## Tasks / Subtasks

- [ ] Task 1: Audit and fix Reduce Motion compliance (AC: #6)
  - [ ] Read `@Environment(\.accessibilityReduceMotion)` in TrainingScreen and pass to FeedbackIndicator (or read directly in FeedbackIndicator)
  - [ ] When Reduce Motion is enabled, replace the `.easeInOut(duration: 0.2)` animation on FeedbackIndicator with `.animation(nil)` (instant show/hide, no opacity transition)
  - [ ] Update FeedbackIndicator doc comment to accurately reflect the implementation (currently claims Reduce Motion support that doesn't exist)

- [ ] Task 2: Audit Dynamic Type at largest accessibility sizes (AC: #3)
  - [ ] Run the app in simulator at each of the 5 accessibility text sizes (AX1 through AX5) and verify every screen
  - [ ] Training Screen: verify Higher/Lower buttons, their icon+text labels, and toolbar buttons remain functional at AX5
  - [ ] Start Screen: verify Start Training button, Profile Preview, and navigation buttons remain functional at AX5
  - [ ] Profile Screen: verify summary statistics, chart labels, and cold-start text remain readable at AX5
  - [ ] Settings Screen: verify all Form controls (Slider labels, Stepper labels, Picker labels, section headers) remain functional at AX5
  - [ ] Info Screen: verify app name, developer, copyright, and version remain readable at AX5
  - [ ] Fix any layout breaks found (if any — SwiftUI's adaptive layout typically handles this, but verify)

- [ ] Task 3: Audit VoiceOver navigation on all screens (AC: #1, #2)
  - [ ] Start Screen: verify all elements are reachable and announced (Start Training, Settings, Profile, Info buttons; Profile Preview with aggregate label)
  - [ ] Training Screen: verify Higher/Lower buttons announce label and disabled/enabled state; verify Settings/Profile toolbar buttons; verify FeedbackIndicator announces "Correct"/"Incorrect" when shown
  - [ ] Profile Screen: verify profile visualization announces aggregate summary; verify summary statistics announce individual values (mean, std dev, trend); verify cold-start state announces appropriately
  - [ ] Settings Screen: verify all controls are navigable and announce current values
  - [ ] Info Screen: verify all text is announced
  - [ ] Fix any VoiceOver issues found during audit

- [ ] Task 4: Verify eyes-closed training loop (AC: #5)
  - [ ] With the simulator, activate VoiceOver, start training, and verify the complete loop works: hear two notes → tap Higher/Lower → feel haptic (if wrong) or silence (if correct) → next comparison
  - [ ] Confirm that VoiceOver does NOT interfere with the training loop timing (VoiceOver announcements of "Correct"/"Incorrect" should not block the next comparison)
  - [ ] Document any issues in Dev Notes; fix if possible

- [ ] Task 5: Verify color contrast in light and dark mode (AC: #4)
  - [ ] Verify that system semantic colors provide WCAG AA-equivalent contrast in both light and dark mode
  - [ ] Check Feedback Indicator green/red against backgrounds in both modes
  - [ ] Check profile visualization band colors against backgrounds in both modes
  - [ ] No code changes expected (system colors handle this), but document verification

- [ ] Task 6: Write tests for Reduce Motion behavior (AC: #6)
  - [ ] Test that FeedbackIndicator (or TrainingScreen) reads the `accessibilityReduceMotion` environment value
  - [ ] Test that when reduce motion is enabled, the feedback indicator transitions without animation
  - [ ] Note: Full animation testing requires UI testing (XCTest) — unit tests can verify the environment value is read and affects the computed animation value

- [ ] Task 7: Write comprehensive VoiceOver accessibility label tests (AC: #1, #2)
  - [ ] Verify existing accessibility label tests still pass (ProfilePreviewView, ProfileScreen, SummaryStatistics)
  - [ ] Add test for FeedbackIndicator accessibility label — correct state returns "Correct", incorrect state returns "Incorrect"
  - [ ] Add test that Training Screen buttons have explicit accessibility labels ("Higher", "Lower")
  - [ ] Verify all label tests use `String(localized:)` pattern (locale-independent, consistent with Story 7.1 approach)

## Dev Notes

### Architecture & Patterns

- **Most custom component accessibility is already implemented.** Stories 5.1, 5.3, and 7.1 progressively added accessibility labels to custom components. This story's primary value is the **systematic audit** to catch gaps and ensure compliance, plus the Reduce Motion fix.
- **Current accessibility state of custom components:**
  - **ProfileScreen** (profile visualization): `.accessibilityElement(children: .ignore)` + `.accessibilityLabel(accessibilitySummary)` on trained state; `.accessibilityElement(children: .combine)` on cold start state. `accessibilitySummary` returns `String(localized:)` with note range and average threshold. [Source: Peach/Profile/ProfileScreen.swift:42-43, 65]
  - **ProfilePreviewView**: `.accessibilityElement(children: .ignore)` + `.accessibilityLabel(accessibilityLabel)` + `.accessibilityAddTraits(.isButton)`. Returns localized strings with/without threshold data. [Source: Peach/Start/ProfilePreviewView.swift:21-23, 34-40]
  - **FeedbackIndicator**: `.accessibilityLabel(isCorrect ? String(localized: "Correct") : String(localized: "Incorrect"))`. [Source: Peach/Training/FeedbackIndicator.swift:27]
  - **SummaryStatisticsView**: Individual labels for mean, std dev, trend; container label for cold start/trained states; dynamic type restricted to `.accessibility3`. [Source: Peach/Profile/SummaryStatisticsView.swift:23-39]
  - **PianoKeyboardView**: No accessibility labels — rendered via Canvas. This is intentional: the parent ProfileScreen provides the aggregate label; individual keys are not VoiceOver-navigable (would be overwhelming). [Source: Peach/Profile/PianoKeyboardView.swift]
  - **ConfidenceBandView**: No accessibility labels — rendered via Swift Charts. Intentional: parent ProfileScreen provides aggregate label. [Source: Peach/Profile/ConfidenceBandView.swift]

### Reduce Motion Fix (Task 1) — The Only Required Code Change

**The gap:** FeedbackIndicator's doc comment (line 8-11) states "Respects Reduce Motion (uses simple opacity transition)" but the implementation does NOT check `@Environment(\.accessibilityReduceMotion)`. The animation in `TrainingScreen.swift` runs unconditionally.

**The fix:**

```swift
// In TrainingScreen.swift (or FeedbackIndicator.swift):
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// When showing/hiding feedback:
.animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showFeedback)
```

**Implementation choice:** Read `reduceMotion` in `TrainingScreen.swift` where the `.animation()` modifier lives (around line 58), rather than inside `FeedbackIndicator.swift` which is a pure display component. The animation control belongs to the parent that manages the show/hide state.

### Dynamic Type Expectations (Task 2)

- **Training Screen:** Higher/Lower buttons use `.font(.title)` text and 80pt SF Symbol icons inside a `.frame(maxWidth: .infinity, maxHeight: .infinity)` with `minHeight: 200`. At extreme Dynamic Type sizes, the text will grow but the buttons have unconstrained height — should work fine. The icons at 80pt fixed size won't scale with Dynamic Type (they're large enough already).
- **Start Screen:** Uses `.buttonStyle(.borderedProminent)` for Start Training and standard icon buttons. Should scale automatically.
- **Settings Screen:** Uses stock `Form` with `Slider`, `Stepper`, `Picker` — these are Apple's components and scale properly.
- **Profile Screen:** SummaryStatisticsView already restricts to `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` to prevent layout overflow — this is an appropriate ceiling.
- **Info Screen:** Simple `Text` views — will scale automatically.
- **Expected outcome:** No code changes needed, but the audit must verify this.

### VoiceOver Navigation Order (Task 3)

- **Training Screen:** VoiceOver should navigate: toolbar buttons (Settings, Profile) → FeedbackIndicator (when visible) → Higher button → Lower button. The Higher/Lower buttons must announce their enabled/disabled state — SwiftUI handles this automatically via `.disabled()`.
- **Start Screen:** VoiceOver should navigate: Profile Preview → Start Training → toolbar buttons (Settings, Profile, Info). Navigation order follows the visual layout.
- **Profile Screen:** VoiceOver should navigate: profile visualization (announces aggregate summary) → summary statistics (mean, std dev, trend as individual items).
- **Settings Screen:** VoiceOver navigates `Form` controls in order — standard SwiftUI behavior.

### Eyes-Closed Training (Task 4)

The audio-haptic loop is already designed for eyes-closed operation:
- Haptic on incorrect answer: `HapticFeedbackManager` fires `UIImpactFeedbackGenerator(style: .heavy)` with double impact pattern (50ms apart) [Source: Peach/Training/HapticFeedbackManager.swift:38-47]
- No haptic on correct answer (silence = confirmation)
- Audio provides the training content (two notes)
- VoiceOver will announce "Correct"/"Incorrect" but this is supplementary — the haptic is the primary non-visual feedback channel

**Potential concern:** VoiceOver announcements of "Correct"/"Incorrect" may add delay to the loop. Need to verify this doesn't disrupt the training rhythm. If it does, consider using `.accessibilityLabel` without `.accessibilityLiveRegion` (which would suppress automatic announcements of the feedback indicator).

### Color Contrast (Task 5)

- All UI uses system semantic colors (`.primary`, `.secondary`, `.accent`)
- Feedback Indicator uses `.green` and `.red` system colors — these meet contrast requirements in both light and dark mode
- Profile visualization uses system `.blue`/`.tint` for band fill — meets contrast requirements
- **No code changes expected** — this task is pure verification

### Testing Approach (Tasks 6 & 7)

- **Swift Testing framework** (`@Test`, `#expect()`) — consistent with all existing tests
- **Reduce Motion test:** Create a test that verifies the animation value changes based on reduce motion. Note: environment values can be injected in SwiftUI previews and tests using `.environment(\.accessibilityReduceMotion, true)`, but for unit tests of the view's behavior, we may need to extract the animation logic into a testable function.
- **Accessibility label tests:** Follow the pattern from Story 7.1 — test the label computation functions directly rather than testing the SwiftUI view hierarchy.
- **Current test count:** 239 passing tests (per Story 7.1 code review). Maintain zero regressions.

### What NOT To Change

- **Do NOT add accessibility labels to PianoKeyboardView or ConfidenceBandView** — these are child components of ProfileScreen which provides the aggregate VoiceOver label. Adding per-key or per-data-point labels would overwhelm VoiceOver users with 128 MIDI notes worth of navigation items.
- **Do NOT add accessibility hints (`.accessibilityHint`)** unless VoiceOver audit reveals a clear usability gap — avoid accessibility theater per UX spec.
- **Do NOT add custom VoiceOver rotor actions** — the app's interaction is simple enough that standard VoiceOver navigation suffices.
- **Do NOT add sonification of the profile chart** — explicitly called out as "accessibility theater" in the UX spec.
- **Do NOT modify stock SwiftUI component accessibility** — standard components handle VoiceOver, Dynamic Type, and contrast correctly by default.
- **Do NOT change the `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` restriction on SummaryStatisticsView** — this is an appropriate ceiling to prevent layout overflow in the compact statistics display.

### Project Structure Notes

- Files to modify: `Peach/Training/TrainingScreen.swift` (add reduce motion environment check), `Peach/Training/FeedbackIndicator.swift` (update doc comment)
- Test files to modify/create: `PeachTests/Training/TrainingScreenAccessibilityTests.swift` (new — reduce motion + VoiceOver label tests), or add to existing `PeachTests/Training/TrainingSessionFeedbackTests.swift`
- No new Swift source files needed (beyond optional test file)
- No structural changes to the project

### References

- [Source: docs/planning-artifacts/epics.md#Story 7.2] — BDD acceptance criteria
- [Source: docs/planning-artifacts/prd.md#FR38] — "System provides basic accessibility support (labels, contrast, VoiceOver basics)"
- [Source: docs/planning-artifacts/prd.md#NFR6] — "All interactive controls labeled for VoiceOver"
- [Source: docs/planning-artifacts/prd.md#NFR7] — "Sufficient color contrast ratios for all text and UI elements"
- [Source: docs/planning-artifacts/prd.md#NFR8] — "Tap targets meet minimum size guidelines (44x44 points per Apple HIG)"
- [Source: docs/planning-artifacts/prd.md#NFR9] — "Feedback Indicator provides non-visual feedback (haptic) in addition to visual"
- [Source: docs/planning-artifacts/architecture.md#SwiftUI View Patterns] — "@Observable, thin views, SwiftUI environment for DI"
- [Source: docs/planning-artifacts/architecture.md#Technology Decisions] — "Swift Testing (@Test, #expect()) for all unit tests"
- [Source: docs/planning-artifacts/ux-design-specification.md#Accessibility Strategy] — Custom component labels, sensory hierarchy, implementation guidelines
- [Source: docs/planning-artifacts/ux-design-specification.md#Accessibility Implementation] — Full table of stock vs. custom accessibility needs
- [Source: Peach/Training/TrainingScreen.swift:58] — `.animation(.easeInOut(duration: 0.2))` — no reduce motion check
- [Source: Peach/Training/FeedbackIndicator.swift:8-11] — Doc comment claims reduce motion support
- [Source: Peach/Training/FeedbackIndicator.swift:27] — Correct/Incorrect accessibility label
- [Source: Peach/Profile/ProfileScreen.swift:42-43] — Profile visualization accessibility
- [Source: Peach/Start/ProfilePreviewView.swift:21-23] — Profile preview accessibility
- [Source: Peach/Profile/SummaryStatisticsView.swift:23-39] — Summary statistics accessibility
- [Source: Peach/Training/HapticFeedbackManager.swift:38-47] — Haptic feedback implementation
- [Source: Peach/Training/TrainingScreen.swift:14-51] — Higher/Lower button sizing (200pt minHeight, 80pt icons)

### Previous Story Learnings (7.1)

- **Localization pattern established:** All accessibility strings use `String(localized:)` for non-view-context strings. SwiftUI view literals use auto-extraction. Follow the same pattern for any new strings.
- **Ternary `.accessibilityLabel()` fix:** Story 7.1 code review found that ternary expressions in `.accessibilityLabel()` resolve to `String` type, calling the `StringProtocol` overload instead of `LocalizedStringKey`. Both FeedbackIndicator and SummaryStatisticsView were fixed to use `String(localized:)` wrappers. Any new accessibility labels must follow this pattern.
- **Test pattern:** Accessibility label tests should verify behavior (e.g., different output for different states) rather than comparing `String(localized:)` == `String(localized:)` (which is tautological). Story 7.1 replaced tautological tests with plural-verification tests.
- **Commit pattern:** story creation → implementation → code review fixes. Follow the same pattern.
- **239 tests pass** — maintain zero regressions.

### Git Intelligence

Recent commits (Story 7.1 completion):
- `ebb5873` — Code review fixes for Story 7.1: plural variants, chart translations, accessibility labels, tests
- `76b0b7a` — Implement story 7.1: English and German Localization
- `05e06c8` — Add story 7.1: English and German Localization

Pattern: story creation commit → implementation commit → code review fixes commit. Swift Testing framework (`@Test`, `#expect()`). All 239 tests currently pass.

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
