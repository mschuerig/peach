# Story 23.1: Data Model and Value Type Updates for Interval Context

Status: review

## Story

As a **developer building interval training**,
I want `ComparisonRecord` and `PitchMatchingRecord` to carry `interval` and `tuningSystem` fields, `PitchMatchingChallenge` and `CompletedPitchMatching` to carry `targetNote`, and all value types confirmed compatible with the two-world architecture,
So that every training result records full interval context for data integrity and future analysis.

## Acceptance Criteria

1. **ComparisonRecord gains `interval` and `tuningSystem` fields**
   - **Given** `ComparisonRecord` has `referenceNote`, `targetNote`, `centOffset`, `isCorrect`, `timestamp`
   - **When** `interval: Interval` and `tuningSystem: TuningSystem` fields are added
   - **Then** the SwiftData schema accepts the new fields
   - **And** `TrainingDataStore` saves and loads both
   - **And** `interval` is stored explicitly for efficient querying (even though derivable from `referenceNote` and `targetNote`)

2. **PitchMatchingRecord gains `targetNote`, `interval`, and `tuningSystem` fields**
   - **Given** `PitchMatchingRecord` has `referenceNote`, `initialCentOffset`, `userCentError`, `timestamp`
   - **When** `targetNote: MIDINote`, `interval: Interval`, and `tuningSystem: TuningSystem` fields are added
   - **Then** `TrainingDataStore` saves and loads all new fields
   - **And** `targetNote` represents the note the user was trying to match (equals `referenceNote` for unison)

3. **Comparison shape confirmed correct (no changes needed)**
   - **Given** `Comparison` already has `referenceNote: MIDINote` and `targetNote: DetunedMIDINote` (from Story 22.4)
   - **When** no structural changes are needed to `Comparison`
   - **Then** its shape is confirmed correct for interval training — `targetNote.note` is the transposed note, `targetNote.offset` is the training cent offset

4. **CompletedComparison gains `tuningSystem` field**
   - **Given** `CompletedComparison` value type
   - **When** `tuningSystem: TuningSystem` field is added
   - **Then** `ComparisonSession` populates it from its session-level parameter
   - **And** `TrainingDataStore` (as `ComparisonObserver`) persists it to `ComparisonRecord`

5. **PitchMatchingChallenge gains `targetNote` field**
   - **Given** `PitchMatchingChallenge` value type
   - **When** `targetNote: MIDINote` field is added
   - **Then** it represents the correct interval note the user should tune toward
   - **And** for unison: `targetNote == referenceNote`
   - **And** for intervals: `targetNote == referenceNote.transposed(by: interval)`

6. **CompletedPitchMatching gains `targetNote` and `tuningSystem` fields**
   - **Given** `CompletedPitchMatching` value type
   - **When** `targetNote: MIDINote` and `tuningSystem: TuningSystem` fields are added
   - **Then** `PitchMatchingSession` populates them from session-level parameters
   - **And** `TrainingDataStore` (as `PitchMatchingObserver`) persists them to `PitchMatchingRecord`

7. **No migration plan needed**
   - **Given** no production user base exists
   - **When** SwiftData schema changes are applied
   - **Then** no `SchemaMigrationPlan` is needed — fresh schema version is acceptable

## Tasks / Subtasks

