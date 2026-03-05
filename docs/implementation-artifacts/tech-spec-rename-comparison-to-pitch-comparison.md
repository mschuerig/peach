---
title: 'Rename Comparison to PitchComparison'
slug: 'rename-comparison-to-pitch-comparison'
created: '2026-03-05'
status: 'completed'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['Swift 6.2', 'SwiftUI', 'SwiftData', 'Swift Testing']
files_to_modify:
  # Source files to rename
  - 'Peach/Core/Training/Comparison.swift'
  - 'Peach/Core/Training/ComparisonObserver.swift'
  - 'Peach/Core/Profile/PitchDiscriminationProfile.swift'
  - 'Peach/Core/Algorithm/NextComparisonStrategy.swift'
  - 'Peach/Core/Data/ComparisonRecord.swift'
  - 'Peach/Core/Data/ComparisonRecordStoring.swift'
  - 'Peach/Comparison/ComparisonSession.swift'
  - 'Peach/Comparison/ComparisonScreen.swift'
  - 'Peach/Comparison/ComparisonFeedbackIndicator.swift'
  - 'Peach/Comparison/HapticFeedbackManager.swift'
  # Source files to update (content only)
  - 'Peach/App/PeachApp.swift'
  - 'Peach/App/EnvironmentKeys.swift'
  - 'Peach/App/NavigationDestination.swift'
  - 'Peach/App/TrainingStatsView.swift'
  - 'Peach/App/ContentView.swift'
  - 'Peach/Start/StartScreen.swift'
  - 'Peach/Core/Data/TrainingDataStore.swift'
  - 'Peach/Core/Data/TrainingDataImporter.swift'
  - 'Peach/Core/Data/TrainingDataExporter.swift'
  - 'Peach/Core/Data/TrainingDataTransferService.swift'
  - 'Peach/Core/Data/CSVImportParser.swift'
  - 'Peach/Core/Data/CSVRecordFormatter.swift'
  - 'Peach/Core/Data/CSVExportSchema.swift'
  - 'Peach/Core/Profile/PerceptualProfile.swift'
  - 'Peach/Core/Profile/ProgressTimeline.swift'
  - 'Peach/Core/Algorithm/KazezNoteStrategy.swift'
  - 'Peach/Profile/ProfileScreen.swift'
  # Test files to rename
  - 'PeachTests/Core/Training/ComparisonTests.swift'
  - 'PeachTests/Comparison/ (all 20 files)'
  - 'PeachTests/Profile/MockPitchDiscriminationProfile.swift'
  - 'PeachTests/Core/Profile/PitchDiscriminationProfileTests.swift'
  # Test files to update (content only)
  - 'PeachTests/Core/Training/ResettableTests.swift'
  - 'PeachTests/Core/TrainingSessionTests.swift'
  - 'PeachTests/Core/Profile/ProgressTimelineTests.swift'
  - 'PeachTests/Core/Profile/PitchMatchingProfileTests.swift'
  - 'PeachTests/Core/Data/TrainingDataStoreTests.swift'
  - 'PeachTests/Core/Data/CSVImportParserTests.swift'
  - 'PeachTests/Core/Data/CSVExportSchemaTests.swift'
  - 'PeachTests/Settings/TrainingDataImportActionTests.swift'
  - 'PeachTests/Start/StartScreenTests.swift'
  # Active docs to update
  - 'docs/project-context.md'
  - 'docs/README.md'
  - 'docs/planning-artifacts/architecture.md'
  - 'docs/planning-artifacts/glossary.md'
  - 'docs/planning-artifacts/epics.md'
  - 'docs/planning-artifacts/prd.md'
  - 'docs/planning-artifacts/ux-design-specification.md'
  - 'docs/arc42/02-constraints.md'
  - 'docs/arc42/03-context-and-scope.md'
  - 'docs/arc42/04-solution-strategy.md'
  - 'docs/arc42/05-building-block-view.md'
  - 'docs/arc42/06-runtime-view.md'
  - 'docs/arc42/07-deployment-view.md'
  - 'docs/arc42/08-crosscutting-concepts.md'
  - 'docs/arc42/09-architecture-decisions.md'
  - 'docs/arc42/10-quality-requirements.md'
  - 'docs/arc42/12-glossary.md'
  - 'docs/arc42/index.md'
  - 'docs/implementation-artifacts/sprint-status.yaml'
code_patterns:
  - 'Pitch{Mode}{Component} naming convention'
  - 'Protocol-first design: protocol -> conformance -> tests'
  - '@Entry environment keys in App/EnvironmentKeys.swift'
  - 'Composition root in PeachApp.swift'
