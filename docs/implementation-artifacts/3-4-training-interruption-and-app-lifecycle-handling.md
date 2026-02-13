# Story 3.4: Training Interruption and App Lifecycle Handling

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want training to stop cleanly when I navigate away or leave the app,
So that no data is lost and I return to the Start Screen seamlessly.

## Acceptance Criteria

1. **Given** training is in progress, **When** the user taps Settings or Profile on the Training Screen, **Then** training stops immediately **And** any incomplete comparison is silently discarded **And** the user navigates to the selected screen **And** that screen returns to the Start Screen when dismissed

2. **Given** training is in progress, **When** the app is backgrounded (home button, app switcher, phone call, headphone disconnect), **Then** training stops and the incomplete comparison is discarded

3. **Given** the app was backgrounded during training, **When** the app is foregrounded, **Then** the user is returned to the Start Screen (not the Training Screen)

4. **Given** training is in the showingFeedback state, **When** the app is backgrounded, **Then** the already-answered comparison was already saved — no data loss

## Tasks / Subtasks

- [ ] Task 1: Implement Navigation-Based Training Stop (AC: #1)
  - [ ] Verify TrainingScreen.onDisappear already calls trainingSession.stop()
  - [ ] Test navigation to Settings - verify training stops
  - [ ] Test navigation to Profile - verify training stops
  - [ ] Verify incomplete comparison is discarded (not saved to dataStore)
  - [ ] Verify Settings/Profile return to Start Screen (already implemented)

- [ ] Task 2: Implement App Lifecycle Handlers (AC: #2, #3)
  - [ ] Add scenePhase observer to PeachApp or ContentView
  - [ ] Detect app backgrounding (.background state)
  - [ ] Stop training when app backgrounds
  - [ ] Pop navigation stack to Start Screen when app foregrounds
  - [ ] Test with home button, app switcher, phone call simulation
  - [ ] Test headphone disconnect scenario

- [ ] Task 3: Verify Data Integrity During Interruption (AC: #4)
  - [ ] Review TrainingSession.handleAnswer() - confirm data saves BEFORE feedback state
  - [ ] Test interruption during showingFeedback state
  - [ ] Verify comparison was saved to dataStore
  - [ ] Verify no duplicate saves on foreground
  - [ ] Test interruption during playingNote1/playingNote2 states
  - [ ] Verify incomplete comparison not saved

- [ ] Task 4: Audio Interruption Handling
  - [ ] Add AVAudioSession interruption notification observers
  - [ ] Handle phone call interruptions
  - [ ] Handle headphone disconnect
  - [ ] Stop training gracefully on audio interruptions
  - [ ] Clean up audio resources properly

- [ ] Task 5: Navigation State Management
  - [ ] Implement navigation path clearing on app foreground
  - [ ] Ensure user lands on Start Screen after backgrounding
  - [ ] Test navigation from Training → Settings → background → foreground
  - [ ] Test navigation from Training → Profile → background → foreground
  - [ ] Verify no navigation state corruption

- [ ] Task 6: Comprehensive Testing
  - [ ] Unit tests for lifecycle state transitions
  - [ ] Manual device tests for all interruption scenarios
  - [ ] Test rapid background/foreground cycles
  - [ ] Test training stop from all states (playingNote1, playingNote2, awaitingAnswer, showingFeedback)
  - [ ] Verify no memory leaks from observers

## Dev Notes

### 🎯 CRITICAL CONTEXT: The Graceful Interruption Contract

**This story completes Epic 3's core training loop** by ensuring that training can be interrupted at any moment without data loss, user confusion, or broken state. This is the final piece that makes Peach's "sessionless training" model work seamlessly.

**What makes this story critical:**
- **Data integrity guarantee**: Users must never lose an answered comparison, even if they background mid-feedback
- **Zero friction stop**: No confirmation dialogs, no "are you sure?" - just leave, anytime
- **Navigation sanity**: After backgrounding during training, users must return to a known, clean state (Start Screen)
- **Audio interruption resilience**: Phone calls, headphone disconnects, system alerts can't break the app

**The UX Principle**: "Respect incidental time" means instant start AND instant stop with zero state overhead.

### Story Context

**Epic Context:** Epic 3 "Train Your Ear - The Comparison Loop" — the core product experience
- Story 3.1: Created navigation shell and Start Screen ✅
- Story 3.2: Implemented TrainingSession state machine and comparison loop ✅
- Story 3.3: Added visual and haptic feedback to complete the training UX ✅
- **Story 3.4 (this story)**: Adds lifecycle and interruption handling to complete Epic 3
- Story 3.5: NOT IN EPIC - Epic 3 complete after this story

**Why This Story Matters:**

From the **PRD and Epics** (epics.md lines 394-420):
- **FR6**: User can stop training by navigating to Settings or Profile from the Training Screen, or by leaving the app
- **FR7**: System discards incomplete comparisons when training is interrupted (navigation away, app backgrounding, phone call, headphone disconnect)
- **FR7a**: System returns to the Start Screen when the app is foregrounded after being backgrounded during training

From the **Architecture Document** (architecture.md lines 363-369):
- **Cross-Cutting Concern - Audio interruption handling**: Phone calls, headphone disconnects, app backgrounding must gracefully discard incomplete comparisons across Training Loop, Audio Engine, and Data layers

From the **UX Design Specification** (ux-design-specification.md lines 350-361):
- **The Comparison Loop - Step 7: Leaving**: User taps Settings or Profile button on Training Screen, or backgrounds the app. If mid-comparison: the incomplete comparison is silently discarded. If during feedback: feedback clears; the answered comparison was already recorded. Training stops, user arrives at the selected destination (Settings/Profile) or Start Screen (on foreground after backgrounding).

**User Impact:**
- Without this story: backgrounding the app crashes training, potentially losing data or leaving broken state
- Without this story: navigating away mid-comparison might save incomplete data or cause state corruption
- With this story: users can put phone down mid-comparison with zero thought, zero friction, zero consequences

**Cross-Story Dependencies:**
- **Story 3.2 (done)**: Provides TrainingSession.stop() method and state machine - this story uses it
- **Story 3.3 (done)**: Feedback state must clear properly on interruption
- **Story 2.1 (done)**: NotePlayer must stop audio cleanly when training stops
- **Epic 4 (future)**: Adaptive algorithm will need to handle incomplete comparisons not affecting the profile

### Technical Stack — Exact Versions & Frameworks

Continuing from Stories 3.1-3.3:
- **Xcode:** 26.2
- **Swift:** 6.0
- **iOS Deployment Target:** iOS 26
- **UI Framework:** SwiftUI
- **Lifecycle APIs:** SwiftUI `scenePhase` environment value
- **Audio Interruption:** AVFoundation `AVAudioSession.interruptionNotification`
- **Navigation:** SwiftUI `NavigationStack` with programmatic path control
- **Testing Framework:** Swift Testing (@Test, #expect())

**New in This Story:**
- First use of SwiftUI `@Environment(\.scenePhase)` for app lifecycle monitoring
- First use of AVAudioSession notification observers
- First programmatic navigation stack manipulation (popping to root on foreground)

### Architecture Compliance Requirements

**From Architecture Document:**

**Cross-Cutting Concerns - Audio Interruption Handling** (architecture.md lines 48-51, 363-369):

The architecture identifies audio interruption handling as a cross-cutting concern affecting:
- `SineWaveNotePlayer` - must stop audio cleanly
- `TrainingSession` - must discard current comparison and transition to idle
- Data layer - must NOT save incomplete comparisons

**Resolution Strategy:**
1. AVAudioSession reports interruption → TrainingSession receives notification
2. TrainingSession calls stop() → audio stops, state → idle, current comparison discarded
3. No data write occurs (comparison only saved on handleAnswer())

**TrainingSession as Error Boundary** (architecture.md lines 248-261):

TrainingSession is designed to catch all service errors and handle them gracefully:
- **Audio failure** → stop training silently (transition to idle)
- **Data write failure** → log internally, continue training
- **The user never sees error screens**

For this story: Interruptions are NOT errors - they're expected user actions that must be handled cleanly.

**Navigation Model - Hub and Spoke** (ux-design-specification.md lines 364-392):

All navigation flows through Start Screen:
```
Start Screen → Training Screen (via Start Training button)
Training Screen → Settings/Profile → Start Screen (always return)
App backgrounded during training → Start Screen (on foreground)
```

**Implementation Requirement:**
- When app foregrounds, programmatically pop navigation to root (Start Screen)
- Do NOT return user to Training Screen - they must consciously choose to resume

**Service Boundaries** (architecture.md lines 329-346):

- `NotePlayer` - knows only frequencies and playback. Has no concept of interruptions. Boundary: stop() must clean up audio resources.
- `TrainingSession` - orchestrates all services. Boundary: the integration layer that handles interruptions.
- `TrainingDataStore` - pure persistence. Boundary: only saves complete comparison records.

This story affects TrainingSession (primary) and NotePlayer (must respond to stop()).

### UX Design Requirements

**From UX Design Specification:**

**The Comparison Loop - Step 7: Leaving** (ux-design-specification.md lines 357-361):

When user leaves training (navigation or backgrounding):
1. If mid-comparison (playingNote1, playingNote2, awaitingAnswer): **silently discard** incomplete comparison
2. If during feedback (showingFeedback): feedback clears, **comparison already saved**
3. Training stops
4. User lands at destination (Settings/Profile) or Start Screen (after backgrounding)
5. **No session summary**, **no confirmation dialog**, **no statistics**

**Critical UX Principle - Respect Incidental Time** (ux-design-specification.md lines 103-105):

The app is designed for the cracks in a musician's day:
- **Instant start** ✅ (Story 3.1-3.3 complete)
- **Instant stop** ← THIS STORY
- **No warm-up, no wind-down, no session overhead**
- **30 seconds of training is as valid as 30 minutes**

Implementation: No "Are you sure?" prompts. No "Session incomplete" warnings. Just stop.

**Navigation-as-Stop Pattern** (ux-design-specification.md lines 308-309):

There is no explicit "stop training" button. Navigation IS stopping:
- Tap Settings button → training stops, navigate to Settings
- Tap Profile button → training stops, navigate to Profile
- Background app → training stops, return to Start Screen on foreground

**Journey 4: Return After Break** (ux-design-specification.md lines 566-584):

After weeks away, the app should look identical - no "welcome back", no streak reset, no messaging. Backgrounding is just a very short "break". Same principle applies.

**Interruption Pattern** (ux-design-specification.md lines 625-628):

"Any interruption during training (navigation, backgrounding, phone call, headphone disconnect) follows the same rule: stop audio, discard incomplete comparison, leave Training Screen. No special cases, no confirmation dialogs, no state to recover."

### Previous Story Intelligence

**Key Learnings from Story 3.3 (Visual and Haptic Feedback):**

**1. TrainingScreen Already Has onDisappear Handler:**

From TrainingScreen.swift (lines 79-82):
```swift
.onDisappear {
    // Stop training when leaving screen
    trainingSession.stop()
}
```

**Implication for Story 3.4:**
- Navigation to Settings/Profile already triggers stop() via onDisappear ✅
- We DON'T need to add manual stop calls in navigation buttons
- We DO need to ensure stop() properly discards incomplete comparisons
- We DO need to add app lifecycle handling (scenePhase) for backgrounding

**2. TrainingSession.stop() Already Exists:**

From TrainingSession.swift (Story 3.2/3.3), stop() method:
- Sets state to .idle
- Stops audio playback
- Clears feedback state (showFeedback, isLastAnswerCorrect)
- Cancels the training loop task

**What's MISSING (this story adds):**
- Explicit handling of incomplete comparison discard
- Documentation that incomplete comparisons are intentionally not saved
- Audio session interruption observers
- Foreground navigation state reset

**3. Data Save Happens in handleAnswer(), Not in Feedback State:**

From Story 3.3 analysis: TrainingSession saves comparison data when handleAnswer() is called, BEFORE transitioning to showingFeedback state.

**Implication:**
- If interrupted during playingNote1/playingNote2/awaitingAnswer: comparison never saved ✅ (no handleAnswer() called)
- If interrupted during showingFeedback: comparison already saved ✅ (handleAnswer() was called)
- This already meets AC#4 - just need to verify and test

**4. State Machine is Robust:**

Story 3.2 went through multiple bug fix iterations to make state machine reliable. Don't modify core state machine logic - add lifecycle handling around it.

**From Story 3.3 Completion Notes:**

**Files Modified in 3.3:**
- Peach/Training/TrainingScreen.swift - has onAppear/onDisappear lifecycle hooks
- Peach/Training/TrainingSession.swift - has stop() method and state management
- These are the files we'll modify for Story 3.4

**Established Patterns to Continue:**
- Protocol-based dependencies with mocks for testing
- Comprehensive logging with os.Logger
- @Observable pattern for state management
- SwiftUI environment for dependency injection

### Git Intelligence from Recent Commits

**Recent Commit Analysis:**

```
0db1cc9 Updated Xcode project to latest recommendations.
e682ff6 Strengthen haptic feedback based on device testing - Story 3.3 complete
1964451 Code review fixes for Story 3.3
0643cd6 Add spacing and padding to training buttons
98923f6 Fix button corner radius implementation
df6126f Implement Story 3.3: Training Screen UI with Higher/Lower Buttons and Feedback
```

**Pattern: Iterative Refinement:**

Story 3.3 required multiple commits after initial implementation:
- df6126f: Initial implementation
- 98923f6: Fix corner radius (implementation detail)
- 0643cd6: Layout refinement
- 1964451: Code review fixes
- e682ff6: Device testing feedback (haptic strength)
- 0db1cc9: Xcode project maintenance

**What This Means for Story 3.4:**

1. **Expect iteration**: First implementation may need refinement based on device testing
2. **Test all scenarios**: Lifecycle handling has many edge cases (phone calls, headphone disconnect, rapid background/foreground)
3. **Code review will check**: Proper cleanup, no memory leaks from observers, navigation state correctness
4. **Device testing mandatory**: Simulator doesn't fully replicate phone calls, headphone disconnect, app switching

**Code Quality Standards Established:**

From recent commits, the project maintains:
- Clean commit messages referencing story numbers
- Separation of concerns (UI layout vs. logic changes)
- Incremental fixes rather than large rewrites
- Device testing validation before marking stories done

**Project Structure from Glob:**

Training folder current files:
- Comparison.swift
- FeedbackIndicator.swift
- TrainingSession.swift
- TrainingScreen.swift
- HapticFeedbackManager.swift

**What Story 3.4 Will Modify:**
- TrainingSession.swift - add audio interruption observers, improve stop() documentation
- TrainingScreen.swift or ContentView.swift - add scenePhase observer for backgrounding
- PeachApp.swift - potentially add app-level lifecycle coordination

**What Story 3.4 Will Create:**
- Possibly LifecycleManager.swift if complexity warrants extraction
- Additional test files for lifecycle scenarios

### Existing Codebase Analysis

**From TrainingSession.swift (lines 1-100 read):**

**Current stop() Implementation:**
```swift
func stop() {
    logger.info("Training stopped")
    state = .idle
    notePlayer.stop()
    showFeedback = false
    isLastAnswerCorrect = nil
    trainingTask?.cancel()
    trainingTask = nil
}
```

**What This Does:**
- ✅ Sets state to idle
- ✅ Stops audio via notePlayer.stop()
- ✅ Clears feedback state
- ✅ Cancels training loop task

**What's Missing for Story 3.4:**
- Explicit logging or handling of incomplete comparison discard
- Audio interruption notification setup
- Cleanup of any audio session observers

**Current State Machine States:**
- idle - training not started or stopped
- playingNote1 - first note playing, buttons disabled
- playingNote2 - second note playing, buttons enabled
- awaitingAnswer - both notes finished, waiting for user tap
- showingFeedback - answer recorded, feedback showing

**Incomplete Comparison Definition:**
Any state other than showingFeedback where currentComparison exists but handleAnswer() hasn't been called yet.

**From TrainingScreen.swift (lines 1-100 read):**

**Current Lifecycle Hooks:**
```swift
.onAppear {
    trainingSession.startTraining()
}
.onDisappear {
    trainingSession.stop()
}
```

**What This Means:**
- ✅ Navigation away from Training Screen already calls stop()
- ✅ AC#1 (Settings/Profile navigation stops training) is already 90% implemented
- We need to add: scenePhase observer for backgrounding scenarios

**Navigation Structure:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        HStack(spacing: 20) {
            NavigationLink(value: NavigationDestination.settings) { ... }
            NavigationLink(value: NavigationDestination.profile) { ... }
        }
    }
}
```

Navigation uses NavigationDestination enum values. This suggests NavigationStack with programmatic path control exists somewhere (likely ContentView.swift).

### Performance and Data Integrity Requirements

**Data Integrity - Critical Requirements:**

**From AC#4:** "Given training is in the showingFeedback state, When the app is backgrounded, Then the already-answered comparison was already saved — no data loss"

**Implementation Verification Needed:**
1. Review TrainingSession.handleAnswer() to confirm data saves BEFORE showingFeedback state
2. Add test: interrupt during showingFeedback, verify data in dataStore
3. Add test: interrupt during playingNote2, verify NO data in dataStore

**From NFR10 (prd.md line 73):** "Training data must survive app crashes, force quits, and unexpected termination without loss"

**Implication:**
- SwiftData provides crash resilience via SQLite
- We must ensure comparisons are saved atomically BEFORE feedback shows
- Current implementation likely correct (handleAnswer saves synchronously) - verify and test

**From NFR11 (prd.md line 74):** "Data writes must be atomic — no partial comparison records"

**Implication:**
- TrainingDataStore uses SwiftData which provides atomic writes
- We must NOT partially save comparison data if interrupted mid-save (but this shouldn't happen - saves are synchronous)

**Audio Resource Cleanup:**

**From NFR1 (prd.md line 63):** "Audio latency must be imperceptible (< 10ms)"

**Implication:**
- Audio engine must be properly cleaned up on interruption to prevent resource leaks
- SineWaveNotePlayer.stop() must release audio resources
- AVAudioSession interruption handling must be robust

### Architectural Deep Dive: Lifecycle Handling

**Component Architecture for This Story:**

```
┌─────────────────────────────────────────────────────┐
│ PeachApp / ContentView                              │
│ - Observes scenePhase (.background, .active)        │
│ - Manages NavigationStack path                      │
│ - Coordinates app-wide lifecycle                    │
└────────────┬────────────────────────────────────────┘
             │
             │ scenePhase: .background
             ↓
┌─────────────────────────────────────────────────────┐
│ Navigation Path Reset                               │
│ - Pop to root (Start Screen)                        │
│ - Clear any modal presentations                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ TrainingScreen                                      │
│ - onDisappear calls trainingSession.stop()          │
│ - Already handles Settings/Profile navigation       │
└────────────┬────────────────────────────────────────┘
             │
             │ navigationLink tap OR onDisappear
             ↓
┌─────────────────────────────────────────────────────┐
│ TrainingSession                                     │
│ - stop() method                                     │
│ - Observes AVAudioSession.interruptionNotification  │
│ - Handles phone calls, headphone disconnect         │
└────────────┬────────────────────────────────────────┘
             │
             │ stop() or interruption
             ↓
┌─────────────────────────────────────────────────────┐
│ NotePlayer (SineWaveNotePlayer)                     │
│ - stop() releases audio resources                   │
│ - AVAudioEngine cleaned up                          │
└─────────────────────────────────────────────────────┘
```

**Lifecycle Scenarios to Handle:**

**Scenario 1: Navigation to Settings/Profile**
- User taps Settings or Profile button
- TrainingScreen.onDisappear fires
- trainingSession.stop() called
- Audio stops, state → idle
- Navigation proceeds to Settings/Profile
- Settings/Profile dismissal returns to Start Screen (already implemented)
- **Status**: Already 90% implemented, needs verification testing

**Scenario 2: App Backgrounding via Home Button**
- User presses home button
- scenePhase → .background
- ContentView detects background state
- Calls trainingSession.stop() (if training)
- Pops navigation to Start Screen
- User returns via app switcher
- scenePhase → .active
- Start Screen is showing
- **Status**: Needs implementation

**Scenario 3: Phone Call Interruption**
- Incoming call arrives
- AVAudioSession posts interruptionNotification (type: .began)
- TrainingSession observes notification
- Calls stop(), audio stops
- App may be backgrounded
- Call ends
- AVAudioSession posts interruptionNotification (type: .ended)
- If app foregrounded, user sees Start Screen
- **Status**: Needs implementation

**Scenario 4: Headphone Disconnect**
- User unplugs headphones
- AVAudioSession posts routeChangeNotification (reason: .oldDeviceUnavailable)
- TrainingSession observes notification
- Calls stop(), audio stops
- User sees current screen (Training Screen still visible)
- UX ambiguity: should this stop training?
- **Decision**: YES - per FR7 "headphone disconnect" is an interruption scenario
- **Status**: Needs implementation

**Scenario 5: Interruption During Feedback**
- User answers comparison
- handleAnswer() saves to dataStore
- State → showingFeedback
- Feedback displays
- User backgrounds app before feedback clears
- stop() called
- Data already saved ✅
- **Status**: Should work, needs verification testing

### Implementation Strategy

**Phase 1: Verify Current Implementation (AC#1)**
- Test navigation to Settings - does stop() fire?
- Test navigation to Profile - does stop() fire?
- Verify incomplete comparison not saved
- Document what already works

**Phase 2: Add ScenePhase Observer (AC#2, AC#3)**
- Add @Environment(\.scenePhase) to ContentView
- Detect .background transition
- Call trainingSession.stop() if needed
- Pop navigation to Start Screen
- Test backgrounding scenarios

**Phase 3: Add Audio Interruption Handling**
- Add AVAudioSession.interruptionNotification observer to TrainingSession
- Add AVAudioSession.routeChangeNotification observer for headphone disconnect
- Call stop() on interruptions
- Clean up observers in deinit

**Phase 4: Data Integrity Verification (AC#4)**
- Review TrainingSession.handleAnswer() - confirm data saves BEFORE showingFeedback
- Add tests for interruption during each state
- Verify data integrity in all scenarios

**Phase 5: Comprehensive Testing**
- Unit tests for lifecycle transitions
- Manual device tests for all interruption scenarios
- Edge case testing (rapid background/foreground, interruption during interruption)

### Testing Strategy

**Unit Tests:**

**Lifecycle State Tests:**
- Test: navigation away calls stop()
- Test: stop() during playingNote1 discards comparison
- Test: stop() during playingNote2 discards comparison
- Test: stop() during awaitingAnswer discards comparison
- Test: stop() during showingFeedback leaves saved data intact
- Test: stop() clears feedback state
- Test: stop() transitions state to idle

**Audio Interruption Tests:**
- Test: phone call notification triggers stop()
- Test: headphone disconnect triggers stop()
- Test: observers cleaned up on deinit
- Use mock notification center for testing

**Manual Device Tests (Required):**

**Background Scenarios:**
- Background via home button during playingNote1
- Background via home button during playingNote2
- Background via home button during awaitingAnswer
- Background via home button during showingFeedback
- Foreground - verify Start Screen shown
- Verify no data loss for answered comparisons
- Verify incomplete comparisons discarded

**Navigation Scenarios:**
- Tap Settings during training - verify stop, verify navigation
- Tap Profile during training - verify stop, verify navigation
- Settings → back to Start Screen
- Profile → back to Start Screen

**Audio Interruption Scenarios:**
- Simulate phone call (use another device to call test device)
- Answer call - verify training stopped
- Decline call - verify training stopped
- Unplug headphones during training
- Verify training stops

**Edge Cases:**
- Rapid background/foreground cycles
- Background during transition between states
- Double-tap navigation button
- Background → kill app → relaunch

### FR Coverage Map for This Story

| FR | Description | Story 3.4 Action |
|---|---|---|
| FR6 | User can stop training by navigating to Settings or Profile, or by leaving the app | Verify onDisappear triggers stop(); add scenePhase backgrounding |
| FR7 | System discards incomplete comparisons when interrupted | Verify stop() doesn't save incomplete data; test all scenarios |
| FR7a | System returns to Start Screen when foregrounded after backgrounding | Implement navigation path reset on scenePhase.active |

**Dependencies on Other FRs:**
- FR27 (Store comparison records) - Must verify data integrity during interruption
- FR29 (Data integrity across restarts) - SwiftData provides this, verify it works with interruptions

### What NOT To Do

- **Do NOT** add "Are you sure you want to stop?" confirmation dialogs
- **Do NOT** show "Training session incomplete" warnings
- **Do NOT** add session summaries on stop
- **Do NOT** save incomplete comparisons "for later" - they're discarded
- **Do NOT** try to resume training where user left off - always return to Start Screen
- **Do NOT** modify core TrainingSession state machine logic (it works, don't break it)
- **Do NOT** add visual "training paused" states - training is either active or stopped
- **Do NOT** implement "pause" functionality - Peach has no concept of paused sessions
- **Do NOT** add streak tracking or "you stopped early" messaging
- **Do NOT** complicate the stop() method - keep it simple and robust

### References

All technical details sourced from:

- [Source: docs/planning-artifacts/epics.md#Story 3.4] — User story, acceptance criteria (lines 394-420)
- [Source: docs/planning-artifacts/epics.md#Epic 3] — Epic objectives and FRs (lines 298-301, 168-170)
- [Source: docs/planning-artifacts/epics.md#FR6-FR7] — Functional requirements for interruption handling (lines 21-23)
- [Source: docs/planning-artifacts/architecture.md#Cross-Cutting Concerns] — Audio interruption as cross-cutting concern (lines 48-51, 363-369)
- [Source: docs/planning-artifacts/architecture.md#TrainingSession as Error Boundary] — Error handling philosophy (lines 248-261)
- [Source: docs/planning-artifacts/architecture.md#Navigation Model] — Hub-and-spoke navigation (lines 364-392)
- [Source: docs/planning-artifacts/ux-design-specification.md#The Comparison Loop Step 7] — Leaving/interruption UX (lines 357-361)
- [Source: docs/planning-artifacts/ux-design-specification.md#Respect Incidental Time] — Instant stop principle (lines 103-105)
- [Source: docs/planning-artifacts/ux-design-specification.md#Interruption Pattern] — Unified interruption handling (lines 625-628)
- [Source: docs/planning-artifacts/ux-design-specification.md#Journey 4: Return After Break] — No welcome-back messaging (lines 566-584)
- [Source: docs/planning-artifacts/prd.md#NFR10-NFR11] — Data integrity requirements (lines 73-74)
- [Source: docs/implementation-artifacts/3-3-training-screen-ui-with-higher-lower-buttons-and-feedback.md] — Previous story context, TrainingScreen.onDisappear (lines 79-82)
- [Source: Peach/Training/TrainingSession.swift] — Current stop() implementation, state machine
- [Source: Peach/Training/TrainingScreen.swift] — Current lifecycle hooks (onAppear/onDisappear)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

