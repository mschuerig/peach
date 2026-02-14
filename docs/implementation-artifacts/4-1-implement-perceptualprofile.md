# Story 4.1: Implement PerceptualProfile

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want the app to build and maintain an accurate map of my pitch discrimination ability,
So that training targets my actual weaknesses.

## Acceptance Criteria

1. **Given** a PerceptualProfile, **When** it is initialized, **Then** it holds aggregate statistics (arithmetic mean, standard deviation of detection thresholds) indexed by MIDI note (0–127)

2. **Given** a TrainingDataStore with existing comparison records, **When** the app starts, **Then** the PerceptualProfile is loaded by aggregating all stored records into per-note statistics

3. **Given** a new comparison result is recorded during training, **When** the PerceptualProfile is updated, **Then** it updates incrementally (not by re-aggregating all records)

4. **Given** a PerceptualProfile, **When** queried for weak spots, **Then** it identifies notes with the largest detection thresholds (poorest discrimination)

5. **Given** the PerceptualProfile, **When** no data exists for a MIDI note, **Then** that note is treated as a weak spot (cold start assumption)

6. **Given** the PerceptualProfile, **When** unit tests are run, **Then** aggregation, incremental update, and weak spot identification are verified

## Tasks / Subtasks

- [x] Task 1: Define PerceptualProfile Data Structure (AC: #1, #5)
  - [x] Create PerceptualProfile.swift in Core/Profile/
  - [x] Define PerceptualNote struct to hold per-note statistics (mean, stdDev, sampleCount)
  - [x] Create 128-slot array indexed by MIDI note (0-127)
  - [x] Implement computed properties for weak spot identification
  - [x] Add @Observable conformance for SwiftUI integration
  - [x] Document cold start assumption (no data = weak spot)

- [x] Task 2: Implement Initial Aggregation from TrainingDataStore (AC: #2)
  - [x] Add init(from dataStore:) method
  - [x] Fetch all ComparisonRecord entries from TrainingDataStore
  - [x] Group records by note1 MIDI value
  - [x] Calculate per-note mean and standard deviation of cent differences
  - [x] Handle empty data gracefully (cold start state)
  - [x] Add logging for startup aggregation performance

- [x] Task 3: Implement Incremental Update (AC: #3)
  - [x] Add update(note:centOffset:isCorrect:) method
  - [x] Update only the affected MIDI note's statistics
  - [x] Use online/incremental algorithm for mean/stdDev (Welford's algorithm)
  - [x] Maintain sample count for confidence weighting
  - [x] Ensure thread-safety with @MainActor isolation

- [x] Task 4: Implement Weak Spot Identification (AC: #4, #5)
  - [x] Add weakSpots(count:) method
  - [x] Return notes with largest detection thresholds (highest mean)
  - [x] Treat untrained notes (sampleCount == 0) as weak spots with infinity priority
  - [x] Support configurable weak spot count (e.g., top 10)
  - [x] Note range filtering deferred to Story 4.3 integration

- [x] Task 5: Add Summary Statistics (Future: Epic 5)
  - [x] Add overallMean computed property (arithmetic mean across training range)
  - [x] Add overallStdDev computed property
  - [x] Filter by trained notes only
  - [x] Return nil for cold start (no data)

- [x] Task 6: Comprehensive Unit Tests (AC: #6)
  - [x] Test cold start initialization (empty dataStore)
  - [x] Test aggregation with sample data
  - [x] Test incremental update correctness
  - [x] Test weak spot identification with mixed data
  - [x] Test untrained notes treated as weak spots with highest priority
  - [x] Test summary statistics computation
  - [x] Use existing MockTrainingDataStore for isolation

## Dev Notes

### 🎯 CRITICAL CONTEXT: The Brain of Peach's Adaptive Algorithm

**This story lays the foundation for Epic 4** — the adaptive algorithm that makes Peach fundamentally different from traditional ear training apps. The PerceptualProfile is the "memory" that tracks what the user can and cannot hear, enabling intelligent comparison selection.

**What makes this story critical:**
- **🧠 Core Intelligence**: This IS the adaptive algorithm's knowledge base — everything else builds on it
- **💾 Data Foundation**: Converts raw comparison history into actionable pitch discrimination intelligence
- **🎯 Weak Spot Targeting**: Enables the algorithm to focus training where it matters most
- **📊 Profile Visualization**: Epic 5 will display this data — the structure must support rich visualization
- **⚡ Performance-Critical**: Loaded on app startup and updated after every comparison — must be fast

**The UX Principle**: "Training, not testing" means the app must KNOW what you're bad at and relentlessly target it. This component makes that possible.

### Story Context Within Epic 4

**Epic 4: Smart Training — Adaptive Algorithm** — The system intelligently selects comparisons based on user strengths/weaknesses

- **Story 4.1 (this story)**: Implement PerceptualProfile — the data structure and aggregation logic
- **Story 4.2**: Implement NextNoteStrategy protocol and AdaptiveNoteStrategy — uses PerceptualProfile to choose comparisons
- **Story 4.3**: Integrate adaptive algorithm into TrainingSession — replaces random placeholder with real intelligence

**Why This Story Comes First:**

From **Architecture Document** (architecture.md lines 166-175):
```
Implementation Sequence:
1. Data model + TrainingDataStore (foundation — everything depends on it) ✅ Story 1.2 DONE
2. PerceptualProfile (aggregation logic, startup loading) ← THIS STORY
3. NotePlayer protocol + SineWaveNotePlayer ✅ Story 2.1 DONE
4. NextNoteStrategy protocol + AdaptiveNoteStrategy (depends on PerceptualProfile)
5. TrainingSession (integrates all services) — already exists, will be enhanced
6. UI layer (observes TrainingSession and PerceptualProfile)
```

**Dependencies:**
- **Story 1.2 (done)**: ComparisonRecord data model and TrainingDataStore — this story reads from it
- **Story 2.1 (done)**: No dependency (audio is independent)
- **Story 3.2 (done)**: TrainingSession state machine — will use PerceptualProfile in Story 4.3

**User Impact:**
- Without this story: Training uses random comparisons at 100 cents (current behavior from Story 3.2)
- With this story: Foundation exists for intelligent comparison selection (activated in Story 4.3)
- User won't see immediate change — this is pure infrastructure for Stories 4.2-4.3

### Requirements from Epic and PRD

**From Epics (epics.md lines 425-456):**

**Story 4.1 Acceptance Criteria (already extracted above):**
- AC1: Holds aggregate statistics indexed by MIDI note 0-127
- AC2: Loaded from TrainingDataStore on app startup
- AC3: Updates incrementally, not by re-aggregating
- AC4: Identifies weak spots (largest detection thresholds)
- AC5: Untrained notes treated as weak spots (cold start)
- AC6: Comprehensive unit tests

**Functional Requirements Addressed:**

- **FR9** (prd.md line 260): "System selects next comparison based on user's perceptual profile"
  - **This story**: Builds the perceptual profile data structure
  - **Story 4.2**: Uses it for comparison selection

- **FR12** (prd.md line 262): "System initializes new users with random comparisons at 100 cents with all notes treated as weak"
  - **This story**: Implements cold start assumption (no data = weak spot)
  - **Story 4.2**: Implements random selection for weak spots

- **FR13** (prd.md line 263): "System maintains perceptual profile across sessions without requiring explicit save or resume"
  - **This story**: Loads from persisted ComparisonRecords on startup
  - **Data persistence**: Already handled by TrainingDataStore (Story 1.2)

- **FR26** (prd.md line 282): "System computes perceptual profile from stored per-answer data"
  - **This story**: Implements aggregation from ComparisonRecord entries

**Non-Functional Requirements:**

- **NFR4** (prd.md line 67): "App launch to training-ready < 2 seconds"
  - **Implication**: Initial aggregation from TrainingDataStore must be fast
  - **Strategy**: In-memory structure, efficient aggregation, profile built during app init

- **NFR5** (prd.md line 68): "Profile Screen rendering < 1 second"
  - **Implication**: PerceptualProfile must expose data efficiently for visualization
  - **Strategy**: Pre-computed statistics, indexed access by MIDI note

### Technical Stack — Exact Versions & Frameworks

Continuing from Stories 1.2, 2.1, 3.1-3.4:
- **Xcode:** 26.2
- **Swift:** 6.0
- **iOS Deployment Target:** iOS 26
- **Data Framework:** SwiftData (for reading ComparisonRecords)
- **State Management:** @Observable macro for SwiftUI integration
- **Testing Framework:** Swift Testing (@Test, #expect())
- **Async/Concurrency:** Swift structured concurrency (async/await)

**New in This Story:**
- First component in Core/Profile/ directory
- First statistical computation (mean, standard deviation)
- First use of incremental/online algorithms (for efficient updates)
- Data structure sized to MIDI note range (128 slots, 0-127)

### Architecture Compliance Requirements

**From Architecture Document:**

**Service Boundaries** (architecture.md lines 329-346):

```
- PerceptualProfile — Pure computation. Aggregates comparison data into per-MIDI-note statistics.
  No persistence, no UI awareness.
  Boundary: receives comparison results, exposes detection thresholds.
```

**What This Means:**
- ✅ PerceptualProfile computes and stores statistics
- ✅ It reads from TrainingDataStore (via init)
- ✅ It receives updates from TrainingSession (via update method)
- ❌ It does NOT persist data directly (TrainingDataStore handles persistence)
- ❌ It does NOT render UI (ProfileScreen will read from it in Epic 5)
- ❌ It does NOT select comparisons (NextNoteStrategy will do that in Story 4.2)

**Data Flow** (architecture.md lines 157-163):

```
1. App startup: TrainingDataStore → all comparison records → PerceptualProfile (full aggregation)
2. Training loop: NextNoteStrategy reads PerceptualProfile → selects comparison → ... →
   result written to TrainingDataStore → PerceptualProfile updated incrementally
3. Profile Screen: reads PerceptualProfile for visualization and summary statistics
```

**Implementation Requirements:**
1. **Startup**: PerceptualProfile init must fetch ALL ComparisonRecords and aggregate into per-note stats
2. **Training**: TrainingSession will call update() after each comparison (Story 4.3)
3. **Visualization**: Epic 5 will read per-note statistics for display

**Project Organization** (architecture.md lines 194-226):

```
Peach/
├── Core/
│   └── Profile/
│       └── PerceptualProfile.swift  ← THIS STORY CREATES THIS
```

**Naming Conventions** (architecture.md lines 185-193):

- Type: `PerceptualProfile` (PascalCase)
- Properties: `weakSpots`, `overallMean`, `overallStdDev` (camelCase)
- Methods: `update(with:isCorrect:)` (camelCase with clear parameters)
- File: `PerceptualProfile.swift` (matches type name)

**SwiftUI Integration** (architecture.md lines 262-268):

- Use `@Observable` macro (iOS 26), NOT `ObservableObject`
- ProfileScreen (Epic 5) will observe PerceptualProfile for visualization
- TrainingSession (Story 4.3) will update PerceptualProfile after each comparison

### Data Model Design

**ComparisonRecord Structure** (from Story 1.2, architecture.md line 128):

```swift
@Model
class ComparisonRecord {
    var note1: Int           // MIDI note (0-127) - the reference note
    var note2: Int           // MIDI note (same as note1 in current design)
    var note2CentOffset: Double  // Cent difference applied to note2
    var isCorrect: Bool      // User's answer correctness
    var timestamp: Date
}
```

**Key Insights:**
- `note1` is the MIDI note to index by
- `note2CentOffset` is the cent difference (this is the threshold we're measuring)
- For weak spot identification: larger `note2CentOffset` where `isCorrect == true` = worse discrimination
- For improved discrimination: smaller `note2CentOffset` where `isCorrect == true` = better

**PerceptualProfile Data Structure:**

```swift
@Observable
class PerceptualProfile {
    // Per-note statistics indexed by MIDI note (0-127)
    private var noteStats: [PerceptualNote] = Array(repeating: PerceptualNote(), count: 128)

    struct PerceptualNote {
        var mean: Double = 0.0          // Mean detection threshold (cents)
        var stdDev: Double = 0.0        // Standard deviation
        var sampleCount: Int = 0        // Number of comparisons for this note

        var isTrained: Bool {
            sampleCount > 0
        }

        var isWeakSpot: Bool {
            // Untrained notes OR notes with high thresholds
            !isTrained || mean > someThreshold
        }
    }

    // Computed properties
    var overallMean: Double? { ... }     // Nil if cold start
    var overallStdDev: Double? { ... }
    func weakSpots(count: Int = 10) -> [Int] { ... }  // Returns MIDI notes
}
```

**Aggregation Logic:**

From ComparisonRecords to PerceptualNote statistics:
1. Group all ComparisonRecords by `note1` (MIDI note)
2. For each MIDI note:
   - Extract all `note2CentOffset` values where `isCorrect == true` (user CAN detect this difference)
   - Calculate arithmetic mean → detection threshold
   - Calculate standard deviation → consistency/confidence
   - Count samples → confidence weighting

**Incremental Update Logic:**

When a new comparison is answered:
1. Identify affected MIDI note (from comparison.note1)
2. Update mean using online algorithm:
   ```
   newMean = oldMean + (newValue - oldMean) / newCount
   ```
3. Update stdDev using Welford's online algorithm
4. Increment sampleCount

**Why Online/Incremental?**
- Avoid re-reading entire TrainingDataStore on every comparison (thousands of records eventually)
- O(1) update complexity vs. O(n) re-aggregation
- Matches NFR2: "next comparison begins immediately" — no blocking computation

### Learnings from Previous Stories

**From Story 3.4 (Training Interruption and App Lifecycle):**

**1. @Observable Pattern:**

Story 3.4 continued using `@Observable` for TrainingSession (from Swift 6.0+). PerceptualProfile MUST also use `@Observable` for Epic 5 ProfileScreen integration.

**2. Async/Concurrency Patterns:**

From TrainingSession (Story 3.2/3.3/3.4):
- Use `Task { }` for async operations
- Mark methods `@MainActor` when updating observable state
- TrainingSession already uses this pattern — PerceptualProfile should match

**Implication for Story 4.1:**
- PerceptualProfile update methods might be called from TrainingSession's training loop
- Ensure thread-safety for concurrent reads/writes
- Use `@MainActor` for state mutations if needed

**3. Protocol-Based Testing:**

Story 3.4 used MockNotePlayer with synchronous callbacks for deterministic testing:

```swift
class MockNotePlayer: NotePlayer {
    var onPlayCalled: (() -> Void)?
    var onStopCalled: (() -> Void)?
    ...
}
```

**Implication for Story 4.1:**
- Create MockTrainingDataStore for isolated PerceptualProfile testing
- No need to populate real SwiftData for tests — use in-memory mock
- Tests should be synchronous and deterministic

**4. Comprehensive Logging:**

Story 3.4 added detailed logging with os.Logger for debugging:
- TrainingScreen, TrainingSession, SineWaveNotePlayer all have loggers
- Log levels: .info for significant events, .debug for verbose

**Implication for Story 4.1:**
- Add logger to PerceptualProfile
- Log startup aggregation: number of records processed, time taken
- Log incremental updates: affected MIDI note, new statistics
- Log weak spot queries for algorithm transparency

**5. Test Coverage Pattern:**

Story 3.4 had 10 comprehensive unit tests covering all AC scenarios. PerceptualProfile should match this thoroughness:
- Test cold start (empty data)
- Test aggregation with sample data (multiple records per note)
- Test incremental update accuracy
- Test weak spot identification
- Test edge cases (single note, all notes, no weak spots)

**6. Swift 6 Concurrency Compliance:**

Story 3.4 fixed Swift 6 actor isolation issues by extracting values before crossing actor boundaries.

**Implication for Story 4.1:**
- If PerceptualProfile is @MainActor isolated, extract data before passing to background tasks
- Watch for compiler warnings about Sendable conformance
- Test with strict concurrency checking enabled

**7. File Organization Pattern:**

From recent commits, all Core/ components are in feature-grouped subdirectories:
- Core/Audio/ — NotePlayer, SineWaveNotePlayer
- Core/Data/ — ComparisonRecord, TrainingDataStore
- Core/Profile/ — PerceptualProfile ← NEW DIRECTORY FOR THIS STORY

**8. Iterative Refinement Expected:**

Story 3.4 required multiple commits (bug fixes, code review improvements, test reliability).

**Implication for Story 4.1:**
- First implementation: get structure and basic functionality working
- Code review iteration: refine algorithms, edge cases, performance
- Test iteration: add missing coverage, improve determinism
- Don't over-engineer upfront — iterate based on feedback

### Algorithm Deep Dive: Statistical Aggregation

**Statistical Concepts:**

**Detection Threshold**: The smallest cent difference a user can reliably detect for a given note.
- Measured from ComparisonRecord where `isCorrect == true`
- Larger `note2CentOffset` required = worse discrimination = higher threshold

**Arithmetic Mean**: Average detection threshold across all correct answers for a note.
```
mean = sum(centOffsets where isCorrect == true) / count(isCorrect == true)
```

**Standard Deviation**: Variability in detection — high stdDev = inconsistent, low stdDev = reliable.
```
stdDev = sqrt(sum((x - mean)^2) / count)
```

**Sample Count**: Number of comparisons answered for this note — confidence metric.

**Weak Spot Identification:**

Three categories of weak spots:
1. **Untrained notes** (sampleCount == 0): Highest priority — no data at all
2. **High threshold notes** (mean > threshold): Poor discrimination despite training
3. **High variance notes** (stdDev > threshold): Inconsistent — need more practice

**Cold Start Behavior** (FR12):

New user with zero training data:
- All 128 notes have sampleCount == 0
- All notes are weak spots
- Algorithm should select randomly across range at 100 cents

**Incremental Update Algorithms:**

**Welford's Online Algorithm for Mean and Variance:**

```swift
// Initialize
var count = 0
var mean = 0.0
var M2 = 0.0  // Sum of squared differences

// Add new value
func update(newValue: Double) {
    count += 1
    let delta = newValue - mean
    mean += delta / Double(count)
    let delta2 = newValue - mean
    M2 += delta * delta2
}

// Compute variance and standard deviation
var variance: Double {
    count < 2 ? 0.0 : M2 / Double(count - 1)
}
var stdDev: Double {
    sqrt(variance)
}
```

**Why Welford's Algorithm?**
- Numerically stable (avoids catastrophic cancellation)
- O(1) update complexity
- Single-pass — no need to store all values
- Standard approach in statistics libraries

**Implementation Strategy:**

Store `mean`, `M2`, and `count` in PerceptualNote struct. Update using Welford's algorithm when new comparisons arrive.

### Performance Considerations

**Startup Aggregation Performance:**

**Scenario**: 10,000 ComparisonRecords across 50 notes (realistic after weeks of training)

**Naive Approach** (re-calculate on every read):
- Fetch 10,000 records from SwiftData
- Group by note1
- Calculate statistics
- **Time**: ~100-500ms (acceptable for startup, UNACCEPTABLE for every comparison)

**Optimal Approach** (this story's design):
- **App startup**: Aggregate once, store in-memory
- **During training**: Incremental update (O(1) per comparison)
- **Time**: Startup ~100-500ms, per-comparison < 1ms

**From NFR4**: "App launch to training-ready < 2 seconds"
- Aggregation is part of app init
- 100-500ms for 10,000 records is acceptable
- If performance issues arise, optimize later (but likely won't need to)

**From NFR2**: "Next comparison begins immediately"
- Incremental update MUST be fast
- Welford's algorithm is O(1) — perfect
- No database query on update — just in-memory math

**Memory Footprint:**

128 notes × (mean: 8 bytes + stdDev: 8 bytes + M2: 8 bytes + count: 8 bytes) = ~4 KB
- Negligible — keep entire profile in memory
- No need for lazy loading or caching strategies

### Integration Points

**Dependency Injection** (already established in Stories 1.2, 3.2):

TrainingSession will receive PerceptualProfile via initializer:
```swift
init(notePlayer: NotePlayer,
     dataStore: TrainingDataStore,
     profile: PerceptualProfile) {  ← Added in Story 4.3
    ...
}
```

**App Initialization Flow** (Story 4.3 will connect this):

```swift
// In PeachApp.swift or ContentView
let dataStore = TrainingDataStore(modelContext: modelContext)
let profile = PerceptualProfile(from: dataStore)  ← THIS STORY
let notePlayer = SineWaveNotePlayer()
let trainingSession = TrainingSession(
    notePlayer: notePlayer,
    dataStore: dataStore,
    profile: profile  ← Story 4.3 adds this parameter
)
```

**Update Flow** (Story 4.3 will implement):

```swift
// In TrainingSession.handleAnswer()
func handleAnswer(_ answer: Answer) async {
    ...
    await dataStore.save(record)
    profile.update(with: currentComparison, isCorrect: isCorrect)  ← Story 4.3 adds this
    ...
}
```

**Read Flow** (Epic 5 will implement):

```swift
// In ProfileScreen (Epic 5, Story 5.1)
struct ProfileScreen: View {
    @State private var profile: PerceptualProfile

    var body: some View {
        // Read profile.noteStats for visualization
        // Display profile.overallMean, profile.overallStdDev
    }
}
```

### Testing Strategy

**Unit Test Structure:**

Create `PeachTests/Core/Profile/PerceptualProfileTests.swift`

**Test Cases (AC#6):**

**1. Cold Start Initialization:**
```swift
@Test func coldStartProfile() async {
    let mockStore = MockTrainingDataStore(records: [])
    let profile = PerceptualProfile(from: mockStore)

    #expect(profile.overallMean == nil)
    #expect(profile.overallStdDev == nil)
    #expect(profile.weakSpots().count == 128)  // All notes are weak
}
```

**2. Aggregation with Sample Data:**
```swift
@Test func aggregationFromRecords() async {
    let records = [
        ComparisonRecord(note1: 60, note2CentOffset: 50, isCorrect: true),
        ComparisonRecord(note1: 60, note2CentOffset: 45, isCorrect: true),
        ComparisonRecord(note1: 60, note2CentOffset: 55, isCorrect: true),
    ]
    let mockStore = MockTrainingDataStore(records: records)
    let profile = PerceptualProfile(from: mockStore)

    let noteStats = profile.statsForNote(60)
    #expect(noteStats.mean == 50.0)  // (50+45+55)/3
    #expect(noteStats.sampleCount == 3)
}
```

**3. Incremental Update:**
```swift
@Test func incrementalUpdate() async {
    let profile = PerceptualProfile(from: MockTrainingDataStore(records: []))

    profile.update(note: 60, centOffset: 50, isCorrect: true)
    profile.update(note: 60, centOffset: 45, isCorrect: true)

    let stats = profile.statsForNote(60)
    #expect(stats.mean == 47.5)
    #expect(stats.sampleCount == 2)
}
```

**4. Weak Spot Identification:**
```swift
@Test func weakSpotsIdentification() async {
    let profile = PerceptualProfile(from: MockTrainingDataStore(records: []))

    // Add data: note 60 weak (high threshold), note 62 strong (low threshold)
    profile.update(note: 60, centOffset: 80, isCorrect: true)
    profile.update(note: 62, centOffset: 10, isCorrect: true)

    let weakSpots = profile.weakSpots(count: 5)
    #expect(weakSpots.contains(60))  // High threshold = weak
    #expect(weakSpots.contains(55))  // Untrained = weak
}
```

**5. Summary Statistics:**
```swift
@Test func summaryStatistics() async {
    let records = [
        ComparisonRecord(note1: 60, note2CentOffset: 50, isCorrect: true),
        ComparisonRecord(note1: 62, note2CentOffset: 30, isCorrect: true),
        ComparisonRecord(note1: 64, note2CentOffset: 40, isCorrect: true),
    ]
    let profile = PerceptualProfile(from: MockTrainingDataStore(records: records))

    #expect(profile.overallMean == 40.0)  // (50+30+40)/3
}
```

**Mock TrainingDataStore:**

```swift
class MockTrainingDataStore: TrainingDataStore {
    private let records: [ComparisonRecord]

    init(records: [ComparisonRecord]) {
        self.records = records
    }

    func fetchAll() -> [ComparisonRecord] {
        records
    }
}
```

### What NOT To Do

- **Do NOT** persist PerceptualProfile to its own database — it's derived from ComparisonRecords
- **Do NOT** implement temporal snapshots yet — that's Epic 5 Story 5.1 enhancement
- **Do NOT** add UI visualization logic — ProfileScreen (Epic 5) will handle that
- **Do NOT** implement comparison selection logic — that's Story 4.2 (NextNoteStrategy)
- **Do NOT** modify TrainingSession yet — that's Story 4.3 integration
- **Do NOT** over-optimize prematurely — simple aggregation is fine for MVP
- **Do NOT** add complex statistical models (Bayesian, confidence intervals) — stick to mean/stdDev
- **Do NOT** implement settings integration yet (note range filtering) — defer to Story 4.3
- **Do NOT** add profile export/import — that's post-MVP
- **Do NOT** implement profile reset/clear functionality — not in current requirements

### FR Coverage Map for This Story

| FR | Description | Story 4.1 Action |
|---|---|---|
| FR9 | System selects next comparison based on perceptual profile | Build profile data structure — selection logic in Story 4.2 |
| FR12 | System initializes new users with 100 cents, all notes weak | Implement cold start: sampleCount == 0 → weak spot |
| FR13 | System maintains profile across sessions | Load from persistent ComparisonRecords on startup |
| FR26 | System computes profile from stored per-answer data | Implement aggregation from TrainingDataStore |

**Dependencies on Other FRs:**
- FR27 (Store comparison records) — Story 1.2 provides this
- FR28 (Local persistence) — Story 1.2 provides this
- FR10 (Difficulty adjustment on correctness) — Story 4.2 uses profile for this
- FR11 (Natural vs. Mechanical balance) — Story 4.2 uses profile for weak spot targeting

### Project Structure Notes

**New Directory Created:**

```
Peach/Core/Profile/
└── PerceptualProfile.swift
```

**Test Directory Created:**

```
PeachTests/Core/Profile/
└── PerceptualProfileTests.swift
```

**Alignment with Architecture:**

From architecture.md lines 194-226, Core/Profile/ is the designated location for perceptual profile logic. This story creates the directory and first component.

**No Conflicts**: Profile is a pure computation layer — no overlap with existing services.

### References

All technical details sourced from:

- [Source: docs/planning-artifacts/epics.md#Story 4.1] — User story, acceptance criteria (lines 425-456)
- [Source: docs/planning-artifacts/epics.md#Epic 4] — Epic objectives and FRs (lines 421-424, 172-174)
- [Source: docs/planning-artifacts/epics.md#FR9-FR15] — Functional requirements for adaptive algorithm (lines 122-129)
- [Source: docs/planning-artifacts/architecture.md#Service Boundaries - PerceptualProfile] — Component responsibility (lines 334)
- [Source: docs/planning-artifacts/architecture.md#Data Flow] — Startup aggregation and incremental updates (lines 157-163)
- [Source: docs/planning-artifacts/architecture.md#Implementation Sequence] — Why PerceptualProfile comes before NextNoteStrategy (lines 168-175)
- [Source: docs/planning-artifacts/architecture.md#Data Architecture] — ComparisonRecord model structure (lines 125-130)
- [Source: docs/planning-artifacts/prd.md#NFR4-NFR5] — Performance requirements (lines 67-68)
- [Source: docs/planning-artifacts/prd.md#FR26] — Profile computation requirement (line 282)
- [Source: docs/implementation-artifacts/3-4-training-interruption-and-app-lifecycle-handling.md] — Patterns for @Observable, testing, logging (Dev Agent Record section)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

- All tests pass (15/15): cold start, aggregation, incremental updates, weak spot identification, summary statistics
- Welford's online algorithm implemented for efficient O(1) incremental updates
- Swift 6 concurrency compliance: @MainActor isolation for thread-safety
- Untrained notes correctly prioritized over trained notes in weak spot identification

### Completion Notes List

✅ **Task 1**: Created PerceptualProfile.swift with PerceptualNote struct, @Observable conformance, and 128-slot MIDI array
✅ **Task 2**: Implemented init(from:) with Welford's algorithm for startup aggregation from TrainingDataStore
✅ **Task 3**: Implemented update(note:centOffset:isCorrect:) for O(1) incremental updates using online mean/variance
✅ **Task 4**: Implemented weakSpots(count:) prioritizing untrained notes (infinity score) over trained high-threshold notes
✅ **Task 5**: Implemented overallMean and overallStdDev computed properties for summary statistics
✅ **Task 6**: Created comprehensive test suite (15 tests) covering all acceptance criteria

**Key Implementation Decisions:**
- Used Welford's online algorithm for numerically stable mean and variance computation
- Untrained notes assigned Double.infinity score for highest weak spot priority (AC#5)
- @MainActor isolation ensures thread-safety for concurrent profile updates
- Reused existing MockTrainingDataStore from Training tests
- Only correct comparisons (isCorrect==true) count toward detection threshold statistics
- PerceptualNote stores m2 (sum of squared differences) for incremental variance calculation

### File List

- Peach/Core/Profile/PerceptualProfile.swift (new)
- PeachTests/Core/Profile/PerceptualProfileTests.swift (new)

## Change Log

### 2026-02-14 - Story 4.1 Implementation Complete
- Created Core/Profile directory structure for perceptual profile logic
- Implemented PerceptualProfile class with @Observable conformance for SwiftUI integration
- Implemented Welford's online algorithm for efficient incremental mean/variance calculation
- Implemented weak spot identification with untrained notes prioritized (infinity score)
- Created comprehensive test suite with 15 tests covering all 6 acceptance criteria
- All tests pass, no regressions in existing test suite