test_patterns:
  - 'Swift Testing: @Test, @Suite, #expect()'
  - 'Struct-based test suites with factory methods'
  - 'waitForState helper for async state transitions'
---

# Tech-Spec: Rename Comparison to PitchComparison

**Created:** 2026-03-05

## Overview

### Problem Statement

The codebase uses two different terms for the same concept: "Comparison" (in sessions, records, observers, strategies) and "Discrimination" (in the profile protocol). Meanwhile, the sibling training mode consistently uses the "PitchMatching" prefix across all its types. This inconsistency creates cognitive friction and naming asymmetry between the two training mode families.

### Solution

Unify all Comparison-family types under a `PitchComparison*` prefix, and rename `PitchDiscriminationProfile` to `PitchComparisonProfile`. This achieves full naming symmetry with the `PitchMatching*` family:

| Layer | Pitch Comparison | Pitch Matching |
|-------|-----------------|----------------|
| Session | `PitchComparisonSession` | `PitchMatchingSession` |
| State | `PitchComparisonSessionState` | `PitchMatchingSessionState` |
| Record | `PitchComparisonRecord` | `PitchMatchingRecord` |
| Profile | `PitchComparisonProfile` | `PitchMatchingProfile` |
| Observer | `PitchComparisonObserver` | `PitchMatchingObserver` |
| Strategy | `NextPitchComparisonStrategy` | (none) |
| Value Object | `PitchComparison` | (none) |
| Completed | `CompletedPitchComparison` | `CompletedPitchMatching` |
| Record Storing | `PitchComparisonRecordStoring` | `PitchMatchingRecordStoring` |

### Scope

**In Scope:**
- All `Comparison*` type renames to `PitchComparison*` (types, files, directories, mocks, tests)
- `PitchDiscriminationProfile` to `PitchComparisonProfile`
- Protocol method renames (e.g., `comparisonCompleted` -> `pitchComparisonCompleted`)
- Property/variable renames (e.g., `currentComparison` -> `currentPitchComparison`)
- Enum case renames (e.g., `.comparison` -> `.pitchComparison`)
- Environment key rename (`comparisonSession` -> `pitchComparisonSession`)
- Directory renames (`Peach/Comparison/` -> `Peach/PitchComparison/`, `PeachTests/Comparison/` -> `PeachTests/PitchComparison/`)
- Active docs update (19 doc files)
- Localization strings in `.xcstrings` if applicable
- SwiftData model rename (no migration; data wipe acceptable)

**Out of Scope:**
- Historical docs (claude-audit, completed story files, brainstorming sessions, research docs, validation reports, implementation-readiness reports)
- SwiftData migration strategy (fresh install acceptable)
- Schema versioning for stored data (separate future spec)

## Context for Development

### Codebase Patterns

- **Naming convention**: `Pitch{Mode}{Component}` pattern (already established by PitchMatching family)
- **Protocol-first design**: Rename protocol, then update all conformances and call sites
- **`@Entry` environment keys** in `App/EnvironmentKeys.swift` reference session/profile types by name
- **Composition root** in `PeachApp.swift` wires all services
- **SwiftData `@Model`**: `ComparisonRecord` -> `PitchComparisonRecord` -- stored class name changes, incompatible with existing store
- **Observer pattern**: `ComparisonObserver` protocol with `comparisonCompleted(_:)` -- method name must rename too
- **Strategy pattern**: `NextComparisonStrategy` protocol with `nextComparison(...)` method
- **CSV export/import**: `CSVExportSchema.TrainingType.comparison` enum case and column names
- **TrainingMode enum**: `ProgressTimeline.swift` has `.unisonComparison` and `.intervalComparison` cases
- **NavigationDestination**: `.comparison(intervals:)` enum case for type-safe routing
- **Test helpers**: `ComparisonTestHelpers.swift` with `makeComparisonSession()` factory and `ComparisonSessionFixture` type

### Rename Reference Table

All identifier renames in one place. Every task below references this table.

**Type names:**

| Current | New |
|---------|-----|
| `Comparison` | `PitchComparison` |
| `CompletedComparison` | `CompletedPitchComparison` |
| `ComparisonObserver` | `PitchComparisonObserver` |
| `ComparisonSession` | `PitchComparisonSession` |
| `ComparisonSessionState` | `PitchComparisonSessionState` |
| `ComparisonScreen` | `PitchComparisonScreen` |
| `ComparisonFeedbackIndicator` | `PitchComparisonFeedbackIndicator` |
| `ComparisonRecord` | `PitchComparisonRecord` |
| `ComparisonRecordStoring` | `PitchComparisonRecordStoring` |
| `NextComparisonStrategy` | `NextPitchComparisonStrategy` |
| `PitchDiscriminationProfile` | `PitchComparisonProfile` |

