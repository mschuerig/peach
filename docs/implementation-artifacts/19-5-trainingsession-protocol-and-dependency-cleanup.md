# Story 19.5: TrainingSession Protocol and Dependency Cleanup

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want `ContentView` decoupled from concrete session types via a `TrainingSession` protocol, and `VerticalPitchSlider` simplified to produce normalized values instead of frequencies,
So that the view layer depends only on abstractions, components have single responsibilities, and the pitch domain logic lives entirely in `PitchMatchingSession`.

## Acceptance Criteria

1. **`TrainingSession` protocol defined** -- A protocol with `stop()` and `var isIdle: Bool { get }`. Both `ComparisonSession` and `PitchMatchingSession` conform.

2. **`ContentView` uses protocol, not concrete types** -- `handleAppBackgrounding()` calls `activeSession?.stop()` on a single `TrainingSession?` reference instead of checking two concrete session types. `ContentView` has no import or reference to `ComparisonSession` or `PitchMatchingSession`.

3. **Active session tracking** -- `PeachApp` tracks which session is currently active. When a session starts, it becomes the active session. When it stops, the active session is cleared. `ContentView` receives only the `activeSession: TrainingSession?` via environment.

4. **`VerticalPitchSlider` normalized API** -- The slider produces values in `-1.0...1.0` only. It no longer has `centRange`, `referenceFrequency`, `onFrequencyChange`, or `onRelease` parameters that reference pitch concepts. It exposes `onNormalizedValueChange: (Double) -> Void` and `onCommit: (Double) -> Void`.

5. **`PitchMatchingSession` owns pitch calculations** -- `PitchMatchingSession` converts the slider's normalized value to a frequency using cent range and reference frequency. `PitchMatchingScreen` passes the normalized callbacks to the slider and delegates conversion to the session.

6. **No `REVIEW:` comments remain on `ContentView.swift` or `VerticalPitchSlider.swift`** -- The code review comments about feature envy (ContentView:48) and slider domain knowledge (VerticalPitchSlider:3) are resolved and removed.

7. **All existing tests pass** -- Full test suite passes with zero regressions.

## Tasks / Subtasks

