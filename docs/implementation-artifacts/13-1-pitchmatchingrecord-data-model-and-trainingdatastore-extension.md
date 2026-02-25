# Story 13.1: PitchMatchingRecord Data Model and TrainingDataStore Extension

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want pitch matching results persisted in SwiftData alongside comparison records,
So that all training data is reliably stored and available for profile computation and future analysis.

## Acceptance Criteria

1. **PitchMatchingRecord model created** — A SwiftData `@Model` with fields: `referenceNote` (Int, MIDI 0-127), `initialCentOffset` (Double, ±100 cents), `userCentError` (Double, signed — positive = sharp, negative = flat), `timestamp` (Date). File located at `Core/Data/PitchMatchingRecord.swift`.

2. **CompletedPitchMatching value type created** — A struct with fields: `referenceNote` (Int), `initialCentOffset` (Double), `userCentError` (Double), `timestamp` (Date). File located at `PitchMatching/CompletedPitchMatching.swift`.

3. **PitchMatchingChallenge value type created** — A struct with fields: `referenceNote` (Int, MIDI 0-127), `initialCentOffset` (Double, random ±100 cents). File located at `PitchMatching/PitchMatchingChallenge.swift`.

4. **PitchMatchingObserver protocol created** — Defines `func pitchMatchingCompleted(_ result: CompletedPitchMatching)`. File located at `PitchMatching/PitchMatchingObserver.swift`.

5. **TrainingDataStore extended with pitch matching CRUD** — Supports `save(_ record: PitchMatchingRecord) throws`, `fetchAllPitchMatching() throws -> [PitchMatchingRecord]`, and `deleteAllPitchMatching() throws`. `TrainingDataStore` conforms to `PitchMatchingObserver`, automatically persisting completed pitch matching attempts.

6. **ModelContainer schema updated** — `PeachApp.swift` registers both `ComparisonRecord.self` and `PitchMatchingRecord.self` in the `ModelContainer`.

7. **All tests pass** — All existing tests pass. New tests verify: PitchMatchingRecord CRUD operations, TrainingDataStore pitch matching persistence, atomic writes, in-memory ModelContainer for tests.

## Tasks / Subtasks

