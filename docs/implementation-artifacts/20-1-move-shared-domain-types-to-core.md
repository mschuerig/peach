# Story 20.1: Move Shared Domain Types to Core/Training/

Status: pending

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want shared domain types (`Comparison`, `CompletedComparison`, `ComparisonObserver`, `CompletedPitchMatching`, `PitchMatchingObserver`) moved from feature directories to `Core/Training/`,
So that Core/ no longer has upward dependencies on feature modules, and the dependency arrows point in the correct direction.

## Acceptance Criteria

1. **`Core/Training/` directory exists** -- A new `Peach/Core/Training/` directory contains the four moved files. A mirror `PeachTests/Core/Training/` directory exists (empty for now, as these types have no dedicated test files).

2. **`Comparison.swift` moved** -- `Peach/Comparison/Comparison.swift` (containing `Comparison` and `CompletedComparison`) is moved to `Peach/Core/Training/Comparison.swift`. The original file no longer exists in `Peach/Comparison/`.

3. **`ComparisonObserver.swift` moved** -- `Peach/Comparison/ComparisonObserver.swift` is moved to `Peach/Core/Training/ComparisonObserver.swift`. The original file no longer exists.

4. **`CompletedPitchMatching.swift` moved** -- `Peach/PitchMatching/CompletedPitchMatching.swift` is moved to `Peach/Core/Training/CompletedPitchMatching.swift`. The original file no longer exists.

5. **`PitchMatchingObserver.swift` moved** -- `Peach/PitchMatching/PitchMatchingObserver.swift` is moved to `Peach/Core/Training/PitchMatchingObserver.swift`. The original file no longer exists.

6. **No Core/ file depends on any type defined in a feature directory** -- After the move, all types referenced by `Core/Data/`, `Core/Profile/`, and `Core/Algorithm/` files are defined within `Core/` itself.

7. **Zero code changes required** -- Because Peach is a single-module app, types are resolved by name, not directory path. No `import` statements or type references need updating.

8. **All existing tests pass** -- Full test suite passes with zero regressions and zero code changes.

## Tasks / Subtasks

- [ ] Task 1: Create directories (AC: #1)
  - [ ] Create `Peach/Core/Training/`
  - [ ] Create `PeachTests/Core/Training/`

- [ ] Task 2: Move Comparison types (AC: #2, #3)
  - [ ] `git mv Peach/Comparison/Comparison.swift Peach/Core/Training/Comparison.swift`
  - [ ] `git mv Peach/Comparison/ComparisonObserver.swift Peach/Core/Training/ComparisonObserver.swift`

- [ ] Task 3: Move PitchMatching types (AC: #4, #5)
  - [ ] `git mv Peach/PitchMatching/CompletedPitchMatching.swift Peach/Core/Training/CompletedPitchMatching.swift`
  - [ ] `git mv Peach/PitchMatching/PitchMatchingObserver.swift Peach/Core/Training/PitchMatchingObserver.swift`

- [ ] Task 4: Verify dependency direction (AC: #6)
  - [ ] Audit Core/ files to confirm none reference types in Comparison/ or PitchMatching/

- [ ] Task 5: Run full test suite (AC: #7, #8)
  - [ ] `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [ ] All tests pass, zero regressions, zero code changes

## Dev Notes

### Critical Design Decisions

- **Pure file move, zero code changes** -- Xcode objectVersion 77 uses file-system-synchronized groups. Moving files on disk with `git mv` is sufficient; no `.pbxproj` edits needed. The Swift compiler resolves types by name within the module, not by directory path.
- **`Core/Training/` as the new home** -- These types are domain primitives (value types and protocols) used by Core/Algorithm, Core/Profile, Core/Data, and both feature sessions. They are not UI types and not feature-specific. `Core/Training/` groups them as the shared training domain vocabulary.
- **`PitchMatchingChallenge` stays** -- `PitchMatchingChallenge` is only used within the PitchMatching feature module and does not need to move.

### Architecture & Integration

**New directories:**
- `Peach/Core/Training/` (production)
- `PeachTests/Core/Training/` (test mirror, initially empty)

**Moved files (content unchanged):**
- `Peach/Comparison/Comparison.swift` -> `Peach/Core/Training/Comparison.swift`
- `Peach/Comparison/ComparisonObserver.swift` -> `Peach/Core/Training/ComparisonObserver.swift`
- `Peach/PitchMatching/CompletedPitchMatching.swift` -> `Peach/Core/Training/CompletedPitchMatching.swift`
- `Peach/PitchMatching/PitchMatchingObserver.swift` -> `Peach/Core/Training/PitchMatchingObserver.swift`

**No modified files.** All consumers reference these types by name only.

### Existing Code to Reference

- **`Core/Data/TrainingDataStore.swift`** -- Conforms to `ComparisonObserver` and `PitchMatchingObserver`; references `CompletedComparison` and `CompletedPitchMatching`. [Source: Peach/Core/Data/TrainingDataStore.swift]
- **`Core/Profile/PerceptualProfile.swift`** -- Conforms to `ComparisonObserver` and `PitchMatchingObserver`. [Source: Peach/Core/Profile/PerceptualProfile.swift]
- **`Core/Algorithm/NextComparisonStrategy.swift`** -- References `Comparison` and `CompletedComparison` in protocol signature. [Source: Peach/Core/Algorithm/NextComparisonStrategy.swift]
- **`Core/Profile/TrendAnalyzer.swift`** -- Conforms to `ComparisonObserver`, references `CompletedComparison`. [Source: Peach/Core/Profile/TrendAnalyzer.swift]
- **`Core/Profile/ThresholdTimeline.swift`** -- Conforms to `ComparisonObserver`, references `CompletedComparison`. [Source: Peach/Core/Profile/ThresholdTimeline.swift]

### Testing Approach

- **No new tests** -- This is a pure file move with no behavioral change.
- **Run full suite** to confirm the compiler resolves all types correctly at their new paths.

### Risk Assessment

- **Extremely low risk** -- Single-module app means file location does not affect compilation. The only risk is Xcode project file corruption, mitigated by using `git mv` and the modern file-system-synchronized project format.

### Git Intelligence

Commit message: `Implement story 20.1: Move shared domain types to Core/Training/`

### Project Structure Notes

- `Core/Training/` is a new subdirectory alongside `Core/Audio/`, `Core/Algorithm/`, `Core/Data/`, and `Core/Profile/`
- It holds the shared training vocabulary (value types and observer protocols) used across features

### References

- [Source: docs/planning-artifacts/epics.md -- Epic 20: Right Direction — Dependency Inversion Cleanup]
- [Source: docs/project-context.md -- File Placement decision tree]

## Change Log

- 2026-02-27: Story created from Epic 20 adversarial dependency review.
