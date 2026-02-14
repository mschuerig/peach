# Story 4.2: Implement NextNoteStrategy Protocol and AdaptiveNoteStrategy

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want the app to intelligently choose which comparisons to present,
So that every comparison maximally improves my pitch discrimination.

## Acceptance Criteria

1. **Given** a NextNoteStrategy protocol, **When** it is defined, **Then** it exposes a method that takes the PerceptualProfile and current settings and returns a Comparison (note1, note2, centDifference)

2. **Given** an AdaptiveNoteStrategy (implementing NextNoteStrategy), **When** the user answers correctly, **Then** the next comparison at that note uses a narrower cent difference (harder)

3. **Given** an AdaptiveNoteStrategy, **When** the user answers incorrectly, **Then** the next comparison at that note uses a wider cent difference (easier)

4. **Given** an AdaptiveNoteStrategy, **When** selecting the next comparison, **Then** it balances between training nearby the current pitch region and jumping to weak spots, controlled by a tunable ratio (Natural vs. Mechanical)

5. **Given** a new user with no training history, **When** comparisons are generated, **Then** they use random note selection at 100 cents (1 semitone) with all notes treated as weak (cold start)

6. **Given** the AdaptiveNoteStrategy, **When** cent differences are computed, **Then** fractional cent precision (0.1 cent resolution) is supported with a practical floor of approximately 1 cent

7. **Given** the AdaptiveNoteStrategy, **When** unit tests are run, **Then** difficulty adjustment, weak spot targeting, cold start behavior, and Natural/Mechanical balance are verified

## Tasks / Subtasks

