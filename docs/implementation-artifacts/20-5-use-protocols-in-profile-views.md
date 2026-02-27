# Story 20.5: Use Protocols in Profile Views

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want `SummaryStatisticsView` and `MatchingStatisticsView` to depend on protocols (`PitchDiscriminationProfile` and `PitchMatchingProfile`) instead of the concrete `PerceptualProfile` class,
So that the views follow the Dependency Inversion Principle and depend on abstractions rather than implementations.

## Acceptance Criteria

1. **`computeStats(from:)` accepts protocol** -- `SummaryStatisticsView.computeStats(from:)` parameter type is changed from `PerceptualProfile` to `PitchDiscriminationProfile`.

2. **`computeMatchingStats(from:)` accepts protocol** -- `MatchingStatisticsView.computeMatchingStats(from:)` parameter type is changed from `PerceptualProfile` to `PitchMatchingProfile`.

3. **No behavioral change** -- Since `PerceptualProfile` conforms to both protocols, all existing callers auto-upcast. No call-site changes are needed.

4. **All existing tests pass** -- Full test suite passes with zero regressions. Existing tests pass `PerceptualProfile()` which conforms to both protocols.

## Tasks / Subtasks

- [x] Task 1: Change `SummaryStatisticsView.computeStats(from:)` (AC: #1)
  - [x] Change parameter type from `PerceptualProfile` to `PitchDiscriminationProfile`
  - [x] Verify the method body only calls API defined on `PitchDiscriminationProfile`

- [x] Task 2: Change `MatchingStatisticsView.computeMatchingStats(from:)` (AC: #2)
  - [x] Change parameter type from `PerceptualProfile` to `PitchMatchingProfile`
  - [x] Verify the method body only calls API defined on `PitchMatchingProfile`

- [x] Task 3: Run full test suite (AC: #3, #4)
  - [x] `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [x] All tests pass, zero regressions

## Dev Notes

### Critical Design Decisions

- **Minimal change** -- Only the `static` computation methods change their parameter type. The `@Environment(\.perceptualProfile)` properties in the view bodies remain `PerceptualProfile` (the concrete type provided by the environment). This is acceptable because the environment necessarily provides a concrete instance; the abstraction boundary is at the computation method level.
- **No new protocols needed** -- `PitchDiscriminationProfile` (Core/Profile/) and `PitchMatchingProfile` (Core/Profile/) already exist and define exactly the API these methods need.

### Architecture & Integration

**Modified production files:**
- `Peach/Profile/SummaryStatisticsView.swift` -- change `computeStats(from:)` parameter type
- `Peach/Profile/MatchingStatisticsView.swift` -- change `computeMatchingStats(from:)` parameter type

### Existing Code to Reference

- **`SummaryStatisticsView.swift:~86`** -- `static func computeStats(from profile: PerceptualProfile, ...)`. Method calls `profile.statsForNote()` which is on `PitchDiscriminationProfile`. [Source: Peach/Profile/SummaryStatisticsView.swift]
- **`MatchingStatisticsView.swift:~66`** -- `static func computeMatchingStats(from profile: PerceptualProfile)`. Method accesses `profile.matchingMean`, `profile.matchingStdDev`, `profile.matchingSampleCount` -- all on `PitchMatchingProfile`. [Source: Peach/Profile/MatchingStatisticsView.swift]
- **`PitchDiscriminationProfile.swift`** -- Protocol definition with `statsForNote()`, `overallMean`, etc. [Source: Peach/Core/Profile/PitchDiscriminationProfile.swift]
- **`PitchMatchingProfile.swift`** -- Protocol definition with `matchingMean`, `matchingStdDev`, `matchingSampleCount`. [Source: Peach/Core/Profile/PitchMatchingProfile.swift]

### Testing Approach

- **No new tests needed** -- Existing tests pass `PerceptualProfile()` which conforms to both protocols. The parameter type change is backwards-compatible.
- **Optional enhancement** -- Could add tests that pass a mock `PitchDiscriminationProfile` / `PitchMatchingProfile` to verify the computation methods work with any conforming type, not just `PerceptualProfile`. This validates the abstraction.

### Risk Assessment

- **Very low risk** -- The change is a type signature relaxation. If the method body accidentally uses API not on the protocol, the compiler will catch it.

### Git Intelligence

Commit message: `Implement story 20.5: Use protocols in profile views`

### References

- [Source: docs/planning-artifacts/epics.md -- Epic 20]
- [Source: Peach/Core/Profile/PitchDiscriminationProfile.swift -- Protocol definition]
- [Source: Peach/Core/Profile/PitchMatchingProfile.swift -- Protocol definition]

## Dev Agent Record

### Implementation Notes

- Changed `SummaryStatisticsView.computeStats(from:)` parameter type from `PerceptualProfile` to `PitchDiscriminationProfile` (line 86). Verified method body only calls `statsForNote()` which is defined on `PitchDiscriminationProfile`.
- Changed `MatchingStatisticsView.computeMatchingStats(from:)` parameter type from `PerceptualProfile` to `PitchMatchingProfile` (line 66). Verified method body only accesses `matchingMean`, `matchingStdDev`, `matchingSampleCount` — all defined on `PitchMatchingProfile`.
- No call-site changes needed: `PerceptualProfile` conforms to both protocols, so existing callers auto-upcast.
- Full test suite: 588 passed, 0 failed.

## File List

- `Peach/Profile/SummaryStatisticsView.swift` (modified) — parameter type change, docstring fix
- `Peach/Profile/MatchingStatisticsView.swift` (modified) — parameter type change
- `PeachTests/Profile/MockPitchDiscriminationProfile.swift` (new) — mock for protocol abstraction tests
- `PeachTests/Profile/SummaryStatisticsTests.swift` (modified) — added protocol abstraction test
- `PeachTests/Profile/MatchingStatisticsViewTests.swift` (modified) — added protocol abstraction test

## Change Log

- 2026-02-27: Story created from Epic 20 adversarial dependency review.
- 2026-02-27: Implementation complete — both computation methods now depend on protocol abstractions.
- 2026-02-27: Code review fixes — fixed Git Intelligence typo (20.4→20.5), updated stale docstring, added protocol-validation tests with mocks.
