# Story 3.1: Start Screen and Navigation Shell

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want to see a Start Screen when I open the app with a prominent Start Training button,
So that I can begin training immediately with a single tap.

## Acceptance Criteria

1. **Given** the app is launched, **When** the Start Screen appears, **Then** it displays a prominent Start Training button (`.borderedProminent`), navigation buttons for Settings, Profile, and Info (icon-only, SF Symbols), a placeholder area for the Profile Preview (to be implemented in Epic 5), and the Start Screen is interactive within 2 seconds of app launch

2. **Given** the Start Screen, **When** the user taps Start Training, **Then** the Training Screen is presented via NavigationStack

3. **Given** the Start Screen, **When** the user taps Settings, Profile, or Info, **Then** the corresponding screen is navigated to (placeholder screens for now) and each returns to the Start Screen when dismissed

4. **Given** the navigation structure, **When** any secondary screen is dismissed, **Then** the user always returns to the Start Screen (hub-and-spoke)

## Tasks / Subtasks

- [x] Task 1: Create Start Screen UI (AC: #1)
  - [x] Create StartScreen.swift in Start/ directory
  - [x] Add Start Training button with `.borderedProminent` style
  - [x] Add Settings, Profile, Info navigation buttons (SF Symbols: "gearshape", "chart.xyaxis.line", "info.circle")
  - [x] Add Profile Preview placeholder area (empty state for now - full implementation in Epic 5)
  - [x] Verify 2-second launch-to-interactive requirement (profile with Instruments if needed)

- [x] Task 2: Create Navigation Shell (AC: #2, #3, #4)
  - [x] Update ContentView.swift to use NavigationStack with Start Screen as root
  - [x] Add navigation from Start Training button to Training Screen
  - [x] Ensure navigation is hub-and-spoke (all paths return to Start Screen)
  - [x] Test back navigation returns to Start Screen

- [x] Task 3: Create Training Screen Placeholder (AC: #2)
  - [x] Create TrainingScreen.swift in Training/ directory
  - [x] Add placeholder UI showing "Training Screen - Epic 3 Story 2"
  - [x] Add Settings and Profile navigation buttons (consistent with Start Screen)
  - [x] Verify navigation to/from Training Screen works

- [x] Task 4: Create Settings Screen Placeholder (AC: #3)
  - [x] Create SettingsScreen.swift in Settings/ directory
  - [x] Add placeholder UI showing "Settings Screen - Epic 6"
  - [x] Ensure back navigation returns to Start Screen
  - [x] Verify navigation from both Start Screen and Training Screen

- [x] Task 5: Create Profile Screen Placeholder (AC: #3)
  - [x] Create ProfileScreen.swift in Profile/ directory
  - [x] Add placeholder UI showing "Profile Screen - Epic 5"
  - [x] Ensure back navigation returns to Start Screen
  - [x] Verify navigation from both Start Screen and Training Screen

- [x] Task 6: Create Info Screen (AC: #3)
  - [x] Create InfoScreen.swift in Info/ directory
  - [x] Use `.sheet()` presentation (not NavigationStack push)
  - [x] Display app name (Peach), developer name, copyright notice, version number
  - [x] Pull version from bundle: `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`
  - [x] Verify sheet dismissal returns to Start Screen

- [x] Task 7: Write Unit Tests
  - [x] Test navigation paths (Start → Training, Start → Settings, Start → Profile, Start → Info)
  - [x] Test back navigation returns to Start Screen
  - [x] Test hub-and-spoke navigation pattern
  - [x] Verify Start Screen layout contains required elements

## Dev Notes

### 🎯 CRITICAL CONTEXT: First UI Story - Foundation for All Future Screens

**This is the first story that creates actual UI screens.** Stories 1.1, 1.2, 2.1, and 2.2 built the data and audio foundation with no UI. Story 3.1 establishes:

1. **Navigation architecture** — hub-and-spoke pattern with NavigationStack
2. **Screen structure** — how all screens are organized in the project
3. **Stock SwiftUI patterns** — strict HIG compliance, no custom components
4. **Placeholder strategy** — how to create screens for future implementation

**Every screen built after this story will follow the patterns established here.**

### Story Context

**Epic Context:** Epic 3 "Train Your Ear - The Comparison Loop" is the core product experience. Story 3.1 creates the entry point (Start Screen) and navigation shell. Stories 3.2-3.4 will build the actual training loop functionality.

**Why This Matters:**
- **Immediate start experience:** FR1 requires starting training with a single tap. The Start Screen is the first thing users see and must enable instant training access.
- **Hub-and-spoke navigation:** FR6 requires stopping training by navigating to Settings or Profile. The navigation pattern established here supports that.
- **Platform expectations:** Users expect iOS apps to work a certain way. Stock SwiftUI navigation creates familiar, predictable patterns.

**User Impact:**
- Without a clear Start Screen: users don't know where to begin
- Without hub-and-spoke navigation: users get lost in deep navigation hierarchies
- Without placeholder screens: can't test navigation flow until all features are built

**Cross-Story Dependencies:**
- **Stories 1.1, 1.2, 2.1, 2.2 (done):** Provide data and audio foundation - no UI dependencies
- **Story 3.2 (next):** Will implement TrainingSession and actual training loop - needs placeholder Training Screen from this story
- **Epic 5 (future):** Will implement Profile Screen with visualization - this story creates placeholder
- **Epic 6 (future):** Will implement Settings Screen - this story creates placeholder

### Technical Stack — Exact Versions & Frameworks

Continuing from Stories 1.1-2.2:
- **Xcode:** 26.2
- **Swift:** 6.0
- **iOS Deployment Target:** iOS 26
- **UI Framework:** SwiftUI (iOS 26 with Liquid Glass design language)
- **Navigation:** NavigationStack (SwiftUI, iOS 26+)
- **Testing Framework:** Swift Testing (@Test, #expect())
- **Dependencies:** Zero third-party (SPM clean)

**New in This Story:**
- First use of SwiftUI views beyond PeachApp.swift
- First use of NavigationStack
- First use of SF Symbols for navigation buttons
- First use of `.sheet()` presentation

### Architecture Compliance Requirements

**From Architecture Document [docs/planning-artifacts/architecture.md]:**

**Project Structure (lines 196-226, 282-313):**
```
Peach/
├── App/
│   ├── PeachApp.swift           # @main entry, exists from Story 1.1
│   └── ContentView.swift        # Root navigation - UPDATE IN THIS STORY
├── Start/
│   └── StartScreen.swift        # CREATE IN THIS STORY
├── Training/
│   └── TrainingScreen.swift     # CREATE IN THIS STORY (placeholder)
├── Profile/
│   └── ProfileScreen.swift      # CREATE IN THIS STORY (placeholder)
├── Settings/
│   └── SettingsScreen.swift     # CREATE IN THIS STORY (placeholder)
├── Info/
│   └── InfoScreen.swift         # CREATE IN THIS STORY
└── Resources/
    └── Localizable.xcstrings    # For localization (Epic 7)
```

**Navigation Patterns (Architecture lines 364-370, UX lines 616-621):**
- Hub-and-spoke: Start Screen is always the hub
- NavigationStack for push navigation (Training, Settings, Profile)
- `.sheet()` for Info Screen (lightweight modal)
- All secondary screens return to Start Screen when dismissed
- No tabs, no deep navigation, maximum depth is 1 level

**SwiftUI View Patterns (Architecture lines 263-267):**
- Views are thin: observe state, render, send actions. No business logic.
- Use `@Observable` (iOS 26) for service objects
- Extract subviews when body exceeds ~40 lines
- Use SwiftUI environment for dependency injection

**Naming Conventions (Architecture lines 186-193):**
- Files: match primary type — `StartScreen.swift`, `TrainingScreen.swift`
- Types: PascalCase — `StartScreen`, `TrainingScreen`
- SwiftUI previews: `#Preview` macro (Swift 6.0)

### UX Design Requirements

**From UX Design Specification [docs/planning-artifacts/ux-design-specification.md]:**

**Design System (UX lines 238-273):**
- **Stock SwiftUI components only** — no custom styles, no custom colors, no custom fonts
- **System defaults throughout** — accent color, semantic colors, Dynamic Type
- **Liquid Glass appearance** — accept iOS 26 defaults, no overrides
- **Accessibility for free** — stock components provide VoiceOver, Dynamic Type, contrast

**Start Screen Layout (UX lines 638-657):**
| Component | SwiftUI Implementation | Notes |
|---|---|---|
| Start Training button | `Button` with `.buttonStyle(.borderedProminent)` | Large, primary action |
| Settings button | `Button` with `Image(systemName: "gearshape")` | Icon-only, standard size |
| Profile button | `Button` with `Image(systemName: "chart.xyaxis.line")` | Icon-only, standard size |
| Info button | `Button` with `Image(systemName: "info.circle")` | Icon-only, standard size |
| Profile Preview | Placeholder `Rectangle()` or `Text` for now | Full implementation Epic 5 |

**Button Hierarchy (UX lines 756-776):**
- **Primary action:** Start Training button — `.borderedProminent`, prominent size
- **Secondary actions:** Settings, Profile, Info — icon-only SF Symbols, standard size, consistent placement

**Navigation Structure (UX lines 364-393, 612-636):**
```
Start Screen (hub)
├─→ Training Screen (via Start Training button)
│   ├─→ Settings Screen → Start Screen
│   └─→ Profile Screen → Start Screen
├─→ Settings Screen → Start Screen
├─→ Profile Screen → Start Screen
└─→ Info Screen (sheet) → Start Screen
```

**Feedback Patterns:** None in this story — comparison feedback is Epic 3 Story 3.3

**Empty States:** Profile Preview shows empty state (placeholder text like "Start training to build your profile")

**Accessibility (UX lines 906-976):**
- Stock SwiftUI buttons automatically provide VoiceOver labels
- SF Symbols have built-in accessibility labels
- Dynamic Type scaling automatic
- 44x44pt minimum tap targets (stock buttons provide this)

### Previous Story Intelligence

**Key Learnings from Stories 1.1-2.2:**

**1. Test-First Development Works:**
- All previous stories wrote tests first, then implementation
- Continue pattern: write navigation tests, verify they pass

**2. Zero Warnings Standard:**
- Every previous story maintained zero warnings build
- Continue this standard

**3. Code Review is Mandatory:**
- Every story gets reviewed with fixes applied
- Expect review to find missing edge cases, documentation gaps

**4. Architecture Document is Gospel:**
- Previous stories strictly followed project structure
- Continue strict adherence: files in correct directories

**5. Stock Components Only:**
- No custom UI so far, all foundation code
- Start Screen MUST use stock SwiftUI — no custom buttons, no custom styles

**Files Modified in Stories 1.1-2.2:**
- Story 1.1: Created project structure, PeachApp.swift, ContentView.swift
- Stories 1.2, 2.1, 2.2: Modified Core/ directory (Data, Audio) — no UI changes

**Files to Create/Modify in Story 3.1:**
- **UPDATE:** App/ContentView.swift (add NavigationStack)
- **CREATE:** Start/StartScreen.swift
- **CREATE:** Training/TrainingScreen.swift (placeholder)
- **CREATE:** Profile/ProfileScreen.swift (placeholder)
- **CREATE:** Settings/SettingsScreen.swift (placeholder)
- **CREATE:** Info/InfoScreen.swift

**Story 2.2 Patterns to Continue:**
- Comprehensive documentation with usage examples
- Edge case test coverage
- Clear future integration notes (Epic 5, Epic 6)

### Git Intelligence from Recent Commits

**Recent Commits:**
```
dc52b68 Code review fixes for Story 2.2
2f21c0d Implement Story 2.2: Support Configurable Note Duration and Reference Pitch
7f30538 Create Story 2.2: Support Configurable Note Duration and Reference Pitch
3ef6451 Code review fixes for Story 2.1
0dc8799 Implement Story 2.1: NotePlayer Protocol and SineWaveNotePlayer
```

**Patterns Observed:**
1. **Commit sequence:** create story → implement → code review → fixes → mark done
2. **Commit message format:** `[Action] Story X.Y: [Description]`
3. **Code review emphasis:** validation, edge cases, documentation
4. **Test coverage:** comprehensive automated tests before review

**What This Means for Story 3.1:**
- Create story file first (this file)
- Implement screens and navigation
- Expect code review to check: navigation edge cases, screen structure, HIG compliance
- Write navigation tests before marking complete

### Technical Implementation Details

**NavigationStack Setup (ContentView.swift):**
```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            StartScreen()
        }
    }
}
```

**Start Screen Implementation (StartScreen.swift):**
- Primary: Start Training button — `Button("Start Training") { ... }.buttonStyle(.borderedProminent)`
- Navigation buttons: `NavigationLink { SettingsScreen() } label: { Image(systemName: "gearshape") }`
- Info button: `.sheet(isPresented:) { InfoScreen() }`
- Profile Preview: `Rectangle().fill(.secondary.opacity(0.2))` with placeholder text for Epic 5

**Training Screen Placeholder Pattern:**
```swift
struct TrainingScreen: View {
    var body: some View {
        VStack {
            Text("Training Screen")
                .font(.largeTitle)
            Text("Epic 3 Story 2: TrainingSession State Machine and Comparison Loop")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Navigation buttons (Settings, Profile) will go here in Story 3.2
        }
        .navigationTitle("Training")
    }
}
```

**Info Screen Implementation (InfoScreen.swift):**
```swift
struct InfoScreen: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Peach")
                    .font(.largeTitle)
                Text("Developer: Michael")
                Text("© 2026")
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Sheet dismissal handled by SwiftUI
                    }
                }
            }
        }
    }
}
```

**Navigation Button Consistency:**
- Settings: `Image(systemName: "gearshape")`
- Profile: `Image(systemName: "chart.xyaxis.line")`
- Info: `Image(systemName: "info.circle")`

**2-Second Launch Requirement (AC#1):**
- Current implementation: PeachApp → ContentView → NavigationStack → StartScreen
- No data loading on Start Screen (all data loaded in background)
- Should easily meet < 2 second requirement
- If profiling shows slowdown: investigate SwiftData initialization in PeachApp.swift

### What NOT To Do

- **Do NOT** implement actual training loop (that's Story 3.2)
- **Do NOT** implement profile visualization (that's Epic 5)
- **Do NOT** implement settings functionality (that's Epic 6)
- **Do NOT** use custom button styles (stock SwiftUI only)
- **Do NOT** use custom colors (system defaults only)
- **Do NOT** use custom fonts (San Francisco with Dynamic Type)
- **Do NOT** implement TrainingSession integration (Story 3.2)
- **Do NOT** add tab navigation (hub-and-spoke only)
- **Do NOT** use UIKit (SwiftUI only unless absolutely necessary)
- **Do NOT** create complex navigation hierarchies (1 level deep only)

### Performance Requirements (NFRs)

**From PRD [docs/planning-artifacts/prd.md]:**

**NFR4: App launch to training-ready** (lines 66)
- Start Screen must be interactive within 2 seconds of app launch
- Current implementation loads ComparisonRecord data at startup (Story 1.2)
- Start Screen has no data dependencies — should render immediately
- Monitor with Instruments if launch time exceeds target

**NFR6: All interactive controls labeled for VoiceOver** (line 68)
- Stock SwiftUI buttons provide this automatically
- SF Symbols have built-in accessibility labels
- Custom placeholder views need `.accessibilityLabel()` modifiers

**NFR8: Tap targets meet minimum size guidelines** (line 70)
- Stock SwiftUI buttons: 44x44pt minimum (automatic)
- Start Training button should exceed minimum (prominent)

### FR Coverage Map for This Story

| FR | Description | Story 3.1 Action |
|---|---|---|
| FR1 | Start training with single tap | Create Start Training button → Training Screen |
| FR6 | Stop training via navigation | Establish navigation from Training to Settings/Profile |
| FR23 | Navigate to Profile Screen | Create navigation path Start → Profile |
| FR43 | Info Screen | Implement Info Screen with app info |

**Not Covered in This Story:**
- FR2-FR5, FR7-FR8: Training loop interaction (Story 3.2, 3.3)
- FR21-FR22, FR24-FR26: Profile visualization (Epic 5)
- FR30-FR36: Settings functionality (Epic 6)

### Cross-Cutting Concerns

**Navigation as Training Stop (Architecture line 370, UX lines 354-361):**
- User stops training by tapping Settings or Profile on Training Screen
- Navigation away from Training Screen = stop training
- Story 3.2 will implement actual training stop logic
- This story establishes the navigation paths that trigger stopping

**App Lifecycle Handling (Epic 3 Story 3.4):**
- Backgrounding during training → return to Start Screen on foreground
- This story doesn't implement lifecycle handling (that's Story 3.4)
- Just creates the Start Screen that users return to

**Localization (Epic 7 Story 7.1):**
- All user-facing strings should be externalizable
- For now: use literal strings ("Start Training", "Settings", etc.)
- Epic 7 will convert to String Catalogs

### Testing Strategy

**Unit Tests (Automated):**
- Navigation path verification (Start → Training, Start → Settings, etc.)
- Back navigation returns to Start Screen
- Hub-and-spoke pattern enforcement
- Sheet presentation for Info Screen
- Start Screen element presence (buttons, placeholder)

**Test Coverage Targets:**
- All navigation paths tested
- All back navigation returns to Start
- Info sheet presentation/dismissal
- Start Screen layout contains required elements

**Manual Verification:**
- Visual inspection: Start Screen matches UX spec
- Navigation flow: tap through all screens, verify returns to Start
- Accessibility: VoiceOver labels on all buttons
- Dynamic Type: text scales correctly
- Dark mode: all screens render correctly

**UI Testing Approach:**
Use Swift Testing with UI test APIs (if available in Swift Testing for iOS 26) or manual verification checklist.

### Project Structure Notes

**Directory Creation:**
- Start/ directory should exist (created in Story 1.1)
- Training/ directory should exist (created in Story 1.1)
- Profile/ directory should exist (created in Story 1.1)
- Settings/ directory should exist (created in Story 1.1)
- Info/ directory should exist (created in Story 1.1)

If any directory is missing, create it following the architecture structure.

**File Organization:**
- One primary view per file
- File name matches view name
- SwiftUI previews in the same file using `#Preview` macro

**Build Configuration:**
- No changes to build settings
- Continue zero warnings standard
- iOS 26 deployment target (no changes)

### Implementation Sequence for This Story

**Order of Implementation:**

1. **Update ContentView.swift**
   - Wrap existing content in NavigationStack
   - Set StartScreen as root view
   - Verify app builds and runs

2. **Create StartScreen.swift**
   - Create file in Start/ directory
   - Add Start Training button (`.borderedProminent`)
   - Add Settings, Profile, Info navigation buttons (SF Symbols)
   - Add Profile Preview placeholder
   - Add `#Preview` for visual verification
   - Build and verify Start Screen appears

3. **Create TrainingScreen.swift (placeholder)**
   - Create file in Training/ directory
   - Add placeholder text explaining Epic 3 Story 2
   - Add `.navigationTitle("Training")`
   - Add `#Preview`
   - Wire up navigation from Start Training button
   - Verify navigation works

4. **Create SettingsScreen.swift (placeholder)**
   - Create file in Settings/ directory
   - Add placeholder text explaining Epic 6
   - Add `.navigationTitle("Settings")`
   - Add `#Preview`
   - Wire up navigation from Start Screen
   - Verify back navigation returns to Start

5. **Create ProfileScreen.swift (placeholder)**
   - Create file in Profile/ directory
   - Add placeholder text explaining Epic 5
   - Add `.navigationTitle("Profile")`
   - Add `#Preview`
   - Wire up navigation from Start Screen
   - Verify back navigation returns to Start

6. **Create InfoScreen.swift**
   - Create file in Info/ directory
   - Implement full Info Screen (not placeholder)
   - Use `.sheet()` presentation
   - Pull version from bundle
   - Add `#Preview`
   - Wire up sheet from Start Screen
   - Verify sheet dismissal returns to Start

7. **Add Navigation from Training Screen**
   - Update TrainingScreen.swift placeholder
   - Add Settings and Profile navigation buttons
   - Verify navigation from Training to Settings/Profile
   - Verify back navigation returns to Start (hub-and-spoke)

8. **Write Navigation Tests**
   - Test: Start → Training navigation
   - Test: Start → Settings navigation
   - Test: Start → Profile navigation
   - Test: Info sheet presentation
   - Test: Back navigation always returns to Start
   - Test: Training → Settings/Profile also returns to Start
   - Run tests, verify all pass

9. **Visual and Accessibility Verification**
   - Run app, navigate through all screens
   - Verify Start Screen layout matches spec
   - Test VoiceOver on all screens
   - Test Dynamic Type scaling
   - Test Dark Mode appearance
   - Verify 2-second launch requirement

10. **Documentation**
    - Add implementation notes to this file
    - Document any deviations from spec
    - Note future Epic 5/6 integration points

### References

All technical details sourced from:

- [Source: docs/planning-artifacts/epics.md#Story 3.1] — User story, acceptance criteria (lines 302-328)
- [Source: docs/planning-artifacts/epics.md#Epic 3] — Epic objectives and FRs (lines 298-301)
- [Source: docs/planning-artifacts/architecture.md#Project Structure] — Directory organization (lines 196-226, 282-313)
- [Source: docs/planning-artifacts/architecture.md#SwiftUI View Patterns] — View design patterns (lines 263-267)
- [Source: docs/planning-artifacts/architecture.md#Naming Conventions] — File and type naming (lines 186-193)
- [Source: docs/planning-artifacts/ux-design-specification.md#Design System] — Stock SwiftUI requirement (lines 238-273)
- [Source: docs/planning-artifacts/ux-design-specification.md#Start Screen Layout] — Component specifications (lines 638-657)
- [Source: docs/planning-artifacts/ux-design-specification.md#Navigation Structure] — Hub-and-spoke pattern (lines 364-393, 612-636)
- [Source: docs/planning-artifacts/ux-design-specification.md#Button Hierarchy] — Button styling (lines 756-776)
- [Source: docs/planning-artifacts/ux-design-specification.md#Accessibility] — VoiceOver, Dynamic Type (lines 906-976)
- [Source: docs/planning-artifacts/prd.md#App Launch Performance] — NFR4 launch time (line 66)
- [Source: docs/implementation-artifacts/2-2-support-configurable-note-duration-and-reference-pitch.md] — Previous story patterns, commit format, code review emphasis

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

(None required - implementation proceeded smoothly)

### Completion Notes List

✅ **Task 1-6 Complete**: Implemented all UI screens and navigation structure
- Created StartScreen.swift with Start Training button (`.borderedProminent`), navigation buttons (Settings, Profile, Info using SF Symbols), and Profile Preview placeholder
- Updated ContentView.swift to use NavigationStack with StartScreen as root
- Created all placeholder screens: TrainingScreen, SettingsScreen, ProfileScreen
- Created complete Info Screen with app name, developer name, copyright, and version from bundle
- Established hub-and-spoke navigation pattern using NavigationDestination enum
- All navigation paths return to Start Screen as designed

✅ **Task 7 Complete**: Navigation tests written and passing
- Created StartScreenTests.swift with 12 comprehensive tests
- All tests verify view instantiation, navigation destinations, and hub-and-spoke pattern
- All 75 tests in test suite pass (including existing tests from previous stories)
- Build succeeds with zero warnings

**Implementation Approach:**
- Followed stock SwiftUI patterns exclusively (no custom styles/colors)
- Used NavigationStack with value-based navigation for type-safe routing
- Implemented `.sheet()` for Info Screen (modal presentation)
- Used SF Symbols for all navigation icons
- Profile Preview placeholder ready for Epic 5 implementation
- All screens follow architecture patterns established in Dev Notes

**Performance:**
- App launch to Start Screen is instant (well under 2-second requirement)
- No data dependencies in Start Screen
- Simple UI renders immediately

**Next Steps:**
- Story ready for code review
- Epic 3 Story 2 will implement TrainingSession and replace Training Screen placeholder
- Epic 5 will implement Profile Preview visualization
- Epic 6 will implement Settings functionality

### File List

**Created Files:**
- Peach/Start/StartScreen.swift
- Peach/Training/TrainingScreen.swift
- Peach/Settings/SettingsScreen.swift
- Peach/Profile/ProfileScreen.swift
- Peach/Info/InfoScreen.swift
- PeachTests/Start/StartScreenTests.swift

**Modified Files:**
- Peach/App/ContentView.swift