- [x] Task 1: Define NextNoteStrategy Protocol and Comparison Type (AC: #1)
  - [x] Create NextNoteStrategy.swift in Core/Algorithm/
  - [x] Define Comparison struct (note1, note2, centDifference)
  - [x] Define protocol method: nextComparison(profile:, settings:) -> Comparison
  - [x] Document protocol contract and boundary
  - [x] Add protocol to project structure

- [x] Task 2: Implement AdaptiveNoteStrategy Cold Start Behavior (AC: #5)
  - [x] Create AdaptiveNoteStrategy.swift in Core/Algorithm/
  - [x] Implement init() with default algorithm parameters
  - [x] Implement cold start detection (all notes untrained)
  - [x] Random note selection across MIDI range 0-127
  - [x] Fixed 100 cent difference for cold start comparisons
  - [x] Add logging for cold start state

- [x] Task 3: Implement Difficulty Adjustment Logic (AC: #2, #3, #6)
  - [x] Track per-note difficulty state (current cent threshold)
  - [x] Implement narrowing logic on correct answer (e.g., multiply by 0.8)
  - [x] Implement widening logic on incorrect answer (e.g., multiply by 1.3)
  - [x] Enforce practical floor of ~1 cent
  - [x] Support fractional cent precision (0.1 cent resolution)
  - [x] Add difficulty bounds (min/max cent difference)

- [x] Task 4: Implement Weak Spot Targeting (AC: #4)
  - [x] Read weak spots from PerceptualProfile
  - [x] Implement Natural vs. Mechanical ratio (tunable parameter)
  - [x] Selection logic: % chance to pick weak spot vs. nearby note
  - [x] "Nearby" strategy: select notes near previous comparison
  - [x] "Weak spot" strategy: select from profile.weakSpots(count:)
  - [x] Ensure all notes within configured range

- [x] Task 5: Implement Settings Integration
  - [x] Read note range bounds from settings (min/max MIDI note)
  - [x] Filter weak spots and nearby notes to range
  - [x] Read Natural vs. Mechanical slider value (0.0 = all nearby, 1.0 = all weak spots)
  - [x] Handle range changes gracefully (no crashes if narrow range)
  - [x] Default values if settings unavailable

- [x] Task 6: Implement nextComparison() Orchestration Logic
  - [x] Check cold start condition (profile all untrained)
  - [x] If cold start → random selection at 100 cents
  - [x] If trained → apply Natural/Mechanical balance
  - [x] Select note (weak spot or nearby based on ratio)
  - [x] Determine cent difference (from difficulty state or profile)
  - [x] Generate Comparison with note1, note2 (same as note1), centDifference
  - [x] Update internal tracking state (last note selected, difficulty)
  - [x] Add comprehensive logging for transparency

- [x] Task 7: Comprehensive Unit Tests (AC: #7)
  - [x] Test cold start: all notes untrained → random at 100 cents
  - [x] Test difficulty adjustment: correct → narrower, incorrect → wider
  - [x] Test fractional cent precision and 1-cent floor
  - [x] Test weak spot targeting: profile with weak/strong notes
  - [x] Test Natural/Mechanical balance: 0.0, 0.5, 1.0 ratios
  - [x] Test note range filtering with various bounds
  - [x] Test edge cases: single note range, empty weak spots
  - [x] Use mock PerceptualProfile for deterministic testing

## Dev Notes

### 🎯 CRITICAL CONTEXT: The Decision Engine of Peach's Adaptive Training

**This story implements the CORE INTELLIGENCE** that makes Peach fundamentally different from static ear training apps. The AdaptiveNoteStrategy IS the adaptive algorithm — it reads the user's PerceptualProfile (Story 4.1) and decides what comparison to present next to maximize learning.

**What makes this story critical:**
- **🧠 Intelligent Selection**: Chooses comparisons based on user's actual strengths/weaknesses
- **🎯 Weak Spot Targeting**: Focuses training on notes the user struggles with
- **📈 Difficulty Adaptation**: Automatically adjusts comparison difficulty based on performance
- **🌱 Cold Start Handling**: Works perfectly for brand new users with zero data
- **⚖️ Natural vs. Mechanical Balance**: User-controllable between exploratory (nearby notes) and focused (weak spots) training

**The UX Principle**: "Training, not testing" means intelligent selection that builds skill efficiently. This component makes that happen.

### Story Context Within Epic 4

**Epic 4: Smart Training — Adaptive Algorithm** — The system intelligently selects comparisons based on user strengths/weaknesses

- **Story 4.1 (done)**: Implement PerceptualProfile — the data structure tracking user's pitch discrimination ability
- **Story 4.2 (this story)**: Implement NextNoteStrategy protocol and AdaptiveNoteStrategy — READS profile and DECIDES comparisons
- **Story 4.3 (next)**: Integrate adaptive algorithm into TrainingSession — REPLACES random placeholder with real intelligence

**Why This Story Comes Now:**

From **Architecture Document** (architecture.md lines 168-175):
```
Implementation Sequence:
1. Data model + TrainingDataStore ✅ Story 1.2 DONE
2. PerceptualProfile ✅ Story 4.1 DONE
3. NotePlayer protocol + SineWaveNotePlayer ✅ Story 2.1 DONE
4. NextNoteStrategy protocol + AdaptiveNoteStrategy ← THIS STORY
5. TrainingSession integration (Story 4.3) — will use AdaptiveNoteStrategy
6. UI layer (observes TrainingSession)
```

**Dependencies:**
- **Story 4.1 (done)**: PerceptualProfile — this story READS from it via weakSpots() and statsForNote()
- **Story 1.2 (done)**: No direct dependency on TrainingDataStore (profile handles data)
- **Story 3.2 (done)**: TrainingSession exists but uses random placeholder — Story 4.3 will replace it with AdaptiveNoteStrategy

**User Impact:**
- Without this story: Training uses random comparisons at 100 cents (current Story 3.2 behavior)
- With this story: Foundation exists for intelligent comparison selection (activated in Story 4.3)
- User won't see immediate change — this is pure infrastructure for Story 4.3 integration

### Requirements from Epic and PRD

**From Epics (epics.md lines 457-492):**

**Story 4.2 Acceptance Criteria (already extracted above):**
- AC1: NextNoteStrategy protocol with nextComparison(profile:, settings:) method
- AC2: Correct answer → narrower cent difference (harder)
- AC3: Incorrect answer → wider cent difference (easier)
- AC4: Natural vs. Mechanical balance between nearby and weak spot training
- AC5: Cold start at 100 cents with random selection, all notes weak
- AC6: Fractional cent precision (0.1 cent), practical floor ~1 cent
- AC7: Comprehensive unit tests covering all behaviors

**Functional Requirements Addressed:**

- **FR9** (epics.md line 122): "System selects next comparison based on user's perceptual profile"
  - **This story**: Implements the selection logic using profile.weakSpots() and profile.statsForNote()
  - **Story 4.1**: Provided PerceptualProfile data structure
  - **Story 4.3**: Integrates AdaptiveNoteStrategy into TrainingSession

- **FR10** (epics.md line 123): "System adjusts comparison difficulty based on answer correctness — narrower on correct, wider on wrong"
  - **This story**: Implements difficulty adjustment algorithm (multiply by factor on each answer)
  - **Story 4.3**: Calls strategy after each answer to get next comparison with adjusted difficulty

- **FR11** (epics.md line 124): "System balances between training nearby the current pitch region and jumping to weak spots, controlled by a tunable ratio"
  - **This story**: Implements Natural vs. Mechanical slider logic (0.0 = nearby, 1.0 = weak spots)
  - **Epic 6**: Settings Screen will expose the slider

- **FR12** (epics.md line 125): "System initializes new users with random comparisons at 100 cents with all notes treated as weak"
  - **This story**: Implements cold start detection and random selection at 100 cents
  - **Story 4.1**: PerceptualProfile treats untrained notes as weak spots

- **FR14** (epics.md line 127): "System supports fractional cent precision (0.1 cent resolution) with a practical floor of approximately 1 cent"
  - **This story**: Implements fractional cent math and 1-cent floor enforcement

- **FR15** (epics.md line 128): "System exposes algorithm parameters for adjustment during development and testing"
  - **This story**: All algorithm parameters (difficulty factors, range bounds, balance ratio) are tunable

**Non-Functional Requirements:**

- **NFR2** (prd.md line 64): "Next comparison begins immediately after answer — no perceptible delay"
  - **Implication**: AdaptiveNoteStrategy.nextComparison() must be fast (< 1ms)
  - **Strategy**: In-memory computation only, no database queries, simple math

### Technical Stack — Exact Versions & Frameworks

Continuing from Story 4.1:
- **Xcode:** 26.2
- **Swift:** 6.0
- **iOS Deployment Target:** iOS 26
- **State Management:** @Observable macro for SwiftUI integration (if needed for settings observation)
- **Testing Framework:** Swift Testing (@Test, #expect())
- **Dependencies:** PerceptualProfile from Story 4.1

**New in This Story:**
- First protocol in Core/Algorithm/ directory
- First implementation of comparison selection algorithm
- First integration with settings system (@AppStorage values)
- Mathematical algorithms: difficulty adjustment, random selection, weighted probability

### Architecture Compliance Requirements

**From Architecture Document:**

**Service Boundaries** (architecture.md lines 332):

```
NextNoteStrategy — knows about the perceptual profile and settings.
Returns a Comparison value type (note1, note2, centDifference).
Has no concept of audio playback or UI.
Boundary: reads profile, produces comparison.
```

**What This Means:**
- ✅ AdaptiveNoteStrategy reads PerceptualProfile (via protocol parameter)
- ✅ It reads settings (note range, Natural/Mechanical ratio, reference pitch)
- ✅ It returns Comparison struct (note1, note2, centDifference)
- ❌ It does NOT play audio (NotePlayer's job)
- ❌ It does NOT persist data (TrainingDataStore's job)
- ❌ It does NOT update profile (PerceptualProfile's job via TrainingSession)
- ❌ It does NOT render UI

**Data Flow** (architecture.md lines 157-163):

```
2. Training loop: NextNoteStrategy reads PerceptualProfile → selects comparison →
   TrainingSession tells NotePlayer to play note 1, then note 2 → user answers →
   result written to TrainingDataStore → PerceptualProfile updated incrementally
```

**Implementation Requirements:**
1. **Input**: PerceptualProfile (read-only access), Settings (note range, Natural/Mechanical)
2. **Output**: Comparison struct (note1, note2, centDifference)
3. **State**: Internal tracking of difficulty per note, last selected note
4. **No side effects**: Pure function (except internal state mutation for difficulty tracking)

**Project Organization** (architecture.md lines 205-207, 292-293):

```
Peach/
├── Core/
│   └── Algorithm/
│       ├── NextNoteStrategy.swift  ← THIS STORY CREATES THIS
│       └── AdaptiveNoteStrategy.swift  ← THIS STORY CREATES THIS
```

**Naming Conventions** (architecture.md lines 185-193):

- Protocol: `NextNoteStrategy` (noun describing capability, not "NextNoteStrategyProtocol")
- Implementation: `AdaptiveNoteStrategy` (descriptive prefix)
- Struct: `Comparison` (value type for comparison data)
- Method: `nextComparison(profile:settings:)` (camelCase with clear parameters)
- File: `NextNoteStrategy.swift`, `AdaptiveNoteStrategy.swift` (match type names)

**Dependency Injection** (architecture.md lines 162-164):

AdaptiveNoteStrategy will be injected into TrainingSession (in Story 4.3):
```swift
init(notePlayer: NotePlayer,
     dataStore: TrainingDataStore,
     profile: PerceptualProfile,
     noteStrategy: NextNoteStrategy) {  ← Story 4.3 adds this
    ...
}
```

### Algorithm Deep Dive: Adaptive Comparison Selection

**Core Algorithm Components:**

#### 1. Comparison Data Structure

```swift
struct Comparison {
    let note1: Int          // MIDI note (0-127) - reference note
    let note2: Int          // MIDI note (same as note1 in current design)
    let centDifference: Double  // Cent offset applied to note2
}
```

**Why note2 == note1?**
- Current design: both notes are the same MIDI note, only frequency differs by cents
- This simplifies the perceptual task: user discriminates pitch shift, not interval recognition
- Future enhancement: could use different notes for interval training

#### 2. Cold Start Algorithm (AC#5)

**Detection:**
```swift
// Cold start if ALL notes in profile are untrained
let isColdStart = profile.allNotesUntrained
```

**Behavior:**
```swift
if isColdStart {
    let randomNote = Int.random(in: settings.noteRangeMin...settings.noteRangeMax)
    return Comparison(note1: randomNote, note2: randomNote, centDifference: 100.0)
}
```

**Rationale:**
- 100 cents = 1 semitone = easily perceptible for all users
- Random note selection ensures even initial sampling across range
- All notes treated as weak spots (per FR12)

#### 3. Difficulty Adjustment Algorithm (AC#2, AC#3, AC#6)

**State Tracking:**
```swift
// Internal state in AdaptiveNoteStrategy
private var difficultyState: [Int: Double] = [:]  // MIDI note -> current cent threshold

func currentDifficulty(for note: Int) -> Double {
    difficultyState[note] ?? 100.0  // Default to 100 cents if untrained
}
```

**Adjustment Logic:**
```swift
func updateDifficulty(for note: Int, wasCorrect: Bool) {
    let current = currentDifficulty(for: note)

    if wasCorrect {
        // Make harder: narrow the difference
        let newDifficulty = max(current * 0.8, 1.0)  // Floor at 1 cent
        difficultyState[note] = newDifficulty
    } else {
        // Make easier: widen the difference
        let newDifficulty = min(current * 1.3, 100.0)  // Cap at 100 cents
        difficultyState[note] = newDifficulty
    }
}
```

**Rationale:**
- **0.8 factor** on correct: gradually narrows difficulty (20% harder each time)
- **1.3 factor** on incorrect: quickly widens difficulty (30% easier) for confidence building
- **1.0 cent floor**: practical limit of human pitch discrimination
- **100 cent cap**: maintains reasonable upper bound (1 semitone)
- **Fractional precision**: Swift Double supports 0.1 cent resolution natively

**Alternative Approaches Considered:**
- Additive adjustment (+/- 5 cents): too coarse, doesn't scale well
- Exponential decay: too complex, multiplicative is simpler and effective
- Per-answer adjustment vs. moving average: per-answer is simpler, profile already tracks average

#### 4. Weak Spot Targeting Algorithm (AC#4)

**Natural vs. Mechanical Balance:**

The "Natural/Mechanical" slider (0.0 to 1.0) controls training focus:
- **0.0 (Natural)**: 100% nearby notes — exploratory, region-focused training
- **0.5 (Balanced)**: 50/50 mix of nearby and weak spot jumps
- **1.0 (Mechanical)**: 100% weak spots — laser-focused on weaknesses

**Selection Logic:**
```swift
func selectNote(profile: PerceptualProfile, settings: Settings) -> Int {
    let mechanicalRatio = settings.naturalVsMechanical  // 0.0 to 1.0

    // Weighted random: % chance to pick weak spot vs. nearby
    if Double.random(in: 0...1) < mechanicalRatio {
        // Pick weak spot
        let weakSpots = profile.weakSpots(count: 10)
        let filtered = weakSpots.filter { settings.isInRange($0) }
        return filtered.randomElement() ?? settings.noteRangeMin
    } else {
        // Pick nearby note
        let nearby = nearbyNotes(around: lastSelectedNote, range: 12)  // Within 1 octave
        let filtered = nearby.filter { settings.isInRange($0) }
        return filtered.randomElement() ?? lastSelectedNote
    }
}
```

**Nearby Note Strategy:**
```swift
func nearbyNotes(around note: Int, range: Int) -> [Int] {
    let min = max(0, note - range)
    let max = min(127, note + range)
    return Array(min...max)
}
```

**Rationale:**
- **Weighted probability**: simple, tunable, transparent
- **Nearby = ±12 semitones**: one octave range keeps training regionally focused
- **Weak spots from profile**: leverages PerceptualProfile.weakSpots(count:) from Story 4.1
- **Range filtering**: ensures all selections respect user's configured note range

#### 5. Settings Integration

**Required Settings:**
```swift
struct TrainingSettings {
    var noteRangeMin: Int = 36       // Default: C2 (MIDI 36)
    var noteRangeMax: Int = 84       // Default: C6 (MIDI 84)
    var naturalVsMechanical: Double = 0.5  // Default: balanced
    var referencePitch: Double = 440.0     // Default: A4 = 440Hz (not used in this story)
}
```

**Integration Point:**
- Story 4.2: AdaptiveNoteStrategy READS settings via parameter
- Epic 6: Settings Screen WRITES settings via @AppStorage
- Story 4.3: TrainingSession passes settings to nextComparison()

**Default Values:**
- Note range: C2 to C6 (36-84) — typical vocal/instrument range
- Natural/Mechanical: 0.5 — balanced between exploration and weak spot focus
- Reference pitch: 440Hz — standard concert pitch

### Learnings from Story 4.1

**From Story 4.1 (PerceptualProfile Implementation):**

**1. Protocol-Based Design:**

Story 4.1 initially used a concrete TrainingDataStore dependency, then refactored to pure statistical aggregator. AdaptiveNoteStrategy should learn from this:
- ✅ Use NextNoteStrategy protocol for abstraction
- ✅ Keep AdaptiveNoteStrategy testable with mock PerceptualProfile
- ✅ No direct SwiftData or TrainingDataStore dependencies

**2. @Observable Pattern:**

Story 4.1 used @Observable for PerceptualProfile. AdaptiveNoteStrategy might NOT need @Observable if it's purely computational:
- **If stateless**: No @Observable needed (pure function)
- **If stateful** (tracking difficulty, last note): Use @Observable OR private internal state
- **Decision**: Internal private state is sufficient — TrainingSession doesn't need to observe strategy internals

**3. Testing with Mocks:**

Story 4.1 created MockTrainingDataStore, then eliminated it after refactoring. AdaptiveNoteStrategy should:
- Create MockPerceptualProfile for deterministic testing
- Mock profile with known weak spots and trained notes
- Test all algorithm branches with controlled inputs

**4. Welford's Algorithm for Efficiency:**

Story 4.1 used Welford's online algorithm for O(1) incremental updates. AdaptiveNoteStrategy should:
- Keep nextComparison() fast — no complex math, no database queries
- Simple selection logic (random, weighted probability)
- Internal difficulty tracking is just dictionary lookup + multiply

**5. Swift 6 Concurrency:**

Story 4.1 used @MainActor for thread-safety. AdaptiveNoteStrategy:
- Will be called from TrainingSession (already @MainActor)
- No async operations needed
- Simple synchronous selection logic

**6. Comprehensive Logging:**

Story 4.1 added detailed logging. AdaptiveNoteStrategy should:
- Log selection decisions: weak spot vs. nearby, chosen note, cent difference
- Log cold start state
- Log difficulty adjustments
- Use os.Logger with appropriate subsystem

**7. File Organization:**

Story 4.1 created Core/Profile/ directory. AdaptiveNoteStrategy creates Core/Algorithm/:
- Core/Algorithm/NextNoteStrategy.swift (protocol)
- Core/Algorithm/AdaptiveNoteStrategy.swift (implementation)
- PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift

### Integration Points

**PerceptualProfile Interface (from Story 4.1):**

```swift
// AdaptiveNoteStrategy will READ from these:
let weakSpots = profile.weakSpots(count: 10)  // Returns [Int] (MIDI notes)
let noteStats = profile.statsForNote(60)      // Returns PerceptualNote struct
let isTrained = noteStats.isTrained           // Bool: has training data?
let threshold = noteStats.mean                // Double: detection threshold in cents
```

**Settings Interface:**

```swift
// Story 4.2: Read from settings parameter
// Epic 6: Settings written via @AppStorage in SettingsScreen
func nextComparison(profile: PerceptualProfile, settings: TrainingSettings) -> Comparison {
    let range = settings.noteRangeMin...settings.noteRangeMax
    let mechanicalRatio = settings.naturalVsMechanical
    ...
}
```

**TrainingSession Integration (Story 4.3 will implement):**

```swift
// In TrainingSession
let strategy: NextNoteStrategy = AdaptiveNoteStrategy()

func startNextComparison() async {
    let comparison = strategy.nextComparison(profile: profile, settings: currentSettings)
    await notePlayer.play(note: comparison.note1, ...)
    await notePlayer.play(note: comparison.note2, centOffset: comparison.centDifference, ...)
}

func handleAnswer(isCorrect: Bool) {
    // Update difficulty (if strategy exposes method)
    strategy.updateDifficulty(for: currentComparison.note1, wasCorrect: isCorrect)
    // Update profile
    profile.update(note: currentComparison.note1, centOffset: currentComparison.centDifference, isCorrect: isCorrect)
    // Next comparison
    startNextComparison()
}
```

### Testing Strategy

**Unit Test Structure:**

Create `PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift`

**Mock PerceptualProfile:**

```swift
class MockPerceptualProfile: PerceptualProfile {
    var mockWeakSpots: [Int] = []
    var mockTrainedNotes: Set<Int> = []

    override func weakSpots(count: Int) -> [Int] {
        Array(mockWeakSpots.prefix(count))
    }

    override func statsForNote(_ note: Int) -> PerceptualNote {
        if mockTrainedNotes.contains(note) {
            return PerceptualNote(mean: 50.0, stdDev: 10.0, sampleCount: 10, m2: 1000.0)
        } else {
            return PerceptualNote()  // Untrained
        }
    }
}
```

**Test Cases (AC#7):**

**1. Cold Start Behavior (AC#5):**
```swift
@Test func coldStartRandomAt100Cents() {
    let profile = MockPerceptualProfile()
    // All notes untrained (default)
    let strategy = AdaptiveNoteStrategy()
    let settings = TrainingSettings(noteRangeMin: 36, noteRangeMax: 84)

    let comparison = strategy.nextComparison(profile: profile, settings: settings)

    #expect(comparison.note1 >= 36 && comparison.note1 <= 84)  // Within range
    #expect(comparison.note2 == comparison.note1)              // Same note
    #expect(comparison.centDifference == 100.0)                // 1 semitone
}
```

**2. Difficulty Adjustment: Correct → Narrower (AC#2):**
```swift
@Test func correctAnswerNarrowsDifficulty() {
    let strategy = AdaptiveNoteStrategy()

    // Simulate correct answer
    strategy.updateDifficulty(for: 60, wasCorrect: true)

    let newDifficulty = strategy.currentDifficulty(for: 60)
    #expect(newDifficulty < 100.0)  // Harder than default 100 cents
    #expect(newDifficulty >= 1.0)   // Not below 1-cent floor
}
```

**3. Difficulty Adjustment: Incorrect → Wider (AC#3):**
```swift
@Test func incorrectAnswerWidensDifficulty() {
    let strategy = AdaptiveNoteStrategy()
    strategy.difficultyState[60] = 10.0  // Start at 10 cents

    strategy.updateDifficulty(for: 60, wasCorrect: false)

    let newDifficulty = strategy.currentDifficulty(for: 60)
    #expect(newDifficulty > 10.0)  // Easier than before
}
```

**4. Fractional Cent Precision and Floor (AC#6):**
```swift
@Test func fractionalCentPrecisionAndFloor() {
    let strategy = AdaptiveNoteStrategy()
    strategy.difficultyState[60] = 1.5  // Start at 1.5 cents

    strategy.updateDifficulty(for: 60, wasCorrect: true)  // 1.5 * 0.8 = 1.2

    let newDifficulty = strategy.currentDifficulty(for: 60)
    #expect(newDifficulty == 1.2)  // Fractional precision supported

    // Keep narrowing to test floor
    strategy.updateDifficulty(for: 60, wasCorrect: true)  // 1.2 * 0.8 = 0.96 → floor to 1.0

    let flooredDifficulty = strategy.currentDifficulty(for: 60)
    #expect(flooredDifficulty == 1.0)  // Floor enforced
}
```

**5. Weak Spot Targeting (AC#4):**
```swift
@Test func weakSpotTargeting() {
    let profile = MockPerceptualProfile()
    profile.mockWeakSpots = [60, 62, 64]  // C4, D4, E4 are weak
    profile.mockTrainedNotes = [48, 50, 52]  // C3, D3, E3 are trained

    let strategy = AdaptiveNoteStrategy()
    let settings = TrainingSettings(
        noteRangeMin: 36,
        noteRangeMax: 84,
        naturalVsMechanical: 1.0  // 100% weak spots
    )

    let comparison = strategy.nextComparison(profile: profile, settings: settings)

    // Should pick from weak spots (60, 62, or 64)
    #expect([60, 62, 64].contains(comparison.note1))
}
```

**6. Natural vs. Mechanical Balance (AC#4):**
```swift
@Test func naturalVsMechanicalBalance() {
    let profile = MockPerceptualProfile()
    profile.mockWeakSpots = [72, 74, 76]  // High notes weak

    let strategy = AdaptiveNoteStrategy()
    strategy.lastSelectedNote = 48  // Last note was C3

    let settingsNatural = TrainingSettings(naturalVsMechanical: 0.0)
    let settingsMechanical = TrainingSettings(naturalVsMechanical: 1.0)

    // Test multiple selections to verify statistical balance
    var nearbyCount = 0
    var weakSpotCount = 0

    for _ in 0..<100 {
        let comparison = strategy.nextComparison(profile: profile, settings: settingsNatural)
        if (48 - 12)...(48 + 12) ~= comparison.note1 {
            nearbyCount += 1
        }
    }

    #expect(nearbyCount > 90)  // 0.0 ratio → mostly nearby

    for _ in 0..<100 {
        let comparison = strategy.nextComparison(profile: profile, settings: settingsMechanical)
        if [72, 74, 76].contains(comparison.note1) {
            weakSpotCount += 1
        }
    }

    #expect(weakSpotCount > 90)  // 1.0 ratio → mostly weak spots
}
```

**7. Note Range Filtering:**
```swift
@Test func noteRangeFiltering() {
    let profile = MockPerceptualProfile()
    profile.mockWeakSpots = [30, 60, 90]  // Notes outside and inside range

    let strategy = AdaptiveNoteStrategy()
    let settings = TrainingSettings(
        noteRangeMin: 48,   // C3
        noteRangeMax: 72,   // C5
        naturalVsMechanical: 1.0  // Target weak spots
    )

    let comparison = strategy.nextComparison(profile: profile, settings: settings)

    #expect(comparison.note1 >= 48)
    #expect(comparison.note1 <= 72)
    // Should only pick 60 (the only weak spot in range)
    #expect(comparison.note1 == 60)
}
```

**8. Edge Case: Single Note Range:**
```swift
@Test func singleNoteRange() {
    let profile = MockPerceptualProfile()
    let strategy = AdaptiveNoteStrategy()
    let settings = TrainingSettings(noteRangeMin: 60, noteRangeMax: 60)  // Only C4

    let comparison = strategy.nextComparison(profile: profile, settings: settings)

    #expect(comparison.note1 == 60)  // Must be the only note
    #expect(comparison.note2 == 60)
}
```

### What NOT To Do

- **Do NOT** implement audio playback — that's NotePlayer's responsibility
- **Do NOT** persist difficulty state to database — it's ephemeral session state (or derived from profile in future)
- **Do NOT** update PerceptualProfile — TrainingSession handles that in Story 4.3
- **Do NOT** integrate into TrainingSession yet — that's Story 4.3
- **Do NOT** create Settings Screen — that's Epic 6
- **Do NOT** over-engineer probability distributions — simple weighted random is sufficient
- **Do NOT** implement machine learning or Bayesian models — stick to deterministic difficulty adjustment
- **Do NOT** add multi-note intervals yet — keep note2 == note1 for MVP
- **Do NOT** implement temporal patterns (e.g., "avoid repeating same note") — keep it simple
- **Do NOT** add performance analytics or logging to external systems — os.Logger only

### FR Coverage Map for This Story

| FR | Description | Story 4.2 Action |
|---|---|---|
| FR9 | System selects next comparison based on perceptual profile | Implement nextComparison() reading profile.weakSpots() |
| FR10 | Difficulty adjustment on correctness | Implement updateDifficulty() with multiply factors |
| FR11 | Natural vs. Mechanical balance | Implement weighted probability selection |
| FR12 | Cold start at 100 cents, all notes weak | Implement isColdStart detection and random selection |
| FR14 | Fractional cent precision, ~1 cent floor | Implement with Swift Double and max(1.0) floor |
| FR15 | Expose algorithm parameters | Make all factors (0.8, 1.3, range) tunable properties |

**Dependencies on Other FRs:**
- FR13 (Profile continuity) — Story 4.1 provides persistent profile
- FR30-FR36 (Settings) — Epic 6 will create Settings Screen for Natural/Mechanical slider
- FR9-FR15 activation — Story 4.3 integrates AdaptiveNoteStrategy into TrainingSession

### Project Structure Notes

**New Directories Created:**

```
Peach/Core/Algorithm/
├── NextNoteStrategy.swift
└── AdaptiveNoteStrategy.swift
```

**Test Directory Created:**

```
PeachTests/Core/Algorithm/
└── AdaptiveNoteStrategyTests.swift
```

**Alignment with Architecture:**

From architecture.md lines 205-207, 292-293, Core/Algorithm/ is the designated location for comparison selection logic. This story creates the directory and first components.

**No Conflicts**: Algorithm layer is pure computation — no overlap with Audio (NotePlayer), Data (TrainingDataStore), or Profile (PerceptualProfile).

### References

All technical details sourced from:

- [Source: docs/planning-artifacts/epics.md#Story 4.2] — User story, acceptance criteria (lines 457-492)
- [Source: docs/planning-artifacts/epics.md#Epic 4] — Epic objectives and FRs (lines 421-424, 172-174)
- [Source: docs/planning-artifacts/epics.md#FR9-FR15] — Functional requirements for adaptive algorithm (lines 122-129)
- [Source: docs/planning-artifacts/architecture.md#Service Boundaries - NextNoteStrategy] — Component responsibility (lines 332)
- [Source: docs/planning-artifacts/architecture.md#Data Flow] — Training loop integration (lines 157-163)
- [Source: docs/planning-artifacts/architecture.md#Implementation Sequence] — Why NextNoteStrategy comes after PerceptualProfile (lines 168-175)
- [Source: docs/planning-artifacts/architecture.md#Dependency Injection] — How services are injected into TrainingSession (lines 162-164)
- [Source: docs/implementation-artifacts/4-1-implement-perceptualprofile.md] — PerceptualProfile interface and patterns (entire document)
- [Source: docs/planning-artifacts/prd.md#NFR2] — Performance requirement for immediate next comparison (line 64)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

N/A

### Completion Notes List

✅ **Task 1 Complete**: Defined NextNoteStrategy protocol with @MainActor annotation for Swift 6 concurrency compliance. Created TrainingSettings struct with default values (C2-C6 range, 0.5 Natural/Mechanical balance). Comparison struct already existed from Story 3.2, so protocol references it directly.

✅ **Task 2 Complete**: Implemented AdaptiveNoteStrategy with cold start detection (isColdStart checks all 128 MIDI notes for training data). Cold start returns random note within settings range at fixed 100 cent difficulty.

✅ **Task 3 Complete**: Implemented difficulty adjustment with narrowing factor 0.8 (correct answers) and widening factor 1.3 (incorrect answers). Enforced 1.0 cent floor and 100.0 cent ceiling. Fractional cent precision supported natively via Swift Double.

✅ **Task 4 Complete**: Implemented weak spot targeting using PerceptualProfile.weakSpots(count:10). Natural/Mechanical ratio uses weighted random selection (mechanicalRatio = probability of selecting weak spot vs nearby note). Nearby selection uses ±12 semitones range from last selected note.

✅ **Task 5 Complete**: Integrated TrainingSettings with note range filtering, Natural/Mechanical slider (0.0-1.0), and reference pitch. All selections filtered to settings.noteRangeMin...noteRangeMax. Graceful handling of narrow ranges (single note range works without crashing).

✅ **Task 6 Complete**: Orchestrated nextComparison() with cold start check → Natural/Mechanical selection → note selection → difficulty determination → Comparison generation. Internal tracking state maintains difficultyState dictionary and lastSelectedNote. Comprehensive logging via OSLog for transparency.

✅ **Task 7 Complete**: Created comprehensive unit test suite with tests for cold start, difficulty adjustment (narrowing, widening, floor, ceiling, fractional precision), weak spot targeting, Natural/Mechanical balance, note range filtering, and edge cases. Tests compile successfully.

✅ **Additional Fix**: Fixed TrainingSessionTests.swift tuple destructuring issues from Story 4.1 changes (added 4th PerceptualProfile element to all tuple destructuring calls).

### File List

- Peach/Core/Algorithm/NextNoteStrategy.swift (new)
- Peach/Core/Algorithm/AdaptiveNoteStrategy.swift (new)
- PeachTests/Core/Algorithm/AdaptiveNoteStrategyTests.swift (new)
- PeachTests/Training/TrainingSessionTests.swift (modified - fixed tuple destructuring)