**Protocol methods:**

| Current | New |
|---------|-----|
| `comparisonCompleted(_:)` | `pitchComparisonCompleted(_:)` |
| `nextComparison(profile:settings:lastComparison:interval:)` | `nextPitchComparison(profile:settings:lastPitchComparison:interval:)` |
| `fetchAllComparisons()` | `fetchAllPitchComparisons()` |

**Properties and local variables:**

| Current | New |
|---------|-----|
| `currentComparison` | `currentPitchComparison` |
| `lastCompletedComparison` | `lastCompletedPitchComparison` |
| `comparisonSession` | `pitchComparisonSession` |
| `lastComparison` (parameter) | `lastPitchComparison` |

**Enum cases:**

| Current | New |
|---------|-----|
| `.comparison` (NavigationDestination) | `.pitchComparison` |
| `.comparison` (CSVExportSchema.TrainingType) | `.pitchComparison` |
| `.unisonComparison` (TrainingMode) | `.unisonPitchComparison` |
| `.intervalComparison` (TrainingMode) | `.intervalPitchComparison` |

**Directories:**

| Current | New |
|---------|-----|
| `Peach/Comparison/` | `Peach/PitchComparison/` |
| `PeachTests/Comparison/` | `PeachTests/PitchComparison/` |

**Files (source):**

| Current | New |
|---------|-----|
| `Core/Training/Comparison.swift` | `Core/Training/PitchComparison.swift` |
| `Core/Training/ComparisonObserver.swift` | `Core/Training/PitchComparisonObserver.swift` |
| `Core/Profile/PitchDiscriminationProfile.swift` | `Core/Profile/PitchComparisonProfile.swift` |
| `Core/Algorithm/NextComparisonStrategy.swift` | `Core/Algorithm/NextPitchComparisonStrategy.swift` |
| `Core/Data/ComparisonRecord.swift` | `Core/Data/PitchComparisonRecord.swift` |
| `Core/Data/ComparisonRecordStoring.swift` | `Core/Data/PitchComparisonRecordStoring.swift` |
| `Comparison/ComparisonSession.swift` | `PitchComparison/PitchComparisonSession.swift` |
| `Comparison/ComparisonScreen.swift` | `PitchComparison/PitchComparisonScreen.swift` |
| `Comparison/ComparisonFeedbackIndicator.swift` | `PitchComparison/PitchComparisonFeedbackIndicator.swift` |
| `Comparison/HapticFeedbackManager.swift` | `PitchComparison/HapticFeedbackManager.swift` |

**Files (tests):**

| Current | New |
|---------|-----|
| `Core/Training/ComparisonTests.swift` | `Core/Training/PitchComparisonTests.swift` |
| `Core/Profile/PitchDiscriminationProfileTests.swift` | `Core/Profile/PitchComparisonProfileTests.swift` |
| `Profile/MockPitchDiscriminationProfile.swift` | `Profile/MockPitchComparisonProfile.swift` |
| `Comparison/ComparisonSessionTests.swift` | `PitchComparison/PitchComparisonSessionTests.swift` |
| `Comparison/ComparisonSessionLifecycleTests.swift` | `PitchComparison/PitchComparisonSessionLifecycleTests.swift` |
| `Comparison/ComparisonSessionUserDefaultsTests.swift` | `PitchComparison/PitchComparisonSessionUserDefaultsTests.swift` |
| `Comparison/ComparisonSessionFeedbackTests.swift` | `PitchComparison/PitchComparisonSessionFeedbackTests.swift` |
| `Comparison/ComparisonSessionResetTests.swift` | `PitchComparison/PitchComparisonSessionResetTests.swift` |
| `Comparison/ComparisonSessionDifficultyTests.swift` | `PitchComparison/PitchComparisonSessionDifficultyTests.swift` |
| `Comparison/ComparisonSessionIntegrationTests.swift` | `PitchComparison/PitchComparisonSessionIntegrationTests.swift` |
| `Comparison/ComparisonSessionAudioInterruptionTests.swift` | `PitchComparison/PitchComparisonSessionAudioInterruptionTests.swift` |
| `Comparison/ComparisonSessionSettingsTests.swift` | `PitchComparison/PitchComparisonSessionSettingsTests.swift` |
| `Comparison/ComparisonScreenLayoutTests.swift` | `PitchComparison/PitchComparisonScreenLayoutTests.swift` |
| `Comparison/ComparisonScreenFeedbackTests.swift` | `PitchComparison/PitchComparisonScreenFeedbackTests.swift` |
| `Comparison/ComparisonScreenAccessibilityTests.swift` | `PitchComparison/PitchComparisonScreenAccessibilityTests.swift` |
| `Comparison/ComparisonAccuracySummaryTests.swift` | `PitchComparison/PitchComparisonAccuracySummaryTests.swift` |
| `Comparison/ComparisonTestHelpers.swift` | `PitchComparison/PitchComparisonTestHelpers.swift` |
| `Comparison/MockNextComparisonStrategy.swift` | `PitchComparison/MockNextPitchComparisonStrategy.swift` |
| `Comparison/MockTrainingDataStore.swift` | `PitchComparison/MockTrainingDataStore.swift` (no name change) |
| `Comparison/MockHapticFeedbackManager.swift` | `PitchComparison/MockHapticFeedbackManager.swift` (no name change) |
| `Comparison/MockNotePlayer.swift` | `PitchComparison/MockNotePlayer.swift` (no name change) |

