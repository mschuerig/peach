# Story 1.1: Create Xcode Project and Folder Structure

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want a properly configured Xcode project with the defined folder structure and test target,
so that all subsequent development has a consistent, organized foundation.

## Acceptance Criteria

1. **Given** no existing Xcode project, **When** the project is created, **Then** it uses Xcode 26.3 iOS App template with SwiftUI lifecycle, Swift language, and SwiftData storage
2. **Given** the project is created, **Then** the deployment target is iOS 26
3. **Given** the project is created, **Then** the folder structure matches the architecture document (App/, Core/Audio/, Core/Algorithm/, Core/Data/, Core/Profile/, Training/, Profile/, Settings/, Start/, Info/, Resources/)
4. **Given** the project is created, **Then** a PeachTests/ test target exists mirroring the source structure
5. **Given** the test target, **Then** Swift Testing framework is configured (@Test, #expect()) — not XCTest
6. **Given** the completed project, **Then** it builds and runs successfully on the simulator

## Tasks / Subtasks

- [ ] Task 1: Create Xcode project (AC: #1, #2)
  - [ ] Create new Xcode project: iOS → App → SwiftUI lifecycle, Swift language, SwiftData storage
  - [ ] Set deployment target to iOS 26
  - [ ] Verify explicit Swift modules are enabled (Xcode 26 default)
  - [ ] Verify zero third-party dependencies (SPM clean)
- [ ] Task 2: Establish folder structure (AC: #3)
  - [ ] Create App/ folder with PeachApp.swift and ContentView.swift
  - [ ] Create Core/Audio/ folder (empty — future NotePlayer.swift, SineWaveNotePlayer.swift)
  - [ ] Create Core/Algorithm/ folder (empty — future NextNoteStrategy.swift, AdaptiveNoteStrategy.swift)
  - [ ] Create Core/Data/ folder (empty — future ComparisonRecord.swift, TrainingDataStore.swift)
  - [ ] Create Core/Profile/ folder (empty — future PerceptualProfile.swift)
  - [ ] Create Training/ folder (empty — future TrainingSession.swift, TrainingScreen.swift)
  - [ ] Create Profile/ folder (empty — future ProfileScreen.swift)
  - [ ] Create Settings/ folder (empty — future SettingsScreen.swift)
  - [ ] Create Start/ folder (empty — future StartScreen.swift)
  - [ ] Create Info/ folder (empty — future InfoScreen.swift)
  - [ ] Create Resources/ folder with Assets.xcassets and Localizable.xcstrings (English + German)
  - [ ] Add placeholder .swift files or .gitkeep in empty folders so they're tracked in git
- [ ] Task 3: Configure test target (AC: #4, #5)
  - [ ] Create PeachTests/ target mirroring source structure
  - [ ] Create PeachTests/Core/Audio/ folder
  - [ ] Create PeachTests/Core/Algorithm/ folder
  - [ ] Create PeachTests/Core/Data/ folder
  - [ ] Create PeachTests/Core/Profile/ folder
  - [ ] Create PeachTests/Training/ folder
  - [ ] Configure Swift Testing framework (@Test, #expect()) — NOT XCTest
  - [ ] Add a placeholder test that passes to verify test target works
- [ ] Task 4: Configure PeachApp.swift entry point (AC: #1)
  - [ ] Set up @main entry point with SwiftUI App protocol
  - [ ] Initialize SwiftData ModelContainer (empty schema for now — ComparisonRecord comes in Story 1.2)
  - [ ] Set up basic ContentView as root
- [ ] Task 5: Verify build and run (AC: #6)
  - [ ] Build succeeds with zero warnings
  - [ ] App launches on simulator showing ContentView
  - [ ] Test target runs and placeholder test passes

## Dev Notes

### Technical Stack — Exact Versions

- **Xcode:** 26.3
- **Swift:** 6.2.3 (ships with Xcode 26.3)
- **iOS Deployment Target:** iOS 26 — no backward compatibility
- **Explicit Swift Modules:** Enabled (Xcode 26 default)
- **Dependencies:** Zero third-party (SPM clean for MVP)

### SwiftUI & SwiftData Configuration

- Use **SwiftUI lifecycle** (not UIKit AppDelegate)
- Use **@Observable** pattern (iOS 26) — NOT ObservableObject/@Published
- SwiftData **ModelContainer** initialized in PeachApp.swift, passed via SwiftUI environment
- SwiftData for persistence (ComparisonRecord @Model comes in Story 1.2)
- **@AppStorage** (UserDefaults) for settings (comes in Epic 6)

### Naming Conventions — MANDATORY

| Element | Convention | Examples |
|---|---|---|
| Types & Protocols | PascalCase | `TrainingSession`, `ComparisonRecord`, `NotePlayer` |
| Properties, Methods, Parameters | camelCase | `isCorrect`, `playNote(frequency:)` |
| Protocols | Noun describing capability | `NotePlayer`, `NextNoteStrategy` (NOT `NotePlayable`, `NoteStrategyProtocol`) |
| Protocol Implementations | Descriptive prefix | `SineWaveNotePlayer`, `AdaptiveNoteStrategy` |
| SwiftData Models | Singular noun | `ComparisonRecord` (NOT `ComparisonRecords`) |
| Files | Match primary type | `TrainingSession.swift`, `NotePlayer.swift` |
| Error Enums | Per-service typed enum | `AudioError: Error`, `DataStoreError: Error` |

### Architecture Pattern

- **Protocol-based service architecture** with dependency injection via SwiftUI environment
- **TrainingSession** is the integration point — depends on all Core services
- **Views are thin:** observe state, render, send actions — no business logic
- Extract subviews when view body exceeds ~40 lines
- Error enums are typed per-service: `AudioError`, `DataStoreError`, etc.

### Navigation Structure (Hub-and-Spoke)

- **Start Screen** is always the hub
- All secondary screens (Training, Profile, Settings) return to Start Screen
- **NavigationStack** for all navigation except Info Screen
- **Info Screen** presented via `.sheet()` modifier
- No tabs, no hamburger menus, no deep navigation

### Complete Folder Structure Reference

```
Peach/
├── App/
│   ├── PeachApp.swift                # @main entry, SwiftData container setup
│   └── ContentView.swift             # Root navigation (Start Screen as home)
├── Core/
│   ├── Audio/
│   │   ├── NotePlayer.swift              # Protocol (Epic 2)
│   │   └── SineWaveNotePlayer.swift      # Implementation (Epic 2)
│   ├── Algorithm/
│   │   ├── NextNoteStrategy.swift        # Protocol (Epic 4)
│   │   └── AdaptiveNoteStrategy.swift    # Implementation (Epic 4)
│   ├── Data/
│   │   ├── ComparisonRecord.swift        # SwiftData @Model (Story 1.2)
│   │   └── TrainingDataStore.swift       # CRUD operations (Story 1.2)
│   └── Profile/
│       └── PerceptualProfile.swift       # In-memory profile (Epic 4)
├── Training/
│   ├── TrainingSession.swift             # State machine (Epic 3)
│   └── TrainingScreen.swift              # UI (Epic 3)
├── Profile/
│   └── ProfileScreen.swift               # Visualization (Epic 5)
├── Settings/
│   └── SettingsScreen.swift              # Form (Epic 6)
├── Start/
│   └── StartScreen.swift                 # Hub screen (Epic 3)
├── Info/
│   └── InfoScreen.swift                  # Sheet (Epic 7)
└── Resources/
    ├── Localizable.xcstrings             # English + German
    └── Assets.xcassets

PeachTests/
├── Core/
│   ├── Audio/
│   │   └── SineWaveNotePlayerTests.swift
│   ├── Algorithm/
│   │   └── AdaptiveNoteStrategyTests.swift
│   ├── Data/
│   │   └── TrainingDataStoreTests.swift
│   └── Profile/
│       └── PerceptualProfileTests.swift
└── Training/
    └── TrainingSessionTests.swift
```

### What NOT To Do

- Do NOT use UIKit AppDelegate — SwiftUI lifecycle only
- Do NOT use ObservableObject/@Published — use @Observable (iOS 26)
- Do NOT add any third-party dependencies
- Do NOT create custom UI styles or appearance overrides — stock SwiftUI + Liquid Glass
- Do NOT use XCTest for unit tests — use Swift Testing (@Test, #expect())
- Do NOT create files for future stories — just the folders with placeholders
- Do NOT add business logic to PeachApp.swift — it only initializes ModelContainer and sets up root view

### Project Structure Notes

- Organization is **by feature**, not by layer
- Core/ contains shared cross-feature services
- Each screen feature (Training, Profile, Settings, Start, Info) gets its own top-level folder
- Test target mirrors source structure exactly
- Resources/ holds localization (String Catalogs) and assets

### References

- [Source: docs/planning-artifacts/architecture.md#Project Directory Structure]
- [Source: docs/planning-artifacts/architecture.md#Technical Stack]
- [Source: docs/planning-artifacts/architecture.md#Naming Conventions]
- [Source: docs/planning-artifacts/architecture.md#Testing Strategy]
- [Source: docs/planning-artifacts/architecture.md#SwiftData]
- [Source: docs/planning-artifacts/epics.md#Story 1.1]
- [Source: docs/planning-artifacts/prd.md#Technical Requirements]
- [Source: docs/planning-artifacts/ux-design-specification.md#Navigation Model]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