- [ ] Task 1: Create PitchMatchingRecord SwiftData model (AC: #1)
  - [ ] 1.1 Create `Peach/Core/Data/PitchMatchingRecord.swift` with `@Model` class containing `referenceNote`, `initialCentOffset`, `userCentError`, `timestamp` fields
  - [ ] 1.2 Write tests: `PeachTests/Core/Data/PitchMatchingRecordTests.swift` — verify field storage, default timestamp, all fields intact after save/fetch

- [ ] Task 2: Create PitchMatching value types and observer protocol (AC: #2, #3, #4)
  - [ ] 2.1 Create `Peach/PitchMatching/` directory
  - [ ] 2.2 Create `Peach/PitchMatching/CompletedPitchMatching.swift` — struct with `referenceNote`, `initialCentOffset`, `userCentError`, `timestamp` fields (mirroring `CompletedComparison` pattern)
  - [ ] 2.3 Create `Peach/PitchMatching/PitchMatchingChallenge.swift` — struct with `referenceNote`, `initialCentOffset` fields
  - [ ] 2.4 Create `Peach/PitchMatching/PitchMatchingObserver.swift` — protocol with `pitchMatchingCompleted(_:)` method (mirroring `ComparisonObserver` pattern)

- [ ] Task 3: Extend TrainingDataStore with pitch matching CRUD (AC: #5)
  - [ ] 3.1 Add `save(_ record: PitchMatchingRecord) throws` to TrainingDataStore
  - [ ] 3.2 Add `fetchAllPitchMatching() throws -> [PitchMatchingRecord]` to TrainingDataStore (sorted by timestamp ascending, matching `fetchAll()` pattern)
  - [ ] 3.3 Add `deleteAllPitchMatching() throws` to TrainingDataStore (for Settings "Reset All Training Data")
  - [ ] 3.4 Add `PitchMatchingObserver` conformance via extension (mirroring `ComparisonObserver` conformance pattern — catch and log errors, don't propagate)
  - [ ] 3.5 Write tests: extend `TrainingDataStoreTests.swift` — verify pitch matching save, fetchAll, deleteAll, observer conformance, error handling

- [ ] Task 4: Update ModelContainer schema (AC: #6)
  - [ ] 4.1 Update `PeachApp.swift`: change `ModelContainer(for: ComparisonRecord.self)` to `ModelContainer(for: ComparisonRecord.self, PitchMatchingRecord.self)`
  - [ ] 4.2 Update test helper `makeTestContainer()` in TrainingDataStore tests to register both models

- [ ] Task 5: Update MockTrainingDataStore for pitch matching (AC: #7)
  - [ ] 5.1 Add `PitchMatchingObserver` conformance to `MockTrainingDataStore` — track `savePitchMatchingCallCount`, `lastSavedPitchMatchingRecord`, `savedPitchMatchingRecords`
  - [ ] 5.2 Add `fetchAllPitchMatching()` and pitch matching reset support
  - [ ] 5.3 Update existing `deleteAll()` in Settings to also call `deleteAllPitchMatching()` (ensure Reset All Training Data clears both record types)

- [ ] Task 6: Run full test suite and verify (AC: #7)
  - [ ] 6.1 Run `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] 6.2 Verify all existing tests pass with zero regressions
  - [ ] 6.3 Verify all new pitch matching data layer tests pass

## Dev Notes

### Architecture Patterns and Constraints

- **TrainingDataStore is the sole SwiftData accessor** — all pitch matching CRUD goes through this single service, never direct `ModelContext` usage. [Source: docs/project-context.md#SwiftData]
- **Observer pattern for decoupled persistence** — `PitchMatchingObserver` mirrors `ComparisonObserver` exactly. `TrainingDataStore` conforms to both. Observer catches its own errors — never fails training. [Source: docs/planning-artifacts/architecture.md#PitchMatchingObserver-Pattern]
- **Value types by default** — `CompletedPitchMatching` and `PitchMatchingChallenge` are structs (like `CompletedComparison` and `Comparison`). [Source: docs/project-context.md#Type-Design]
- **Default MainActor isolation** — all code is implicitly `@MainActor` per Swift 6.2 project settings. Do NOT add explicit `@MainActor`. [Source: docs/project-context.md#Concurrency]
- **No HapticFeedbackManager conformance** — `HapticFeedbackManager` does NOT conform to `PitchMatchingObserver` (UX spec decision: no haptics for pitch matching). [Source: docs/planning-artifacts/architecture.md#PitchMatchingObserver-Pattern]

### Source Tree Components to Touch

**New files:**
| File | Location | Description |
|------|----------|-------------|
| `PitchMatchingRecord.swift` | `Peach/Core/Data/` | SwiftData `@Model` for pitch matching results |
| `CompletedPitchMatching.swift` | `Peach/PitchMatching/` | Value type for observer notification |
| `PitchMatchingChallenge.swift` | `Peach/PitchMatching/` | Value type for challenge parameters |
| `PitchMatchingObserver.swift` | `Peach/PitchMatching/` | Observer protocol |
| `PitchMatchingRecordTests.swift` | `PeachTests/Core/Data/` | Tests for the new model |

**Modified files:**
| File | Location | Change |
|------|----------|--------|
| `TrainingDataStore.swift` | `Peach/Core/Data/` | Add pitch matching CRUD + PitchMatchingObserver conformance |
| `PeachApp.swift` | `Peach/App/` | Register `PitchMatchingRecord.self` in ModelContainer schema |
| `TrainingDataStoreTests.swift` | `PeachTests/Core/Data/` | Add pitch matching CRUD tests, update `makeTestContainer()` |
| `MockTrainingDataStore.swift` | `PeachTests/Comparison/` | Add PitchMatchingObserver conformance and tracking |

**New directory:** `Peach/PitchMatching/` — this is the feature directory for all pitch matching components (future stories will add `PitchMatchingSession`, `PitchMatchingScreen`, etc.)

### Existing Code Patterns to Follow Exactly

**ComparisonRecord pattern** (`Peach/Core/Data/ComparisonRecord.swift`):
```swift
import SwiftData
import Foundation

@Model
final class ComparisonRecord {
    var note1: Int
    var note2: Int
    var note2CentOffset: Double
    var isCorrect: Bool
    var timestamp: Date

    init(note1: Int, note2: Int, note2CentOffset: Double, isCorrect: Bool, timestamp: Date = Date()) {
        // field assignments
    }
}
```

**TrainingDataStore observer pattern** (`Peach/Core/Data/TrainingDataStore.swift`):
```swift
extension TrainingDataStore: ComparisonObserver {
    func comparisonCompleted(_ completed: CompletedComparison) {
        let record = ComparisonRecord(/* map fields */)
        do {
            try save(record)
        } catch let error as DataStoreError {
            print("warning message")
        } catch {
            print("unexpected error message")
        }
    }
}
```

**ComparisonObserver pattern** (`Peach/Comparison/ComparisonObserver.swift`):
```swift
protocol ComparisonObserver {
    func comparisonCompleted(_ completed: CompletedComparison)
}
```

**Test pattern** (`PeachTests/Core/Data/TrainingDataStoreTests.swift`):
- In-memory `ModelContainer` via `ModelConfiguration(isStoredInMemoryOnly: true)`
- Factory method `makeTestContainer()` returns `ModelContainer`
- Each test creates its own `ModelContext(container)` and `TrainingDataStore(modelContext:)`
- Uses `@Test("behavioral description")` and `#expect()`
- All test functions are `async`

**MockTrainingDataStore pattern** (`PeachTests/Comparison/MockTrainingDataStore.swift`):
- Tracks `saveCallCount`, `lastSavedRecord`, `savedRecords`
- `shouldThrowError` flag with `errorToThrow`
- `reset()` method clears all state
- Observer implementation converts value type to record and calls `save()`

### Data Model Design Notes

- **`initialCentOffset`** is stored for future analysis (sharp vs. flat starting bias)
- **`userCentError`** is signed — positive means user tuned sharp, negative means flat
- User's final absolute pitch is derivable: reference note frequency + `userCentError` cents
- **No `isCorrect` field** on PitchMatchingRecord — pitch matching is continuous accuracy, not binary correct/incorrect (unlike ComparisonRecord)
- **MIDI note range: 0-127** — same constraint as ComparisonRecord

### Settings "Reset All Training Data" Integration

The existing `deleteAll()` in Settings currently calls `TrainingDataStore.deleteAll()` which only deletes ComparisonRecords. After this story, the reset path in `SettingsScreen.swift` must also call `deleteAllPitchMatching()` to clear both record types. Check how `SettingsScreen` calls the delete — it may go through `TrainingDataStore` or directly through the model context.

### Testing Standards Summary

- **Swift Testing only** — `@Test`, `@Suite`, `#expect()` — NEVER XCTest
- **All test functions must be `async`**
- **In-memory ModelContainer** for all data tests — `ModelConfiguration(isStoredInMemoryOnly: true)`
- **Fresh instances per test** — each test creates its own container, context, and store
- **Behavioral test descriptions** — `@Test("saves and retrieves a pitch matching record")`
- **No `test` prefix** on function names
- **Run full suite**: `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`

### Project Structure Notes

- All new files align with the v0.2 architecture document's updated project structure
- `PitchMatchingRecord.swift` goes in `Core/Data/` (data layer, alongside ComparisonRecord)
- `PitchMatchingObserver.swift`, `CompletedPitchMatching.swift`, `PitchMatchingChallenge.swift` go in `PitchMatching/` (feature directory, mirroring how `ComparisonObserver.swift`, `CompletedComparison` live in `Comparison/`)
- The new `Peach/PitchMatching/` directory must be added to the Xcode project

### Previous Story Intelligence (Story 12.1)

- **PlaybackHandle redesign completed** — NotePlayer now returns `PlaybackHandle` from `play()`, enabling indefinite playback for future pitch matching. `stopAll()` added for interruption cleanup.
- **Code review fixes applied** — `adjustFrequency()` validation (20-20000 Hz range), pitch bend range validation (±200 cents), duration validation in convenience method.
- **Key learning**: When adding protocol methods, ensure all conforming types (including preview mocks like `MockNotePlayerForPreview` in `ComparisonScreen.swift`) are updated.
- **Key learning**: Dynamic dispatch needed for test mocks — if a method is only in a protocol extension (not declared in the protocol), mocks can't override it. Declare in protocol if override is needed.
- **Test count**: 409 tests passing as of 12.1 completion.

### Git Intelligence (Recent Commits)

```
737d647 Mark story 12.2 as won't do and close epics 11, 12
b34e86d Fix code review findings for 12-1-playbackhandle-protocol-and-noteplayer-redesign
e90367f Implement story 12.1: PlaybackHandle Protocol and NotePlayer Redesign
cd3f1d6 Add story 12.1: PlaybackHandle Protocol and NotePlayer Redesign
1644036 Fix code review findings for 11-1-rename-training-types-and-files-to-comparison
```

- Commit pattern: `Add story X.Y: Title` for story creation, `Implement story X.Y: Title` for implementation
- Recent work has been pure refactoring (renames, protocol redesign) — no new features or data models
- Story 12.2 was marked `wont-do` — ComparisonSession didn't need PlaybackHandle integration because `stopAll()` covered the need

### References

- [Source: docs/planning-artifacts/architecture.md#PitchMatchingRecord-Data-Model]
- [Source: docs/planning-artifacts/architecture.md#PitchMatchingObserver-Pattern]
- [Source: docs/planning-artifacts/architecture.md#TrainingDataStore-Extension]
- [Source: docs/planning-artifacts/architecture.md#Updated-Project-Structure-v0.2]
- [Source: docs/planning-artifacts/epics.md#Epic-13-Story-13.1]
- [Source: docs/project-context.md#SwiftData]
- [Source: docs/project-context.md#Testing-Rules]
- [Source: docs/project-context.md#Swift-6.2-Concurrency]
- [Source: Peach/Core/Data/ComparisonRecord.swift — @Model pattern to replicate]
- [Source: Peach/Core/Data/TrainingDataStore.swift — CRUD and observer pattern to extend]
- [Source: Peach/Core/Data/ComparisonRecordStoring.swift — protocol pattern]
- [Source: Peach/Core/Data/DataStoreError.swift — error enum (no changes needed)]
- [Source: Peach/Comparison/ComparisonObserver.swift — observer protocol pattern to replicate]
- [Source: Peach/Comparison/Comparison.swift — CompletedComparison value type pattern to replicate]
- [Source: Peach/App/PeachApp.swift — ModelContainer schema registration]
- [Source: PeachTests/Core/Data/TrainingDataStoreTests.swift — test pattern with in-memory container]
- [Source: PeachTests/Comparison/MockTrainingDataStore.swift — mock pattern to extend]
- [Source: docs/implementation-artifacts/12-1-playbackhandle-protocol-and-noteplayer-redesign.md — previous story learnings]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