- [x] Task 1: Add `interval` and `tuningSystem` to `ComparisonRecord` (AC: #1)
  - [x] Add `var interval: Int` property (stores `Interval.rawValue`)
  - [x] Add `var tuningSystem: String` property (stores coded `TuningSystem` identifier)
  - [x] Update `init` to accept new parameters
  - [x] Write tests for record creation with new fields
- [x] Task 2: Add `targetNote`, `interval`, and `tuningSystem` to `PitchMatchingRecord` (AC: #2)
  - [x] Add `var targetNote: Int` property (stores `MIDINote.rawValue`)
  - [x] Add `var interval: Int` property
  - [x] Add `var tuningSystem: String` property
  - [x] Update `init` to accept new parameters
  - [x] Write tests for record creation with new fields
- [x] Task 3: Add `tuningSystem` to `CompletedComparison` (AC: #4)
  - [x] Add `let tuningSystem: TuningSystem` property
  - [x] Update `init` to accept `tuningSystem` parameter
  - [x] Write tests
- [x] Task 4: Add `targetNote` to `PitchMatchingChallenge` (AC: #5)
  - [x] Add `let targetNote: MIDINote` property
  - [x] Write tests verifying unison: `targetNote == referenceNote`
- [x] Task 5: Add `targetNote` and `tuningSystem` to `CompletedPitchMatching` (AC: #6)
  - [x] Add `let targetNote: MIDINote` property
  - [x] Add `let tuningSystem: TuningSystem` property
  - [x] Update `init` to accept new parameters
  - [x] Write tests
- [x] Task 6: Update `TrainingDataStore` observer conformances (AC: #1, #2, #4, #6)
  - [x] Update `ComparisonObserver` conformance to map `tuningSystem` to record
  - [x] Update `PitchMatchingObserver` conformance to map `targetNote`, `interval`, `tuningSystem` to record
  - [x] Write tests with in-memory `ModelContainer`
- [x] Task 7: Update all call sites that create these types (AC: #3, #4, #5, #6)
  - [x] Update `ComparisonSession` where it creates `CompletedComparison` — pass `tuningSystem`
  - [x] Update `PitchMatchingSession` where it creates `PitchMatchingChallenge` — pass `targetNote`
  - [x] Update `PitchMatchingSession` where it creates `CompletedPitchMatching` — pass `targetNote` and `tuningSystem`
  - [x] For now, all call sites use `.prime` and `.equalTemperament` (existing unison behavior)
- [x] Task 8: Update mocks and test fixtures (AC: all)
  - [x] Update `MockTrainingDataStore` or any test helpers
  - [x] Ensure all existing tests pass with new required parameters
- [x] Task 9: Confirm `Comparison` shape is already correct (AC: #3)
  - [x] Verify `Comparison` has `referenceNote: MIDINote` and `targetNote: DetunedMIDINote`
  - [x] No code changes needed — just explicit confirmation in commit message
- [x] Task 10: Run full test suite and commit (AC: all)

## Dev Notes

### Current State of Each Type (Read These Files First)

| Type | File | Current Properties |
|------|------|--------------------|
| `ComparisonRecord` | `Peach/Core/Data/ComparisonRecord.swift` | `referenceNote: Int`, `targetNote: Int`, `centOffset: Double`, `isCorrect: Bool`, `timestamp: Date` |
| `PitchMatchingRecord` | `Peach/Core/Data/PitchMatchingRecord.swift` | `referenceNote: Int`, `initialCentOffset: Double`, `userCentError: Double`, `timestamp: Date` |
| `Comparison` | `Peach/Core/Training/Comparison.swift` | `referenceNote: MIDINote`, `targetNote: DetunedMIDINote` — **already correct, no changes** |
| `CompletedComparison` | `Peach/Core/Training/Comparison.swift` | `comparison: Comparison`, `userAnsweredHigher: Bool`, `timestamp: Date` — **needs `tuningSystem`** |
| `CompletedPitchMatching` | `Peach/Core/Training/CompletedPitchMatching.swift` | `referenceNote: MIDINote`, `initialCentOffset: Double`, `userCentError: Double`, `timestamp: Date` — **needs `targetNote`, `tuningSystem`** |
| `PitchMatchingChallenge` | `Peach/PitchMatching/PitchMatchingChallenge.swift` | `referenceNote: MIDINote`, `initialCentOffset: Double` — **needs `targetNote`** |
| `TrainingDataStore` | `Peach/Core/Data/TrainingDataStore.swift` | Observer conformances map domain → record — **must update both** |

### SwiftData Storage Pattern (Critical)

SwiftData `@Model` types store **raw primitives only** — not domain types. The conversion between domain types and `@Model` records happens in `TrainingDataStore`'s observer conformances.

**Storage mapping for new fields:**
- `Interval` → store as `Int` (its `rawValue` — semitone count). Reconstruct: `Interval(rawValue: storedInt)!`
- `TuningSystem` → store as `String`. Since `TuningSystem` is a `Codable` enum, use a stable string identifier. Pattern: `"equalTemperament"`. Reconstruct: decode from string. **Implementation choice:** Add a `storageIdentifier: String` computed property on `TuningSystem` and a `init?(storageIdentifier:)` failable initializer (or use a simple `switch`). This is cleaner than JSON-encoding a single enum value.
- `MIDINote` → store as `Int` (its `rawValue`). Already used for `referenceNote`/`targetNote` in `ComparisonRecord`.

**Do NOT:**
- Store domain types directly in `@Model` classes — SwiftData cannot handle custom value types as stored properties
- Use `Codable` encoding (JSON) for simple enum storage — a string identifier is simpler and queryable
- Add `import SwiftData` to any file outside `Core/Data/` and `App/`

### Observer Conformance Updates (TrainingDataStore)

**Current `ComparisonObserver` conformance** (line 130-153 of `TrainingDataStore.swift`):
```swift
func comparisonCompleted(_ completed: CompletedComparison) {
    let comparison = completed.comparison
    let record = ComparisonRecord(
        referenceNote: comparison.referenceNote.rawValue,
        targetNote: comparison.targetNote.note.rawValue,
        centOffset: comparison.targetNote.offset.rawValue,
        isCorrect: completed.isCorrect,
        timestamp: completed.timestamp
    )
    // ... save
}
```
**Must add:** `interval` and `tuningSystem` mapping. The `interval` can be derived from `comparison.referenceNote` and `comparison.targetNote.note` via `Interval.between()`, **but** the AC says to store it explicitly. Get it from `CompletedComparison` which will carry it (propagated from session). The `tuningSystem` comes from the new `CompletedComparison.tuningSystem` field.

**Current `PitchMatchingObserver` conformance** (line 109-126):
```swift
func pitchMatchingCompleted(_ result: CompletedPitchMatching) {
    let record = PitchMatchingRecord(
        referenceNote: result.referenceNote.rawValue,
        initialCentOffset: result.initialCentOffset,
        userCentError: result.userCentError,
        timestamp: result.timestamp
    )
    // ... save
}
```
**Must add:** `targetNote`, `interval`, `tuningSystem` mapping from `CompletedPitchMatching`.

### Where `interval` Comes From in CompletedComparison

`CompletedComparison` wraps a `Comparison`, which has `referenceNote: MIDINote` and `targetNote: DetunedMIDINote`. The interval is derivable: `Interval.between(comparison.referenceNote, comparison.targetNote.note)`. However, the AC says to store it explicitly for efficient querying. **The cleanest approach:** `CompletedComparison` does NOT need a separate `interval` field — derive it when constructing the `ComparisonRecord` in `TrainingDataStore`. This avoids redundancy in the domain type while satisfying the "store explicitly" requirement at the persistence level.

Alternatively, if future stories need `interval` on `CompletedComparison`, add it now. **Decision: derive in TrainingDataStore** — the AC is about `ComparisonRecord` having `interval`, not about `CompletedComparison` having it. Keep domain types lean.

### Call Sites That Create These Types

**`CompletedComparison`** — created in `ComparisonSession`. Search for `CompletedComparison(` to find the exact location. Must add `tuningSystem` parameter. For current unison behavior, pass `.equalTemperament`.

**`PitchMatchingChallenge`** — created in `PitchMatchingSession`. Search for `PitchMatchingChallenge(` to find the exact location. Must add `targetNote` parameter. For current unison behavior, pass `referenceNote` (i.e., `targetNote == referenceNote`).

**`CompletedPitchMatching`** — created in `PitchMatchingSession`. Search for `CompletedPitchMatching(` to find the exact location. Must add `targetNote` and `tuningSystem` parameters. For current unison behavior, pass `referenceNote` and `.equalTemperament`.

### Hardcoded Unison Values for Now

Story 23.1 only updates data models — it does NOT change training behavior. All call sites should pass:
- `interval: .prime` (or derive from reference/target which are identical for unison)
- `tuningSystem: .equalTemperament`
- `targetNote: referenceNote` (for pitch matching types)

Stories 23.2 and 23.3 will parameterize the sessions to accept actual intervals.

### TuningSystem Storage Strategy

`TuningSystem` is an enum with one case (`equalTemperament`) and `Codable` conformance. For SwiftData storage:

```swift
// On TuningSystem (in Core/Audio/TuningSystem.swift):
var storageIdentifier: String {
    switch self {
    case .equalTemperament: return "equalTemperament"
    }
}

static func fromStorageIdentifier(_ id: String) -> TuningSystem? {
    switch id {
    case "equalTemperament": return .equalTemperament
    default: return nil
    }
}
```

Place this extension in `TuningSystem.swift` since it's a domain type method, not a SwiftData concern. `TrainingDataStore` calls these when converting.

### No Migration Plan

Per AC #7 and the epics: no production user base exists, so a fresh schema version is acceptable. SwiftData will recreate the store on schema mismatch. No `SchemaMigrationPlan`, no `VersionedSchema`.

### ModelContainer Registration

`PeachApp.swift` line 21: `ModelContainer(for: ComparisonRecord.self, PitchMatchingRecord.self)`. No changes needed — the same model types are registered, they just have more properties.

### Project Structure Notes

All changes stay within established directories:
- `Peach/Core/Data/` — `ComparisonRecord.swift`, `PitchMatchingRecord.swift`, `TrainingDataStore.swift`
- `Peach/Core/Training/` — `Comparison.swift` (contains `CompletedComparison`), `CompletedPitchMatching.swift`
- `Peach/Core/Audio/` — `TuningSystem.swift` (storage identifier extension)
- `Peach/PitchMatching/` — `PitchMatchingChallenge.swift`
- `Peach/Comparison/` or wherever `ComparisonSession` lives — call site updates
- `Peach/PitchMatching/` — wherever `PitchMatchingSession` creates challenges/completions
- Test files mirror source structure in `PeachTests/`

No new files needed. No new directories. No cross-feature coupling introduced.

### Testing Strategy

- **SwiftData tests:** Use in-memory `ModelContainer` (`ModelConfiguration(isStoredInMemoryOnly: true)`) to verify records save and load with new fields
- **Value type tests:** Verify new properties exist and are populated correctly
- **Observer tests:** Verify `TrainingDataStore` maps all new fields from domain types to records
- **Regression:** All existing tests must pass — new parameters with default unison values ensure backward compatibility
- **TDD workflow:** Write failing tests first for each new field, then implement
- **Run full suite:** `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`

### References

- [Source: docs/planning-artifacts/epics.md#Story 23.1] — Full acceptance criteria
- [Source: docs/planning-artifacts/epics.md#Epic 23] — Epic context and all stories overview
- [Source: docs/planning-artifacts/architecture.md] — Two-world architecture, SwiftData patterns
- [Source: docs/project-context.md#SwiftData] — Only `TrainingDataStore` accesses SwiftData, primitives in `@Model`
- [Source: docs/project-context.md#Testing Rules] — Swift Testing, in-memory containers, TDD
- [Source: docs/project-context.md#Critical Don't-Miss Rules] — Domain rules, TuningSystem.frequency bridge
- [Source: docs/implementation-artifacts/22-5-extract-soundsourceprovider-protocol.md] — Previous story learnings
- [Source: Peach/Core/Data/TrainingDataStore.swift] — Observer conformances to update
- [Source: Peach/Core/Audio/Interval.swift] — `Interval` enum, raw value is `Int`, `Codable`
- [Source: Peach/Core/Audio/TuningSystem.swift] — `TuningSystem` enum, `Codable`, frequency bridge

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

No debug issues encountered. All tasks completed cleanly.

### Completion Notes List

- Added `interval: Int` and `tuningSystem: String` fields to `ComparisonRecord` SwiftData model
- Added `targetNote: Int`, `interval: Int`, and `tuningSystem: String` fields to `PitchMatchingRecord` SwiftData model
- Added `tuningSystem: TuningSystem` to `CompletedComparison` value type
- Added `targetNote: MIDINote` to `PitchMatchingChallenge` value type
- Added `targetNote: MIDINote` and `tuningSystem: TuningSystem` to `CompletedPitchMatching` value type
- Added `storageIdentifier` and `fromStorageIdentifier` to `TuningSystem` for SwiftData storage conversion
- Updated `TrainingDataStore` observer conformances to derive interval via `Interval.between()` and map tuningSystem via `storageIdentifier`
- Updated `ComparisonSession` to pass `.equalTemperament` when creating `CompletedComparison`
- Updated `PitchMatchingSession` to pass `targetNote: note` (unison) and `.equalTemperament` for challenge and completion types
- Updated `MockTrainingDataStore` with new field mappings
- Updated all test fixtures (20+ files) with new required parameters using unison defaults
- Confirmed `Comparison` shape is already correct (`referenceNote: MIDINote`, `targetNote: DetunedMIDINote`)
- No migration plan needed (no production user base)
- All tests pass, dependency checks pass

### File List

- Peach/Core/Data/ComparisonRecord.swift (modified: added `interval`, `tuningSystem` fields)
- Peach/Core/Data/PitchMatchingRecord.swift (modified: added `targetNote`, `interval`, `tuningSystem` fields)
- Peach/Core/Training/Comparison.swift (modified: added `tuningSystem` to `CompletedComparison`)
- Peach/Core/Training/CompletedPitchMatching.swift (modified: added `targetNote`, `tuningSystem`)
- Peach/PitchMatching/PitchMatchingChallenge.swift (modified: added `targetNote`)
- Peach/Core/Audio/TuningSystem.swift (modified: added `storageIdentifier`, `fromStorageIdentifier`)
- Peach/Core/Data/TrainingDataStore.swift (modified: updated observer conformances for new fields)
- Peach/Comparison/ComparisonSession.swift (modified: pass `tuningSystem: .equalTemperament`)
- Peach/PitchMatching/PitchMatchingSession.swift (modified: pass `targetNote`, `tuningSystem`)
- Peach/Profile/ThresholdTimelineView.swift (modified: preview ComparisonRecord updated)
- Peach/Profile/ProfileScreen.swift (modified: preview ComparisonRecord updated)
- Peach/Profile/SummaryStatisticsView.swift (modified: preview ComparisonRecord updated)
- Peach/Start/ProfilePreviewView.swift (modified: preview ComparisonRecord updated)
- PeachTests/Comparison/MockTrainingDataStore.swift (modified: updated observer methods)
- PeachTests/Core/Data/TrainingDataStoreTests.swift (modified: updated all record calls)
- PeachTests/Core/Data/TrainingDataStoreEdgeCaseTests.swift (modified: updated all record calls)
- PeachTests/Core/Data/PitchMatchingRecordTests.swift (modified: updated all record calls)
- PeachTests/Core/Training/ComparisonTests.swift (modified: added `tuningSystem` to CompletedComparison)
- PeachTests/Core/Profile/ThresholdTimelineTests.swift (modified: updated record and completed calls)
- PeachTests/Core/Profile/PitchMatchingProfileTests.swift (modified: updated CompletedPitchMatching call)
- PeachTests/Core/Algorithm/KazezNoteStrategyTests.swift (modified: added `tuningSystem` to CompletedComparison)
- PeachTests/Profile/TrendAnalyzerTests.swift (modified: updated record and completed calls)
- PeachTests/Profile/ProfileScreenLayoutTests.swift (modified: updated ComparisonRecord calls)
- PeachTests/Start/ProfilePreviewViewTests.swift (modified: updated ComparisonRecord calls)
- PeachTests/Comparison/ComparisonSessionResetTests.swift (modified: updated ComparisonRecord calls)
- PeachTests/Comparison/ComparisonSessionIntegrationTests.swift (modified: updated ComparisonRecord calls)
- PeachTests/Settings/SettingsTests.swift (modified: updated record calls)
- docs/implementation-artifacts/23-1-data-model-and-value-type-updates-for-interval-context.md (modified: status, tasks, dev record)
- docs/implementation-artifacts/sprint-status.yaml (modified: story status)

## Change Log

- 2026-03-01: Implemented story 23.1 — added interval and tuning system context fields to all data models and value types for interval training support
