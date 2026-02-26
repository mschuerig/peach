# Story 19.2: Value Objects for Domain Primitives

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want naked primitive types (Int, Double, UInt8, Float) wrapped in validated domain-specific Value Objects,
So that MIDI note ranges, cent values, frequencies, velocities, and amplitudes are enforced at compile time and the code communicates intent clearly.

## Acceptance Criteria

1. **`MIDINote` value type exists** -- A `struct MIDINote` validated to 0–127, with `.rawValue: Int`, `.name` (e.g., "A4"), `.frequency(referencePitch:)`, `Comparable`, `Hashable`, `Codable`, `ExpressibleByIntegerLiteral`. Lives in `Peach/Core/Audio/`.

2. **`MIDIVelocity` value type exists** -- A `struct MIDIVelocity` validated to 1–127, with `.rawValue: UInt8`, `ExpressibleByIntegerLiteral`.

3. **`Cents` value type exists** -- A `struct Cents` wrapping a signed `Double`, with `.rawValue: Double`, `.magnitude: Double`, `Comparable`, `ExpressibleByFloatLiteral`, `ExpressibleByIntegerLiteral`.

4. **`Frequency` value type exists** -- A `struct Frequency` wrapping a positive `Double`, with `.rawValue: Double`, `ExpressibleByFloatLiteral`, `ExpressibleByIntegerLiteral`.

5. **`AmplitudeDB` value type exists** -- A `struct AmplitudeDB` wrapping `Float`, auto-clamped to `-90.0...12.0` (using the named constant from Story 19.1), `ExpressibleByFloatLiteral`, `ExpressibleByIntegerLiteral`.

6. **Protocol and session signatures updated** -- `NotePlayer.play()` takes `Frequency`, `MIDIVelocity`, `AmplitudeDB`. `PitchDiscriminationProfile` and `PitchMatchingProfile` methods take `MIDINote` and `Cents` where appropriate. `PlaybackHandle.adjustFrequency()` takes `Frequency`.

7. **`Comparison` redesigned** -- `note1` and `note2` are `MIDINote`. `centDifference` is signed `Cents`. `isSecondNoteHigher` is a computed property (`centDifference.rawValue > 0`). The `isSecondNoteHigher` stored property is removed.

8. **Strategy methods produce signed `Cents`** -- `NextComparisonStrategy.nextComparison()` returns `Comparison` with signed `centDifference`. Direction (positive = second note higher) is randomly chosen by the strategy. `TrainingSettings` uses `MIDINote` for range and `Cents` for difficulty bounds.

9. **SwiftData models keep raw types** -- `ComparisonRecord` and `PitchMatchingRecord` retain `Int` and `Double` storage to avoid SwiftData migration. Conversion happens at boundaries: `.rawValue` when writing, `MIDINote(record.field)` when reading.

10. **Value Object types have unit tests** -- Each new value type has its own test file covering: valid construction, boundary validation, `ExpressibleByLiteral` conformance, and relevant computed properties.

11. **All existing tests pass** -- Full test suite passes with zero regressions. Test code updated to use new types where necessary.

## Tasks / Subtasks

