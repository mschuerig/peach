# Story 19.1: Clamping Utility and Magic Value Constants

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want inline clamping patterns and magic numeric literals replaced with a reusable utility and named constants,
So that the code is easier to read, harder to get wrong, and changes to domain bounds propagate from a single source of truth.

## Acceptance Criteria

1. **`Comparable.clamped(to:)` extension exists** -- A `clamped(to:)` method on `Comparable` replaces all inline `min(max(...))` / `max(..., min(...))` patterns. The extension lives in `Peach/Core/`.

2. **All inline clamping removed** -- Every inline `min(max(...))` or `max(..., min(...))` pattern in production code is replaced with `.clamped(to:)`. The local `clamp()` helper in `AdaptiveNoteStrategy.swift` is removed.

3. **Named constant for initial cent offset range** -- The magic literal `-100.0...100.0` in `PitchMatchingSession.swift` is replaced with a named `static let` constant with a descriptive name.

4. **Named constant for amplitude dB bounds** -- The magic literals `-90.0` and `12.0` used as amplitude decibel bounds in `ComparisonSession.swift` are replaced with named constants.

5. **All existing tests pass** -- The full test suite passes with zero regressions. No behavioral changes.

## Tasks / Subtasks

- [ ] Task 1: Create `Comparable+Clamped.swift` extension (AC: #1)
  - [ ] Create `Peach/Core/Comparable+Clamped.swift`
  - [ ] Implement `func clamped(to range: ClosedRange<Self>) -> Self`
  - [ ] Mark `nonisolated` (needed for use in `nonisolated` contexts under default MainActor isolation)

- [ ] Task 2: Replace all inline clamping patterns (AC: #2)
  - [ ] `AdaptiveNoteStrategy.swift`: Remove local `clamp()` function, replace usages with `.clamped(to:)`
  - [ ] `AdaptiveNoteStrategy.swift`: Replace `max(p * ..., settings.minCentDifference)` / `min(p * ..., settings.maxCentDifference)` with `.clamped(to:)` where applicable
  - [ ] `KazezNoteStrategy.swift`: Replace any inline `min(max(...))` with `.clamped(to:)`
  - [ ] `ComparisonSession.swift`: Replace inline clamping of amplitude values
  - [ ] `PitchMatchingSession.swift`: Replace inline clamping patterns

- [ ] Task 3: Add named constant for initial cent offset range (AC: #3)
  - [ ] In `PitchMatchingSession.swift`, replace the magic literal `-100.0...100.0` with a `private static let initialCentOffsetRange` constant

- [ ] Task 4: Add named constants for amplitude dB bounds (AC: #4)
  - [ ] In `ComparisonSession.swift`, extract `-90.0` and `12.0` amplitude bounds into named constants (e.g., `private static let amplitudeDBRange: ClosedRange<Float> = -90.0...12.0`)
  - [ ] Use constant with `.clamped(to:)` at the clamping site

- [ ] Task 5: Run full test suite and verify (AC: #5)
  - [ ] Run `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] All tests pass, zero regressions

## Dev Notes

### Critical Design Decisions

- **Pure refactoring, no behavioral change** -- This story only restructures how clamping is expressed. Every `.clamped(to:)` call must produce the same result as the inline `min(max(...))` it replaces. No new features, no logic changes.
- **`nonisolated` on the extension method** -- Under Swift 6.2 default MainActor isolation, a `Comparable` extension method must be marked `nonisolated` so it can be called from both `@MainActor` and `nonisolated` contexts (e.g., value type inits, static methods).
- **Constants are `private static let` unless shared** -- The amplitude dB range and initial cent offset range are only used within their respective files. Keep them `private static let`. If Story 19.2 (Value Objects) later needs to share them, they can be promoted at that point.
- **Do NOT extract MIDI ranges (0...127) or pitch bend ranges (0...16383) into constants** -- Those are well-known MIDI standards and self-documenting. Story 19.2 will wrap them in value types instead.

### Architecture & Integration

- **New file:** `Peach/Core/Comparable+Clamped.swift`
- **Modified files:**
  - `Peach/Core/Algorithm/AdaptiveNoteStrategy.swift` -- Remove local `clamp()`, replace inline patterns
  - `Peach/Core/Algorithm/KazezNoteStrategy.swift` -- Replace inline clamping
  - `Peach/Comparison/ComparisonSession.swift` -- Named constant for amplitude dB bounds, replace clamping
  - `Peach/PitchMatching/PitchMatchingSession.swift` -- Named constant for cent offset range
- **No changes to:** protocols, SwiftData models, views, `PeachApp.swift`, tests, or localization

### Implementation Pattern

```swift
// Peach/Core/Comparable+Clamped.swift
extension Comparable {
    nonisolated func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

Usage at each site:

```swift
// Before (AdaptiveNoteStrategy.swift, local clamp):
private func clamp(_ value: Double, min minVal: Double, max maxVal: Double) -> Double {
    max(minVal, min(maxVal, value))
}

// After:
value.clamped(to: minVal...maxVal)
```

```swift
// Before (ComparisonSession.swift):
let amplitudeDB = Float.random(in: -90.0...12.0)

// After:
private static let amplitudeDBRange: ClosedRange<Float> = -90.0...12.0
// ...
let amplitudeDB = Float.random(in: Self.amplitudeDBRange)
```

```swift
// Before (PitchMatchingSession.swift):
let offset = Double.random(in: -100.0...100.0)

// After:
private static let initialCentOffsetRange: ClosedRange<Double> = -100.0...100.0
// ...
let offset = Double.random(in: Self.initialCentOffsetRange)
```

### Existing Code to Reference (DO NOT MODIFY unless specified)

- **`AdaptiveNoteStrategy.swift`** -- Contains local `clamp()` at ~line 308 and inline `max(p * ..., min)` patterns. [Source: Peach/Core/Algorithm/AdaptiveNoteStrategy.swift]
- **`ComparisonSession.swift`** -- Amplitude dB magic values at ~lines 398-399. [Source: Peach/Comparison/ComparisonSession.swift]
- **`PitchMatchingSession.swift`** -- Magic `-100.0...100.0` at ~line 165. [Source: Peach/PitchMatching/PitchMatchingSession.swift]
- **`KazezNoteStrategy.swift`** -- Inline clamping pattern. [Source: Peach/Core/Algorithm/KazezNoteStrategy.swift]

### Testing Approach

- **No new tests needed** -- This is a pure refactoring. All existing tests verify the same behavior.
- **Run full suite** to confirm zero regressions.
- **Test count baseline:** 550 tests (from Story 18.1 completion).

### Previous Story Learnings (from 18.1)

- **`nonisolated` is required** on extensions that need to work across isolation boundaries. This was learned in multiple stories — Swift 6.2's default MainActor isolation means extensions must opt out explicitly.
- **Pure refactoring stories are small** — keep scope tight, don't add features or "improvements" beyond what's specified.

### Git Intelligence

Recent commit pattern:
1. `Add story X.Y` — create story file
2. `Implement story X.Y` — implement the code
3. `Fix code review findings for X-Y` — post-review fixes

Commit message for this story: `Implement story 19.1: Clamping utility and magic value constants`

### Project Structure Notes

- `Comparable+Clamped.swift` goes in `Peach/Core/` (cross-cutting utility used by Algorithm and session files)
- Do NOT create `Utils/`, `Helpers/`, or `Extensions/` directories — project convention prohibits them
- No new test files needed

### References

- [Source: docs/planning-artifacts/epics.md -- Epic 19 (to be added)]
- [Source: docs/project-context.md -- Language Rules, Code Quality]
- [Source: Peach/Core/Algorithm/AdaptiveNoteStrategy.swift -- Local clamp() function]
- [Source: Peach/Comparison/ComparisonSession.swift -- Amplitude dB magic values]
- [Source: Peach/PitchMatching/PitchMatchingSession.swift -- Cent offset magic range]
- [Source: Peach/Core/Algorithm/KazezNoteStrategy.swift -- Inline clamping]

## Change Log

- 2026-02-26: Story created by BMAD create-story workflow from Epic 19 code review plan.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