**Mock/test helper types:**

| Current | New |
|---------|-----|
| `MockNextComparisonStrategy` | `MockNextPitchComparisonStrategy` |
| `MockPitchDiscriminationProfile` | `MockPitchComparisonProfile` |
| `ComparisonSessionFixture` | `PitchComparisonSessionFixture` |
| `makeComparisonSession(...)` | `makePitchComparisonSession(...)` |

**CSV/import string constants:**

| Current | New |
|---------|-----|
| `"comparison"` (TrainingType raw value) | `"pitchComparison"` |
| `comparisonColumns` | `pitchComparisonColumns` |

### Technical Decisions

- **No SwiftData migration**: User accepts data loss. Simply rename the `@Model` class; existing store will be incompatible and replaced.
- **Directory renames**: `Peach/Comparison/` -> `Peach/PitchComparison/` and `PeachTests/Comparison/` -> `PeachTests/PitchComparison/`.
- **CSV format change**: The "comparison" string in CSV export/import changes to "pitchComparison". Breaking change for exported CSVs -- acceptable since no external consumers exist.
- **Historical docs untouched**: All files in `docs/claude-audit/`, completed numbered story files in `docs/implementation-artifacts/`, `docs/brainstorming/`, `docs/planning-artifacts/research/`, validation reports, and implementation-readiness reports must not be modified.
- **`git mv` for all file/directory renames**: Preserves git history tracking.
- **HapticFeedbackManager.swift**: Moves with directory rename but file name stays -- it is not Comparison-specific.

## Implementation Plan

### Tasks

Implementation is structured in 4 phases: (1) file/directory renames via git, (2) content renames in source code, (3) content renames in tests, (4) documentation updates. Each phase must compile/pass before the next.

#### Phase 1: File and Directory Renames

All renames use `git mv`. Perform directory renames first, then individual file renames.

- [x] Task 1.1: Rename source directories
  - Action: `git mv Peach/Comparison Peach/PitchComparison`
  - Notes: This moves all files in the directory. HapticFeedbackManager.swift moves but keeps its name.

- [x] Task 1.2: Rename source files in Core/
  - Action: `git mv` each file:
    - `Peach/Core/Training/Comparison.swift` -> `PitchComparison.swift`
    - `Peach/Core/Training/ComparisonObserver.swift` -> `PitchComparisonObserver.swift`
    - `Peach/Core/Profile/PitchDiscriminationProfile.swift` -> `PitchComparisonProfile.swift`
    - `Peach/Core/Algorithm/NextComparisonStrategy.swift` -> `NextPitchComparisonStrategy.swift`
    - `Peach/Core/Data/ComparisonRecord.swift` -> `PitchComparisonRecord.swift`
    - `Peach/Core/Data/ComparisonRecordStoring.swift` -> `PitchComparisonRecordStoring.swift`

- [x] Task 1.3: Rename source files in PitchComparison/ (already moved by 1.1)
  - Action: `git mv` each file within `Peach/PitchComparison/`:
    - `ComparisonSession.swift` -> `PitchComparisonSession.swift`
    - `ComparisonScreen.swift` -> `PitchComparisonScreen.swift`
    - `ComparisonFeedbackIndicator.swift` -> `PitchComparisonFeedbackIndicator.swift`