- [ ] Task 1: Create value type files (AC: #1, #2, #3, #4, #5)
  - [ ] Create `Peach/Core/Audio/MIDINote.swift` — validated 0–127, `.name`, `.frequency()`, `.random(in:)`, Comparable, Hashable, Codable, ExpressibleByIntegerLiteral
  - [ ] Create `Peach/Core/Audio/MIDIVelocity.swift` — validated 1–127, ExpressibleByIntegerLiteral
  - [ ] Create `Peach/Core/Audio/Cents.swift` — signed Double wrapper, `.magnitude`, Comparable, ExpressibleByFloatLiteral + IntegerLiteral
  - [ ] Create `Peach/Core/Audio/Frequency.swift` — positive Double, ExpressibleByFloatLiteral + IntegerLiteral
  - [ ] Create `Peach/Core/Audio/AmplitudeDB.swift` — Float clamped to dB range, ExpressibleByFloatLiteral + IntegerLiteral
  - [ ] All `init` methods marked `nonisolated` (required for ExpressibleByLiteral under default MainActor isolation)
  - [ ] All `static let` range properties marked `nonisolated(unsafe)` (required despite SourceKit warning for Sendable types)

- [ ] Task 2: Update `Comparison` struct (AC: #7)
  - [ ] Change `note1: Int` → `note1: MIDINote`
  - [ ] Change `note2: Int` → `note2: MIDINote`
  - [ ] Change `centDifference: Double` → `centDifference: Cents` (signed)
  - [ ] Remove stored `isSecondNoteHigher: Bool`, replace with computed property: `var isSecondNoteHigher: Bool { centDifference.rawValue > 0 }`
  - [ ] Update `note1Frequency` / `note2Frequency` to use `.rawValue` when calling FrequencyCalculation

- [ ] Task 3: Update `NotePlayer` protocol and implementations (AC: #6)
  - [ ] `NotePlayer.play(frequency:velocity:amplitudeDB:)` → takes `Frequency`, `MIDIVelocity`, `AmplitudeDB`
  - [ ] `NotePlayer.play(frequency:duration:velocity:amplitudeDB:)` → same type changes
  - [ ] `PlaybackHandle.adjustFrequency(_:)` → takes `Frequency`
  - [ ] `SoundFontNotePlayer` — extract `.rawValue` before passing to AVAudioUnitSampler
  - [ ] `SoundFontPlaybackHandle` — extract `.rawValue` before passing to FrequencyCalculation

- [ ] Task 4: Update `FrequencyCalculation` (AC: #6)
  - [ ] Keep internal math using raw `Double`/`Int` — callers wrap/unwrap at boundaries
  - [ ] OR update signatures to accept/return Value Objects (design decision — see Dev Notes)

- [ ] Task 5: Update profile protocols and `PerceptualProfile` (AC: #6)
  - [ ] `PitchDiscriminationProfile.update(note:centOffset:isCorrect:)` — `note: MIDINote`
  - [ ] `PitchDiscriminationProfile.setDifficulty(note:difficulty:)` — `note: MIDINote`
  - [ ] `PitchDiscriminationProfile.weakSpots()` → returns `[MIDINote]`
  - [ ] `PitchDiscriminationProfile.statsForNote(_:)` — takes `MIDINote`
  - [ ] `PitchMatchingProfile.updateMatching(note:centError:)` — `note: MIDINote`
  - [ ] `PerceptualProfile` implementation — use `.rawValue` for internal array indexing

- [ ] Task 6: Update `TrainingSettings` and strategies (AC: #8)
  - [ ] `TrainingSettings.noteRangeMin/Max` → `MIDINote`
  - [ ] `TrainingSettings.minCentDifference/maxCentDifference` → `Cents`
  - [ ] `KazezNoteStrategy` — produce signed `Cents` with random direction
  - [ ] `AdaptiveNoteStrategy` — produce signed `Cents` with random direction
  - [ ] Ensure `CompletedComparison` uses the new types

- [ ] Task 7: Update `ComparisonSession` (AC: #6, #8)
  - [ ] Wrap `Frequency(...)` when calling `comparison.note1Frequency()`
  - [ ] Use `MIDIVelocity` for velocity constant
  - [ ] Use `AmplitudeDB` for amplitude calculations
  - [ ] Update `currentSettings` to construct `MIDINote` from UserDefaults Int values

- [ ] Task 8: Update `PitchMatchingSession` (AC: #6)
  - [ ] Use `MIDINote.random(in:)` for challenge generation
  - [ ] Wrap `Frequency(...)` when calling FrequencyCalculation
  - [ ] Use `MIDIVelocity` and `AmplitudeDB` for playback calls

- [ ] Task 9: Update data store boundary (AC: #9)
  - [ ] `TrainingDataStore.comparisonCompleted()` — extract `.rawValue` from Value Objects before writing to `ComparisonRecord`
  - [ ] `TrainingDataStore.pitchMatchingCompleted()` — extract `.rawValue` before writing to `PitchMatchingRecord`
  - [ ] `PeachApp.swift` profile loading — wrap `MIDINote(record.note1)` when reading from records
  - [ ] `ComparisonRecord` and `PitchMatchingRecord` — NO changes to @Model stored properties

- [ ] Task 10: Update observers (AC: #6)
  - [ ] `TrendAnalyzer.comparisonCompleted()` — use `.centDifference.magnitude` for unsigned threshold
  - [ ] `ThresholdTimeline.comparisonCompleted()` — use `.centDifference.magnitude` and `.note1.rawValue`
  - [ ] `HapticFeedbackManager` — if it references comparison types

- [ ] Task 11: Update view files (AC: #6)
  - [ ] `ComparisonScreen.swift` — update preview mock NotePlayer signatures
  - [ ] `PitchMatchingScreen.swift` — update preview mock NotePlayer signatures
  - [ ] `ProfileScreen.swift` — use `MIDINote(note)` in preview data population
  - [ ] `SummaryStatisticsView.swift` — use `MIDINote($0)` in `computeStats`
  - [ ] `PianoKeyboardView.swift` — wrap MIDI range values if needed

- [ ] Task 12: Update all test mocks (AC: #11)
  - [ ] `MockNotePlayer` — update `play()` signature to accept Value Objects, store `.rawValue` internally
  - [ ] `MockNextComparisonStrategy` — default Comparison uses `MIDINote` and `Cents`
  - [ ] `MockTrainingDataStore` — extract `.rawValue` for stored records
  - [ ] `MockPitchMatchingProfile` — `updateMatching(note: MIDINote, ...)`
  - [ ] `ComparisonTestHelpers` — default comparisons use signed `Cents`

- [ ] Task 13: Update all test files (AC: #11)
  - [ ] Replace `isSecondNoteHigher: true/false` with signed `Cents(100.0)` / `Cents(-100.0)`
  - [ ] Replace `.centDifference` comparisons with `.centDifference.magnitude` where unsigned value expected
  - [ ] Replace `.note1 >= X` with `.note1.rawValue >= X` for range checks
  - [ ] Wrap loop variables: `for note in 0..<128 { profile.update(note: MIDINote(note), ...) }`
  - [ ] Integer literals in `Comparison(note1: 60, ...)` work via `ExpressibleByIntegerLiteral` — no wrapping needed
  - [ ] Test `UserDefaults` comparisons: `.noteRangeMin.rawValue == SettingsKeys.defaultNoteRangeMin`

- [ ] Task 14: Write Value Object unit tests (AC: #10)
  - [ ] Create `PeachTests/Core/Audio/MIDINoteTests.swift`
  - [ ] Create `PeachTests/Core/Audio/CentsTests.swift`
  - [ ] Create `PeachTests/Core/Audio/FrequencyTests.swift`
  - [ ] Create `PeachTests/Core/Audio/MIDIVelocityTests.swift`
  - [ ] Create `PeachTests/Core/Audio/AmplitudeDBTests.swift`

- [ ] Task 15: Run full test suite and verify (AC: #11)
  - [ ] Run `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] All existing tests pass plus new Value Object tests
  - [ ] Zero regressions

## Dev Notes

### Critical Design Decisions

- **`nonisolated init` is mandatory on all value types** -- Under Swift 6.2 default MainActor isolation, `ExpressibleByIntegerLiteral` and `ExpressibleByFloatLiteral` require `nonisolated init(integerLiteral:)` / `init(floatLiteral:)`. The primary `init` must also be `nonisolated` since the literal inits call it.
- **`nonisolated(unsafe)` on `static let` validation ranges** -- Despite SourceKit flagging this as "unnecessary" for Sendable types, the actual Swift 6.2 compiler rejects `nonisolated init` accessing a `static let` without this annotation. Apply it and suppress the warning.
- **`ExpressibleByLiteral` only works with literal values** -- `MIDINote` can be initialized as `let n: MIDINote = 60` (literal), but `let i = 60; let n: MIDINote = i` fails. Loop variables (`for i in 0..<128`) require explicit `MIDINote(i)` wrapping. This is the main source of test code churn.
- **`Comparison.centDifference` becomes signed** -- Positive = second note higher, negative = second note lower. `isSecondNoteHigher` becomes a computed property. This is a semantic improvement: strategies produce a single signed value instead of separate magnitude + direction.
- **Strategies produce random direction** -- Both `KazezNoteStrategy` and `AdaptiveNoteStrategy` determine the cent difference magnitude via their algorithm, then randomly negate it (50/50 chance). Test assertions on difficulty must use `.centDifference.magnitude`.
- **SwiftData @Model types keep raw primitives** -- `ComparisonRecord.note1` stays `Int`, `PitchMatchingRecord.referenceNote` stays `Int`. Wrapping at boundaries: `.rawValue` when storing, `MIDINote(record.note1)` when loading. This avoids SwiftData schema migration.
- **`FrequencyCalculation` keeps raw signatures** -- The math functions use `Double` and `Int` internally. Callers are responsible for unwrapping (`.rawValue`) and wrapping (`Frequency(result)`). This keeps the calculation pure and avoids circular dependencies between Value Objects and calculation utilities.
- **`Cents` for `centOffset` but NOT for `difficulty`** -- Profile methods like `update(note:centOffset:)` use `Double` for centOffset because cent offsets in the profile context are absolute thresholds, not signed pitch differences. Only `Comparison.centDifference` and strategy outputs use `Cents`. Consider whether `difficulty` in `setDifficulty` should also remain `Double`. (Design decision to make during implementation.)

### Architecture & Integration

**New files (5 value types + 5 test files):**
- `Peach/Core/Audio/MIDINote.swift`
- `Peach/Core/Audio/MIDIVelocity.swift`
- `Peach/Core/Audio/Cents.swift`
- `Peach/Core/Audio/Frequency.swift`
- `Peach/Core/Audio/AmplitudeDB.swift`
- `PeachTests/Core/Audio/MIDINoteTests.swift`
- `PeachTests/Core/Audio/CentsTests.swift`
- `PeachTests/Core/Audio/FrequencyTests.swift`
- `PeachTests/Core/Audio/MIDIVelocityTests.swift`
- `PeachTests/Core/Audio/AmplitudeDBTests.swift`

**Modified production files (15+):**
- `Peach/Comparison/Comparison.swift`
- `Peach/Comparison/ComparisonSession.swift`
- `Peach/Core/Audio/NotePlayer.swift`
- `Peach/Core/Audio/PlaybackHandle.swift`
- `Peach/Core/Audio/SoundFontNotePlayer.swift`
- `Peach/Core/Audio/SoundFontPlaybackHandle.swift`
- `Peach/Core/Profile/PitchDiscriminationProfile.swift`
- `Peach/Core/Profile/PitchMatchingProfile.swift`
- `Peach/Core/Profile/PerceptualProfile.swift`
- `Peach/Core/Profile/TrendAnalyzer.swift`
- `Peach/Core/Profile/ThresholdTimeline.swift`
- `Peach/Core/Algorithm/NextComparisonStrategy.swift` (TrainingSettings)
- `Peach/Core/Algorithm/KazezNoteStrategy.swift`
- `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift`
- `Peach/Core/Data/TrainingDataStore.swift`
- `Peach/PitchMatching/PitchMatchingSession.swift`
- `Peach/PitchMatching/PitchMatchingChallenge.swift`
- `Peach/App/PeachApp.swift`
- `Peach/Settings/SettingsKeys.swift`

**Modified view files:**
- `Peach/Comparison/ComparisonScreen.swift` (preview mocks)
- `Peach/PitchMatching/PitchMatchingScreen.swift` (preview mocks)
- `Peach/Profile/ProfileScreen.swift` (preview data)
- `Peach/Profile/SummaryStatisticsView.swift` (MIDINote wrapping in computeStats)

**Modified test files (10+):**
- All Comparison test files (constructor changes for signed Cents)
- All Strategy test files (.magnitude for assertions)
- Profile test files (MIDINote wrapping for loop variables)
- All mock files (signature updates)

**NOT modified:**
- `ComparisonRecord.swift`, `PitchMatchingRecord.swift` (SwiftData — raw types stay)
- `FrequencyCalculation.swift` (raw types — callers wrap/unwrap)
- `SF2PresetParser.swift` (separate concern)
- `VerticalPitchSlider.swift` (Story 19.5)

### Key Implementation Patterns

```swift
// Value type pattern (all 5 follow this structure):
struct MIDINote: Hashable, Comparable, Codable, Sendable {
    nonisolated(unsafe) static let validRange = 0...127
    let rawValue: Int

    nonisolated init(_ rawValue: Int) {
        precondition(Self.validRange.contains(rawValue), "MIDI note must be 0-127, got \(rawValue)")
        self.rawValue = rawValue
    }
}

// ExpressibleByIntegerLiteral (on MIDINote, MIDIVelocity, Cents, Frequency, AmplitudeDB):
extension MIDINote: ExpressibleByIntegerLiteral {
    nonisolated init(integerLiteral value: Int) { self.init(value) }
}

// Signed Cents in strategies:
let magnitude = algorithm.computeDifficulty(...)
let signed = Bool.random() ? magnitude : -magnitude
return Comparison(note1: selectedNote, note2: selectedNote, centDifference: Cents(signed))

// SwiftData boundary:
// Writing:
let record = ComparisonRecord(
    note1: comparison.note1.rawValue,
    note2: comparison.note2.rawValue,
    note2CentOffset: comparison.centDifference.rawValue,  // signed, stored directly
    isCorrect: isCorrect
)
// Reading:
profile.update(note: MIDINote(record.note1), centOffset: abs(record.note2CentOffset), isCorrect: record.isCorrect)
```

### Testing Approach

- **New test files (5):** One per Value Object, testing construction, boundary validation, literal conformance, computed properties
- **Existing test updates:** Replace `isSecondNoteHigher:` with signed `Cents`, use `.magnitude` for assertions, wrap loop variables with `MIDINote()`
- **Common pitfall:** `for note in [30, 60, 90]` creates `[Int]` by default — use `for note: MIDINote in [30, 60, 90]` or `for note in [30, 60, 90] { profile.update(note: MIDINote(note), ...) }`
- **`#expect(comparison.centDifference.magnitude == 100.0)`** — strategies produce random sign, so test the absolute value
- **UserDefaults comparisons:** `#expect(settings.noteRangeMin.rawValue == SettingsKeys.defaultNoteRangeMin)`

### Previous Story Learnings (from 19.1 and earlier)

- **`nonisolated` is mandatory for value type inits** — discovered during 19.1 clamping extension and confirmed across multiple value types. Every `init` and `static let` on value types needs explicit opt-out from MainActor isolation.
- **Test file naming mirrors source structure** — `Peach/Core/Audio/MIDINote.swift` → `PeachTests/Core/Audio/MIDINoteTests.swift`
- **Clamping utility from 19.1 available** — `AmplitudeDB` can use `.clamped(to:)` in its init.

### Risk Assessment

- **Largest story in the epic** — touches 25+ files. Recommend implementing in waves: (1) create value types with tests, (2) update protocols and core types, (3) update sessions and strategies, (4) update views and test mocks, (5) fix remaining test compilation errors.
- **Build errors cascade** — a type change in a protocol propagates to all implementations and callers. Expect many compiler errors after changing `NotePlayer`. Work through them file by file.
- **Random sign in strategies may break assertions** — any test that previously asserted `centDifference == 100.0` must now use `.magnitude` since strategies randomly negate.

### Git Intelligence

Recent commit pattern: `Implement story X.Y: {description}`
Commit message: `Implement story 19.2: Value Objects for domain primitives`

### Project Structure Notes

- Value type files go in `Peach/Core/Audio/` alongside `FrequencyCalculation.swift`
- Test files go in `PeachTests/Core/Audio/`
- No new directories needed
- Do NOT create `Peach/Core/Types/` or similar — audio value types belong in `Core/Audio/`

### References

- [Source: docs/project-context.md -- Type Design rules, Testing Rules, Critical Don't-Miss Rules]
- [Source: Peach/Core/Audio/NotePlayer.swift -- Protocol to update]
- [Source: Peach/Core/Audio/PlaybackHandle.swift -- Protocol to update]
- [Source: Peach/Comparison/Comparison.swift -- Struct to redesign]
- [Source: Peach/Core/Algorithm/NextComparisonStrategy.swift -- TrainingSettings struct]
- [Source: Peach/Core/Profile/PitchDiscriminationProfile.swift -- Protocol to update]
- [Source: Peach/Core/Profile/PitchMatchingProfile.swift -- Protocol to update]
- [Source: Peach/Core/Data/ComparisonRecord.swift -- SwiftData model, keep raw types]
- [Source: Peach/Core/Data/PitchMatchingRecord.swift -- SwiftData model, keep raw types]
- [Source: docs/implementation-artifacts/19-1-clamping-utility-and-magic-value-constants.md -- Prerequisite story]

## Change Log

- 2026-02-26: Story created by BMAD create-story workflow from Epic 19 code review plan.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