- [x] Task 1: Create `TrainingSession` protocol (AC: #1)
  - [x] Create `Peach/Core/TrainingSession.swift`
  - [x] Define `protocol TrainingSession: AnyObject` with `func stop()` and `var isIdle: Bool { get }`
  - [x] Add `ComparisonSession` conformance (already has `stop()` and state-based idle check)
  - [x] Add `PitchMatchingSession` conformance (already has `stop()` and state-based idle check)

- [x] Task 2: Implement active session tracking in `PeachApp` (AC: #3)
  - [x] Add `private var activeSession: TrainingSession?` property to `PeachApp`
  - [x] Observe `comparisonSession.state` changes — when transitioning away from idle, set as active session
  - [x] Observe `pitchMatchingSession.state` changes — when transitioning away from idle, set as active session
  - [x] When a new session becomes active, stop the previous active session first
  - [x] Inject `activeSession` into environment for `ContentView`

- [x] Task 3: Refactor `ContentView.handleAppBackgrounding()` (AC: #2, #6)
  - [x] Replace `comparisonSession` and `pitchMatchingSession` environment values with single `activeSession: TrainingSession?`
  - [x] Replace two concrete `if session.state != .idle { session.stop() }` blocks with `activeSession?.stop()`
  - [x] Remove REVIEW comment at line 48
  - [x] Remove `@Environment(\.comparisonSession)` and `@Environment(\.pitchMatchingSession)` from ContentView
  - [x] Add `@Environment(\.activeSession)` (new environment key)

- [x] Task 4: Normalize `VerticalPitchSlider` API (AC: #4, #6)
  - [x] Remove `centRange: Double` parameter
  - [x] Remove `referenceFrequency: Double` parameter
  - [x] Remove `onFrequencyChange: (Double) -> Void` callback
  - [x] Remove `onRelease: (Double) -> Void` callback
  - [x] Add `onNormalizedValueChange: (Double) -> Void` — called during drag with value in -1.0...1.0
  - [x] Add `onCommit: (Double) -> Void` — called on release with final normalized value
  - [x] Remove internal `centOffset(dragY:trackHeight:centRange:)` method (or simplify to normalized math)
  - [x] Remove internal `frequency(centOffset:referenceFrequency:)` method
  - [x] Keep `thumbPosition` logic but map from normalized value instead of cent offset
  - [x] Remove REVIEW comment at line 3
  - [x] Update accessibility actions to use normalized increments

- [x] Task 5: Move pitch calculations to `PitchMatchingSession` (AC: #5)
  - [x] Add `adjustNormalizedPitch(_ normalized: Double)` method — converts normalized → frequency → internal state
  - [x] Add `commitNormalizedPitch(_ normalized: Double)` method — converts and calls existing `commitResult()`
  - [x] The session knows `centRange` and `referenceFrequency` — it computes `centOffset = normalized * centRange` and `frequency = referenceFrequency * pow(2.0, centOffset / 1200.0)`

- [x] Task 6: Update `PitchMatchingScreen` to use new APIs (AC: #4, #5)
  - [x] Pass `onNormalizedValueChange:` → `pitchMatchingSession.adjustNormalizedPitch(_:)`
  - [x] Pass `onCommit:` → `pitchMatchingSession.commitNormalizedPitch(_:)`
  - [x] Remove `referenceFrequency:` and `centRange:` from slider construction

- [x] Task 7: Add environment key for `activeSession` (AC: #3)
  - [x] Add `@Entry var activeSession: TrainingSession? = nil` in EnvironmentValues extension
  - [x] Wire in `PeachApp.swift` body

- [x] Task 8: Update tests (AC: #7)
  - [x] Update `VerticalPitchSlider` tests to use normalized API (if layout tests exist)
  - [x] Update `PitchMatchingScreen` tests if any reference frequency/cent parameters
  - [x] Verify `ContentView` no longer needs session-specific test setup
  - [x] Add tests for `PitchMatchingSession.adjustNormalizedPitch()` and `commitNormalizedPitch()`

- [x] Task 9: Run full test suite and verify (AC: #7)
  - [x] Run `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [x] All tests pass, zero regressions

## Dev Notes

### Critical Design Decisions

- **`TrainingSession` is minimal** -- Only `stop()` and `isIdle`. No training-specific methods. The protocol exists solely for `ContentView` to stop whatever session is active without knowing what kind it is.
- **Active session is a single reference** -- Only one training mode can be active at a time. Starting comparison training stops pitch matching and vice versa. This is already the behavioral contract but was implicit; now it's explicit.
- **Observation approach for active session** -- PeachApp needs to know when sessions start/stop. Options: (1) sessions call a closure on start, (2) PeachApp polls state, (3) `@Observable` property observation. The cleanest approach is for `PeachApp` to use `withObservationTracking` or pass a callback. Design decision to make during implementation.
- **Slider becomes a pure UI component** -- `VerticalPitchSlider` no longer has any pitch domain knowledge. It's a generic vertical slider that maps a drag gesture to a normalized -1.0...1.0 value. This makes it reusable and testable without audio domain context.
- **Cent→frequency math moves to `PitchMatchingSession`** -- The formula `referenceFrequency * pow(2.0, centOffset / 1200.0)` moves from `VerticalPitchSlider.frequency()` to `PitchMatchingSession`. The session already knows the reference frequency and cent range.
- **`isActive` parameter stays on slider** -- The slider still needs to know if it's active (to enable/disable interaction). This comes from `pitchMatchingSession.state == .playingTunable`.

### Architecture & Integration

**New files:**
- `Peach/Core/TrainingSession.swift` (protocol)

**Modified production files:**
- `Peach/Comparison/ComparisonSession.swift` — add `TrainingSession` conformance
- `Peach/PitchMatching/PitchMatchingSession.swift` — add `TrainingSession` conformance, add normalized pitch methods
- `Peach/App/PeachApp.swift` — active session tracking, new environment value
- `Peach/App/ContentView.swift` — use `activeSession` protocol instead of concrete types
- `Peach/PitchMatching/VerticalPitchSlider.swift` — normalized API
- `Peach/PitchMatching/PitchMatchingScreen.swift` — pass normalized callbacks

**Modified test files:**
- `PeachTests/PitchMatching/VerticalPitchSliderTests.swift` (if exists) — update for normalized API
- `PeachTests/PitchMatching/PitchMatchingSessionTests.swift` — add tests for normalized pitch methods

### VerticalPitchSlider API Transformation

```swift
// BEFORE:
VerticalPitchSlider(
    isActive: pitchMatchingSession.state == .playingTunable,
    referenceFrequency: pitchMatchingSession.referenceFrequency ?? 440.0,
    onFrequencyChange: { frequency in
        pitchMatchingSession.adjustFrequency(frequency)
    },
    onRelease: { frequency in
        pitchMatchingSession.commitResult(userFrequency: frequency)
    }
)

// AFTER:
VerticalPitchSlider(
    isActive: pitchMatchingSession.state == .playingTunable,
    onNormalizedValueChange: { normalized in
        pitchMatchingSession.adjustNormalizedPitch(normalized)
    },
    onCommit: { normalized in
        pitchMatchingSession.commitNormalizedPitch(normalized)
    }
)
```

### ContentView Transformation

```swift
// BEFORE:
@Environment(\.comparisonSession) private var comparisonSession
@Environment(\.pitchMatchingSession) private var pitchMatchingSession

private func handleAppBackgrounding() {
    if comparisonSession.state != .idle { comparisonSession.stop() }
    if pitchMatchingSession.state != .idle { pitchMatchingSession.stop() }
}

// AFTER:
@Environment(\.activeSession) private var activeSession

private func handleAppBackgrounding() {
    activeSession?.stop()
}
```

### Existing Code to Reference

- **`ContentView.swift:48-66`** -- Feature envy REVIEW comment and current concrete session handling. [Source: Peach/App/ContentView.swift]
- **`VerticalPitchSlider.swift:3`** -- REVIEW comment about slider domain knowledge. [Source: Peach/PitchMatching/VerticalPitchSlider.swift]
- **`VerticalPitchSlider.swift:120-157`** -- Current cent/frequency calculation methods to move. [Source: Peach/PitchMatching/VerticalPitchSlider.swift]
- **`PitchMatchingScreen.swift:11-19`** -- Current slider construction with frequency callbacks. [Source: Peach/PitchMatching/PitchMatchingScreen.swift]

### Testing Approach

- **New tests:** `PitchMatchingSession.adjustNormalizedPitch()` and `commitNormalizedPitch()` need unit tests verifying correct frequency computation from normalized values
- **VerticalPitchSlider tests:** Update static method tests (if they exist) for normalized API — `centOffset(dragY:trackHeight:centRange:)` becomes simpler normalized mapping
- **ContentView:** No direct test changes needed — it's now simpler (one optional protocol call)
- **Integration:** Full suite run confirms sessions still start/stop correctly on navigation

### Previous Story Learnings (from 19.4)

- **Methods are already extracted** — `ComparisonSession` and `PeachApp` methods are clean from Story 19.4. The `TrainingSession` conformance is straightforward since `stop()` and `isIdle` already exist as concepts.
- **`@Observable` observation** — SwiftUI views automatically re-render when `@Observable` properties change. `activeSession` changes will propagate naturally if wired via `@Environment`.

### Risk Assessment

- **`VerticalPitchSlider` accessibility actions** — The current implementation has hardcoded cent-based increment/decrement in accessibility actions. These need to be converted to normalized increments. Don't forget these.
- **`PitchMatchingScreen` references** — Check if `PitchMatchingScreen` passes `referenceFrequency` to the slider from `pitchMatchingSession.referenceFrequency`. This coupling must be removed.
- **Active session timing** — Ensure the active session reference is updated before the view observes it. Race conditions between session start and `ContentView` reading `activeSession` should be considered.

### Git Intelligence

Commit message: `Implement story 19.5: TrainingSession protocol and dependency cleanup`

### Project Structure Notes

- `TrainingSession.swift` goes in `Peach/Core/` (cross-cutting protocol used by App and sessions)
- No new directories needed

### References

- [Source: Peach/App/ContentView.swift:48 -- REVIEW comment about feature envy]
- [Source: Peach/PitchMatching/VerticalPitchSlider.swift:3 -- REVIEW comment about slider domain knowledge]
- [Source: Peach/PitchMatching/PitchMatchingScreen.swift -- Current slider usage]
- [Source: Peach/PitchMatching/PitchMatchingSession.swift -- Session that will own pitch calculations]
- [Source: docs/project-context.md -- Views are thin, protocol-first design]
- [Source: docs/implementation-artifacts/19-4-extract-long-methods.md -- Prerequisite story]

## Change Log

- 2026-02-26: Story created by BMAD create-story workflow from Epic 19 code review plan.
- 2026-02-27: Implemented all 9 tasks. TrainingSession protocol, active session tracking, ContentView refactor, VerticalPitchSlider normalized API, PitchMatchingSession pitch calculations, environment wiring, tests updated. Full suite passes.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- VerticalPitchSlider test initially had ComparisonSession tests waiting for `.playingNote1` which transitions too fast with instant playback — fixed to wait for `.awaitingAnswer`

### Completion Notes List

- Created `TrainingSession` protocol with `stop()` and `isIdle` — both `ComparisonSession` and `PitchMatchingSession` conform
- Active session tracking via `.onChange(of: session.isIdle)` in PeachApp body — cleanly stops previous session when a new one starts
- ContentView simplified from 2 concrete session references to 1 `activeSession: TrainingSession?` — `handleAppBackgrounding()` is now a single `activeSession?.stop()` call
- VerticalPitchSlider transformed to pure UI component with normalized `-1.0...1.0` API — no pitch/frequency/cent domain knowledge
- PitchMatchingSession now owns cent→frequency conversion via `adjustNormalizedPitch()` and `commitNormalizedPitch()`
- All REVIEW comments removed from ContentView.swift and VerticalPitchSlider.swift
- 6 new TrainingSession protocol tests, 7 new normalized pitch tests, 11 updated slider tests — full suite passes (zero regressions)

### File List

- Peach/Core/TrainingSession.swift (new)
- Peach/Comparison/ComparisonSession.swift (modified)
- Peach/PitchMatching/PitchMatchingSession.swift (modified)
- Peach/App/PeachApp.swift (modified)
- Peach/App/ContentView.swift (modified)
- Peach/PitchMatching/VerticalPitchSlider.swift (modified)
- Peach/PitchMatching/PitchMatchingScreen.swift (modified)
- PeachTests/Core/TrainingSessionTests.swift (new)
- PeachTests/PitchMatching/VerticalPitchSliderTests.swift (modified)
- PeachTests/PitchMatching/PitchMatchingSessionTests.swift (modified)