- [x] Task 1.4: Rename test directories
  - Action: `git mv PeachTests/Comparison PeachTests/PitchComparison`

- [x] Task 1.5: Rename test files in PitchComparison/ (already moved by 1.4)
  - Action: `git mv` each file that needs a name change:
    - `ComparisonSessionTests.swift` -> `PitchComparisonSessionTests.swift`
    - `ComparisonSessionLifecycleTests.swift` -> `PitchComparisonSessionLifecycleTests.swift`
    - `ComparisonSessionUserDefaultsTests.swift` -> `PitchComparisonSessionUserDefaultsTests.swift`
    - `ComparisonSessionFeedbackTests.swift` -> `PitchComparisonSessionFeedbackTests.swift`
    - `ComparisonSessionResetTests.swift` -> `PitchComparisonSessionResetTests.swift`
    - `ComparisonSessionDifficultyTests.swift` -> `PitchComparisonSessionDifficultyTests.swift`
    - `ComparisonSessionIntegrationTests.swift` -> `PitchComparisonSessionIntegrationTests.swift`
    - `ComparisonSessionAudioInterruptionTests.swift` -> `PitchComparisonSessionAudioInterruptionTests.swift`
    - `ComparisonSessionSettingsTests.swift` -> `PitchComparisonSessionSettingsTests.swift`
    - `ComparisonScreenLayoutTests.swift` -> `PitchComparisonScreenLayoutTests.swift`
    - `ComparisonScreenFeedbackTests.swift` -> `PitchComparisonScreenFeedbackTests.swift`
    - `ComparisonScreenAccessibilityTests.swift` -> `PitchComparisonScreenAccessibilityTests.swift`
    - `ComparisonAccuracySummaryTests.swift` -> `PitchComparisonAccuracySummaryTests.swift`
    - `ComparisonTestHelpers.swift` -> `PitchComparisonTestHelpers.swift`
    - `MockNextComparisonStrategy.swift` -> `MockNextPitchComparisonStrategy.swift`
  - Notes: MockTrainingDataStore.swift, MockHapticFeedbackManager.swift, MockNotePlayer.swift keep their names (not Comparison-specific).

- [x] Task 1.6: Rename other test files
  - Action: `git mv` each file:
    - `PeachTests/Profile/MockPitchDiscriminationProfile.swift` -> `MockPitchComparisonProfile.swift`
    - `PeachTests/Core/Profile/PitchDiscriminationProfileTests.swift` -> `PitchComparisonProfileTests.swift`
    - `PeachTests/Core/Training/ComparisonTests.swift` -> `PitchComparisonTests.swift`

- [x] Task 1.7: Update Xcode project file
  - File: `Peach.xcodeproj/project.pbxproj`
  - Action: After `git mv`, open Xcode or use `xcodebuild` to verify file references resolve. If Xcode auto-detects the moves, no manual pbxproj editing is needed. If references break, re-add files to the project in Xcode.
  - Notes: Modern Xcode with folder references may handle this automatically. Verify by building.

#### Phase 2: Source Code Content Renames

Apply all identifier renames from the Rename Reference Table to source files. Process bottom-up: value types and protocols first, then conformances, then consumers.

- [x] Task 2.1: Rename value types and protocols (leaf dependencies)
  - Files:
    - `Peach/Core/Training/PitchComparison.swift`: Rename `Comparison` -> `PitchComparison`, `CompletedComparison` -> `CompletedPitchComparison`
    - `Peach/Core/Training/PitchComparisonObserver.swift`: Rename protocol `ComparisonObserver` -> `PitchComparisonObserver`, method `comparisonCompleted` -> `pitchComparisonCompleted`
    - `Peach/Core/Profile/PitchComparisonProfile.swift`: Rename protocol `PitchDiscriminationProfile` -> `PitchComparisonProfile`
    - `Peach/Core/Algorithm/NextPitchComparisonStrategy.swift`: Rename protocol `NextComparisonStrategy` -> `NextPitchComparisonStrategy`, method `nextComparison` -> `nextPitchComparison`, parameter `lastComparison` -> `lastPitchComparison`, return type `Comparison` -> `PitchComparison`, update comments replacing "discrimination" with "pitch comparison"
    - `Peach/Core/Data/PitchComparisonRecord.swift`: Rename class `ComparisonRecord` -> `PitchComparisonRecord`
    - `Peach/Core/Data/PitchComparisonRecordStoring.swift`: Rename protocol `ComparisonRecordStoring` -> `PitchComparisonRecordStoring`, method `fetchAllComparisons` -> `fetchAllPitchComparisons`, parameter types

