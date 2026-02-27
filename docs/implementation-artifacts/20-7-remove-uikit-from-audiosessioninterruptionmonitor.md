# Story 20.7: Remove UIKit from AudioSessionInterruptionMonitor

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer maintaining Peach**,
I want `AudioSessionInterruptionMonitor` to not import UIKit by accepting notification names as parameters instead of hardcoding `UIApplication` constants,
So that Core/ files have no UIKit dependency and the monitor is more testable.

## Acceptance Criteria

1. **No UIKit import in AudioSessionInterruptionMonitor** -- `Peach/Core/Audio/AudioSessionInterruptionMonitor.swift` has no `import UIKit`.

2. **Background notification name is injected** -- The `observeBackgrounding: Bool` parameter is replaced with `backgroundNotificationName: Notification.Name? = nil`. When non-nil, the monitor observes that notification name for backgrounding. When nil (default), backgrounding is not monitored.

3. **Foreground notification name is injected** -- A new `foregroundNotificationName: Notification.Name? = nil` parameter is added. When non-nil, the monitor observes that notification name and calls `onStopRequired`. When nil (default), foreground is not monitored.

4. **PitchMatchingSession passes notification names** -- `PitchMatchingSession.init()` accepts optional notification name parameters and passes them through to `AudioSessionInterruptionMonitor`.

5. **PeachApp provides UIKit notification names** -- `PeachApp.createPitchMatchingSession()` passes `UIApplication.didEnterBackgroundNotification` and `UIApplication.willEnterForegroundNotification` (available via SwiftUI import).

6. **ComparisonSession unaffected** -- `ComparisonSession` does not observe backgrounding (default nil). No changes needed to its monitor creation.

7. **All existing tests pass** -- Full test suite passes with zero regressions.

## Tasks / Subtasks