- [x] Task 2.2: Rename conforming implementations
  - Files:
    - `Peach/PitchComparison/PitchComparisonSession.swift`: Rename class `ComparisonSession` -> `PitchComparisonSession`, enum `ComparisonSessionState` -> `PitchComparisonSessionState`, all properties (`currentComparison` -> `currentPitchComparison`, `lastCompletedComparison` -> `lastCompletedPitchComparison`), all private methods (`playNextComparison` -> `playNextPitchComparison`, `playComparisonNotes` -> `playPitchComparisonNotes`, `recordComparison` -> `recordPitchComparison`), all protocol references, logger messages
    - `Peach/Core/Algorithm/KazezNoteStrategy.swift`: Update conformance to `NextPitchComparisonStrategy`, method signature `nextPitchComparison(...)`, return type, parameter names
    - `Peach/Core/Profile/PerceptualProfile.swift`: Update conformance from `PitchDiscriminationProfile` to `PitchComparisonProfile`
    - `Peach/Core/Data/TrainingDataStore.swift`: Update conformances to `PitchComparisonRecordStoring` + `PitchComparisonObserver`, method signatures (`fetchAllPitchComparisons`, `pitchComparisonCompleted`), parameter types
    - `Peach/Core/Profile/ProgressTimeline.swift`: Rename `TrainingMode` cases `.unisonComparison` -> `.unisonPitchComparison`, `.intervalComparison` -> `.intervalPitchComparison`, update all references and switch statements

- [x] Task 2.3: Rename CSV/import/export layer
  - Files:
    - `Peach/Core/Data/CSVExportSchema.swift`: Rename `TrainingType.comparison` -> `.pitchComparison`, `comparisonColumns` -> `pitchComparisonColumns`, string literal `"comparison"` -> `"pitchComparison"`
    - `Peach/Core/Data/CSVRecordFormatter.swift`: Update type references (`PitchComparisonRecord`, `.pitchComparison`)
    - `Peach/Core/Data/CSVImportParser.swift`: Update string literal `"comparison"` -> `"pitchComparison"`, type references, error messages
    - `Peach/Core/Data/TrainingDataImporter.swift`: Update string constant `"comparison"` -> `"pitchComparison"`, type references
    - `Peach/Core/Data/TrainingDataExporter.swift`: Update type references
    - `Peach/Core/Data/TrainingDataTransferService.swift`: Update type references

- [x] Task 2.4: Rename UI layer
  - Files:
    - `Peach/PitchComparison/PitchComparisonScreen.swift`: Rename struct `ComparisonScreen` -> `PitchComparisonScreen`, `@Environment(\.comparisonSession)` -> `@Environment(\.pitchComparisonSession)`, property name `comparisonSession` -> `pitchComparisonSession`
    - `Peach/PitchComparison/PitchComparisonFeedbackIndicator.swift`: Rename struct `ComparisonFeedbackIndicator` -> `PitchComparisonFeedbackIndicator`, update all type references
    - `Peach/App/NavigationDestination.swift`: Rename case `.comparison` -> `.pitchComparison`, update all switch statements
    - `Peach/App/ContentView.swift`: Update navigation destination references (`.pitchComparison`, `PitchComparisonScreen`)
    - `Peach/Start/StartScreen.swift`: Update navigation references
    - `Peach/App/TrainingStatsView.swift`: Update type references
    - `Peach/Profile/ProfileScreen.swift`: Update type references if any

- [x] Task 2.5: Rename composition root and environment
  - Files:
    - `Peach/App/EnvironmentKeys.swift`: Rename `@Entry var comparisonSession` -> `@Entry var pitchComparisonSession`, preview stub types (`PreviewComparisonStrategy` -> `PreviewPitchComparisonStrategy`, etc.), all protocol conformances and method signatures in preview stubs
    - `Peach/App/PeachApp.swift`: Update all type references, `ModelContainer` schema registration (`PitchComparisonRecord.self`), observer array types, session construction

- [x] Task 2.6: Build and fix
  - Action: Run `bin/build.sh`
  - Notes: Fix any remaining compile errors. The compiler will catch any missed renames. Iterate until clean build.

#### Phase 3: Test Code Content Renames

- [x] Task 3.1: Rename test helpers and mocks
  - Files:
    - `PeachTests/PitchComparison/PitchComparisonTestHelpers.swift`: Rename `ComparisonSessionFixture` -> `PitchComparisonSessionFixture`, `makeComparisonSession` -> `makePitchComparisonSession`, all type references
    - `PeachTests/PitchComparison/MockNextPitchComparisonStrategy.swift`: Rename class `MockNextComparisonStrategy` -> `MockNextPitchComparisonStrategy`, method `nextComparison` -> `nextPitchComparison`, all property/parameter names
    - `PeachTests/Profile/MockPitchComparisonProfile.swift`: Rename class `MockPitchDiscriminationProfile` -> `MockPitchComparisonProfile`
    - `PeachTests/PitchComparison/MockTrainingDataStore.swift`: Update protocol conformances and method signatures (`PitchComparisonRecordStoring`, `PitchComparisonObserver`, `pitchComparisonCompleted`, `fetchAllPitchComparisons`)

- [x] Task 3.2: Rename all test suites in PeachTests/PitchComparison/
  - Files: All 14 test files in `PeachTests/PitchComparison/`
  - Action: For each file, update `@Suite` names, struct names (e.g., `ComparisonSessionTests` -> `PitchComparisonSessionTests`), all type references, factory method calls (`makePitchComparisonSession`), `waitForState` calls, property accesses

- [x] Task 3.3: Rename other test files
  - Files:
    - `PeachTests/Core/Training/PitchComparisonTests.swift`: Rename suite and all type references
    - `PeachTests/Core/Profile/PitchComparisonProfileTests.swift`: Rename suite, update `MockPitchComparisonProfile` references
    - `PeachTests/Core/Profile/PitchMatchingProfileTests.swift`: Update `MockPitchComparisonProfile` references if any
    - `PeachTests/Core/Training/ResettableTests.swift`: Update `PitchComparisonSession` references
    - `PeachTests/Core/TrainingSessionTests.swift`: Update `PitchComparisonSession` references
    - `PeachTests/Core/Profile/ProgressTimelineTests.swift`: Update `CompletedPitchComparison` and `TrainingMode` case references
    - `PeachTests/Core/Data/TrainingDataStoreTests.swift`: Update `PitchComparisonRecord`, `CompletedPitchComparison` references
    - `PeachTests/Core/Data/CSVImportParserTests.swift`: Update "pitchComparison" string literals
    - `PeachTests/Core/Data/CSVExportSchemaTests.swift`: Update `.pitchComparison` enum case references
    - `PeachTests/Settings/TrainingDataImportActionTests.swift`: Update type references
    - `PeachTests/Start/StartScreenTests.swift`: Update `.pitchComparison` navigation destination references

- [x] Task 3.4: Run full test suite
  - Action: Run `bin/test.sh`
  - Notes: All tests must pass. Fix any remaining compile errors or test failures.

#### Phase 4: Documentation Updates

- [x] Task 4.1: Update project-context.md
  - File: `docs/project-context.md`
  - Action: Replace all type name references per Rename Reference Table. Replace "discrimination" with "pitch comparison" in conceptual text. Update file paths (`Comparison/` -> `PitchComparison/`).

- [x] Task 4.2: Update glossary
  - File: `docs/planning-artifacts/glossary.md`
  - Action: Rename entries:
    - "Comparison" -> "Pitch Comparison"
    - "Completed Comparison" -> "Completed Pitch Comparison"
    - "Pitch Discrimination Profile" -> "Pitch Comparison Profile" (update definition to remove "discrimination" language)
    - "Next Comparison Strategy" -> "Next Pitch Comparison Strategy"
    - "Comparison Session" -> "Pitch Comparison Session"
    - "Comparison Session State" -> "Pitch Comparison Session State"
    - "Comparison Observer" -> "Pitch Comparison Observer"
    - "Comparison Screen" -> "Pitch Comparison Screen"
    - "Comparison Feedback Indicator" -> "Pitch Comparison Feedback Indicator"
    - Update all type names in definitions (backtick references)
    - Replace "discrimination" with "pitch comparison" in definitions

- [x] Task 4.3: Update architecture doc
  - File: `docs/planning-artifacts/architecture.md`
  - Action: Replace all type names, directory references, concept text. This is the most extensive doc -- update systematically section by section.

- [x] Task 4.4: Update PRD
  - File: `docs/planning-artifacts/prd.md`
  - Action: Replace type names, "discrimination" -> "pitch comparison" in concept text, "comparison" -> "pitch comparison" where it refers to the training mode.

- [x] Task 4.5: Update epics
  - File: `docs/planning-artifacts/epics.md`
  - Action: Update FR descriptions, epic titles, type name references.