- [x] Task 1: Refactor AudioSessionInterruptionMonitor init (AC: #1, #2, #3)
  - [x] Replace `observeBackgrounding: Bool = false` with `backgroundNotificationName: Notification.Name? = nil`
  - [x] Add `foregroundNotificationName: Notification.Name? = nil` parameter
  - [x] Replace hardcoded `UIApplication.didEnterBackgroundNotification` with `backgroundNotificationName`
  - [x] Replace hardcoded `UIApplication.willEnterForegroundNotification` with `foregroundNotificationName`
  - [x] Remove `import UIKit`

- [x] Task 2: Update PitchMatchingSession (AC: #4)
  - [x] Add `backgroundNotificationName: Notification.Name? = nil` and `foregroundNotificationName: Notification.Name? = nil` parameters to init
  - [x] Pass through to `AudioSessionInterruptionMonitor(... backgroundNotificationName:, foregroundNotificationName:)`

- [x] Task 3: Update PeachApp (AC: #5)
  - [x] In `createPitchMatchingSession()`, pass `backgroundNotificationName: UIApplication.didEnterBackgroundNotification` and `foregroundNotificationName: UIApplication.willEnterForegroundNotification`

- [x] Task 4: Update tests (AC: #7)
  - [x] Update `AudioSessionInterruptionMonitorTests` to pass notification names explicitly instead of `observeBackgrounding: true`
  - [x] The test file can keep its `import UIKit` (acceptable for tests)
  - [x] Update `PitchMatchingSessionTests` if they construct sessions with backgrounding params

- [x] Task 5: Run full test suite (AC: #6, #7)
  - [x] `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
  - [x] All tests pass, zero regressions

## Dev Notes

### Critical Design Decisions

- **Injection over abstraction** -- Rather than creating a protocol for `AudioSessionInterruptionMonitor` (which has no methods called after init), we inject the notification names. This removes the UIKit dependency while keeping the implementation simple. The monitor's contract is established at init time via callback closures.
- **Both notification names injected** -- The monitor uses both `didEnterBackgroundNotification` and `willEnterForegroundNotification`. Both need to be parameters.
- **Default nil preserves backward compatibility** -- `ComparisonSession` creates the monitor without backgrounding (default). Only `PitchMatchingSession` needs backgrounding, and it gets the names from `PeachApp`.

### Architecture & Integration

**Modified production files:**
- `Peach/Core/Audio/AudioSessionInterruptionMonitor.swift` -- parameter change, remove UIKit
- `Peach/PitchMatching/PitchMatchingSession.swift` -- pass through notification names
- `Peach/App/PeachApp.swift` -- provide UIKit notification names at composition root

**Modified test files:**
- `PeachTests/Core/Audio/AudioSessionInterruptionMonitorTests.swift` -- pass notification names
- `PeachTests/PitchMatching/PitchMatchingSessionTests.swift` -- Updated `makePitchMatchingSession` factory to pass notification names (defaulting to UIApplication constants for test parity)

### Existing Code to Reference

- **`AudioSessionInterruptionMonitor.swift`** -- Current `observeBackgrounding: Bool` parameter and UIKit notification observers. [Source: Peach/Core/Audio/AudioSessionInterruptionMonitor.swift]
- **`PitchMatchingSession.swift:~init`** -- Creates `AudioSessionInterruptionMonitor(... observeBackgrounding: true)`. [Source: Peach/PitchMatching/PitchMatchingSession.swift]
- **`ComparisonSession.swift:88-92`** -- Creates `AudioSessionInterruptionMonitor(...)` without backgrounding. [Source: Peach/Comparison/ComparisonSession.swift]

### Testing Approach

- **Update existing tests** -- `AudioSessionInterruptionMonitorTests` has tests for background notification (lines ~148-184). These pass `observeBackgrounding: true` -- change to pass `backgroundNotificationName: UIApplication.didEnterBackgroundNotification`.
- **Full suite run** confirms no regressions.

### Risk Assessment

- **Low risk** -- Parameter rename with straightforward ripple effects. The notification observation mechanism is unchanged; only the source of the notification name changes from a hardcoded constant to an injected parameter.

### Git Intelligence

Commit message: `Implement story 20.7: Remove UIKit from AudioSessionInterruptionMonitor`

### References

- [Source: docs/project-context.md -- "no UIKit in views" (extending to "no UIKit in Core/")]
- [Source: docs/planning-artifacts/epics.md -- Epic 20]

## File List

**Modified:**
- `Peach/Core/Audio/AudioSessionInterruptionMonitor.swift` — Removed `import UIKit`; replaced `observeBackgrounding: Bool` with `backgroundNotificationName: Notification.Name?` and added `foregroundNotificationName: Notification.Name?`; added `foregroundObserver` property with cleanup in deinit
- `Peach/PitchMatching/PitchMatchingSession.swift` — Added `backgroundNotificationName` and `foregroundNotificationName` parameters to init; passes them through to `AudioSessionInterruptionMonitor`
- `Peach/App/PeachApp.swift` — `createPitchMatchingSession()` now passes `UIApplication.didEnterBackgroundNotification` and `UIApplication.willEnterForegroundNotification`
- `PeachTests/Core/Audio/AudioSessionInterruptionMonitorTests.swift` — Updated background tests to use `backgroundNotificationName:` instead of `observeBackgrounding:`; added foreground notification tests
- `PeachTests/PitchMatching/PitchMatchingSessionTests.swift` — Updated `makePitchMatchingSession` factory to pass notification names (defaulting to UIApplication constants for test parity)
- `docs/implementation-artifacts/sprint-status.yaml` — Story status updated

## Dev Agent Record

### Implementation Notes
- Replaced `observeBackgrounding: Bool` parameter with two optional `Notification.Name?` parameters (`backgroundNotificationName`, `foregroundNotificationName`), both defaulting to nil
- Added symmetric foreground notification observation (calls `onStopRequired` like background), with cleanup in `isolated deinit`
- ComparisonSession is completely unaffected — it uses default nil parameters (no backgrounding)
- PeachApp (composition root) provides the UIKit notification names via SwiftUI import, keeping UIKit knowledge at the app boundary
- Test factory updated to default to UIApplication notification names to maintain test parity with previous behavior

### Completion Notes
- All 5 tasks completed successfully
- Full test suite passes with zero regressions
- `import UIKit` removed from `AudioSessionInterruptionMonitor.swift`
- No new dependencies introduced

## Change Log

- 2026-02-27: Story created from Epic 20 adversarial dependency review.
- 2026-02-27: Implemented — removed UIKit import from AudioSessionInterruptionMonitor by injecting notification names as parameters. All tests pass.
- 2026-02-27: Code review — Fixed: added missing foreground notification unit tests (M2), corrected story number in Git Intelligence from 20.6 to 20.7 (M3), clarified AC #3 wording that foreground observation is new not a replacement (M1), fixed hedging language in Modified test files (L1).