- [x] Task 4.6: Update UX design spec
  - File: `docs/planning-artifacts/ux-design-specification.md`
  - Action: Update training mode names, user journey text, screen names.

- [x] Task 4.7: Update arc42 docs (all affected sections)
  - Files: `docs/arc42/02-constraints.md`, `03-context-and-scope.md`, `04-solution-strategy.md`, `05-building-block-view.md`, `06-runtime-view.md`, `07-deployment-view.md`, `08-crosscutting-concepts.md`, `09-architecture-decisions.md`, `10-quality-requirements.md`, `12-glossary.md`, `index.md`
  - Action: Replace all type names, directory references, diagram participant names, concept text per Rename Reference Table. Update Mermaid diagrams where type names appear as participants or labels.

- [x] Task 4.8: Update sprint-status and README
  - Files: `docs/implementation-artifacts/sprint-status.yaml`, `docs/README.md`
  - Action: Update type references, backlog item description, app description.

- [x] Task 4.9: Update localization strings
  - File: `Peach/Localizable.xcstrings` (if applicable)
  - Action: Check for user-facing strings containing "comparison" or "discrimination" and update. Note: most UI strings may use generic terms ("higher"/"lower") rather than "comparison" -- verify before changing.

- [x] Task 4.10: Final verification
  - Action: Run `grep -ri "Discrimination" --include="*.swift" --include="*.md"` excluding historical dirs. Run `grep -r "ComparisonSession\|ComparisonRecord\|ComparisonObserver\|ComparisonScreen\|NextComparisonStrategy\|ComparisonFeedbackIndicator" --include="*.swift"`. Verify zero matches outside historical docs.

### Acceptance Criteria

- [x] AC 1: Given the full codebase, when searching for `PitchDiscriminationProfile` in all `.swift` files, then zero matches are found.
- [x] AC 2: Given the full codebase, when searching for `ComparisonSession` (without `PitchComparison` prefix) in all `.swift` files, then zero matches are found.
- [x] AC 3: Given the full codebase, when searching for `ComparisonRecord` (without `PitchComparison` prefix) in all `.swift` files, then zero matches are found.
- [x] AC 4: Given the full codebase, when searching for `ComparisonObserver` (without `PitchComparison` prefix) in all `.swift` files, then zero matches are found.
- [x] AC 5: Given the full codebase, when searching for `NextComparisonStrategy` (without `PitchComparison` prefix) in all `.swift` files, then zero matches are found.
- [x] AC 6: Given the project, when running `bin/build.sh`, then the build succeeds with zero errors.
- [x] AC 7: Given the project, when running `bin/test.sh`, then all tests pass.
- [x] AC 8: Given the active documentation files, when searching for "discrimination" (case-insensitive), then zero matches are found outside historical docs.
- [x] AC 9: Given the active documentation files, when searching for `ComparisonSession` or `ComparisonRecord` or `PitchDiscriminationProfile`, then zero matches are found outside historical docs.
- [x] AC 10: Given the `Peach/` directory structure, then directories `Peach/PitchComparison/` and `PeachTests/PitchComparison/` exist and `Peach/Comparison/` and `PeachTests/Comparison/` do not exist.
- [x] AC 11: Given the git log, then file renames are tracked via `git mv` (verifiable with `git log --follow`).
- [x] AC 12: Given historical docs (`docs/claude-audit/`, completed story files, brainstorming, research, validation reports), then none have been modified (verify with `git diff` on those paths).

## Additional Context

### Dependencies

None. This is a pure rename refactoring with no functional changes.

### Testing Strategy

- **No new tests needed** -- behavior is unchanged; all existing tests are renamed and must pass
- **Build verification**: `bin/build.sh` must succeed after Phase 2
- **Test verification**: `bin/test.sh` must succeed after Phase 3
- **Grep verification**: Automated search for stale names after Phase 4
- **Historical doc verification**: `git diff` confirms no changes to excluded files

### Notes

- **Risk: Xcode project file**: The `.pbxproj` file may need manual intervention if Xcode doesn't auto-detect `git mv` renames. Mitigation: Build immediately after Phase 1 to detect early.
- **Risk: Merge conflicts**: This rename touches many files. If other work is in progress on a branch, merging will be painful. Mitigation: Perform this rename on a clean `main` with no pending work.
- **Future work**: SwiftData schema versioning (separate spec as discussed in party mode).
- **CSV breaking change**: Exported CSV files using `"comparison"` type tag will not be importable after this rename. Acceptable -- no external consumers exist.
