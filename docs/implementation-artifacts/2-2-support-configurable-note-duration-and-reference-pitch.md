# Story 2.2: Support Configurable Note Duration and Reference Pitch

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **musician using Peach**,
I want notes to play at a configurable duration and tuning standard,
So that the training experience matches my preferences.

## Acceptance Criteria

1. **Given** a NotePlayer, **When** a note duration is specified, **Then** the note plays for exactly that duration (with envelope attack/release within the duration)

2. **Given** a default configuration, **When** no reference pitch is set, **Then** frequencies are derived from A4 = 440Hz

3. **Given** a configurable reference pitch, **When** a different reference pitch value is provided (e.g., A4 = 442Hz), **Then** all generated frequencies are derived from the new reference pitch

4. **Given** a MIDI note number and a cent offset, **When** a frequency is calculated, **Then** the frequency is mathematically derived from the reference pitch using standard equal temperament with the cent offset applied

5. **And** fractional cent precision (0.1 cent resolution) is supported

## Tasks / Subtasks

**IMPORTANT CONTEXT:** Story 2.1 already implemented the core infrastructure for this story:
- ✅ NotePlayer.play() accepts `duration` parameter
- ✅ FrequencyCalculation.frequency() accepts `referencePitch` parameter with default 440Hz
- ✅ SineWaveNotePlayer respects duration in buffer generation with proper envelope timing
- ✅ Fractional cent precision already supported

**This story focuses on:**
- Verification and test coverage of configuration scenarios
- Documentation and usage examples
- Any remaining integration gaps

- [ ] Task 1: Verify Existing Duration Support (AC: #1)
  - [ ] Review SineWaveNotePlayer buffer generation logic for duration handling
  - [ ] Verify envelope (attack/release) stays within specified duration
  - [ ] Test with various durations: 0.1s, 0.5s, 1.0s, 2.0s
  - [ ] Confirm no duration drift or timing issues

- [ ] Task 2: Add Comprehensive Duration Tests (AC: #1)
  - [ ] Test: Duration accuracy for short notes (100ms)
  - [ ] Test: Duration accuracy for default notes (1000ms)
  - [ ] Test: Duration accuracy for long notes (2000ms)
  - [ ] Test: Envelope timing doesn't exceed specified duration
  - [ ] Test: Invalid duration (negative, zero) handling

- [ ] Task 3: Verify Reference Pitch Functionality (AC: #2, #3, #4, #5)
  - [ ] Verify FrequencyCalculation default reference pitch is 440Hz
  - [ ] Verify custom reference pitch (442Hz, 432Hz) produces correct frequencies
  - [ ] Verify cent offset calculation uses reference pitch correctly
  - [ ] Verify fractional cent precision (test with 0.1 cent increments)

- [ ] Task 4: Add Reference Pitch Configuration Tests (AC: #2, #3, #4)
  - [ ] Test: Default reference pitch A4=440Hz
  - [ ] Test: Custom reference pitch A4=442Hz (baroque tuning)
  - [ ] Test: Custom reference pitch A4=432Hz (alternative tuning)
  - [ ] Test: Frequency calculation with reference pitch + cent offset
  - [ ] Test: Known frequency values at different reference pitches
  - [ ] Test: Fractional cent precision with custom reference pitch

- [ ] Task 5: Add Integration Examples and Documentation (AC: all)
  - [ ] Document duration parameter usage in NotePlayer
  - [ ] Document reference pitch parameter usage in FrequencyCalculation
  - [ ] Add code examples: playing notes at different durations
  - [ ] Add code examples: using different reference pitches
  - [ ] Add use case examples: baroque tuning (442Hz), alternative tuning (432Hz)

- [ ] Task 6: Settings Integration Preparation (Future Epic 6)
  - [ ] Document how settings will propagate to NotePlayer (duration from @AppStorage)
  - [ ] Document how reference pitch will propagate to FrequencyCalculation
  - [ ] Note: Actual settings screen is Epic 6, this story just ensures the parameters exist
  - [ ] Verify parameter signatures support future settings integration

## Dev Notes

### 🎯 CRITICAL CONTEXT: Most Functionality Already Implemented!

**Story 2.1 completed 90% of this story's technical requirements.** This is intentional - Story 2.1 needed these features to properly implement the audio engine, so they were built together.

**What's Already Done:**
- ✅ `NotePlayer.play(frequency:duration:amplitude:)` - duration parameter exists and works
- ✅ `FrequencyCalculation.frequency(midiNote:cents:referencePitch:)` - reference pitch parameter exists with 440Hz default
- ✅ `SineWaveNotePlayer` buffer generation respects duration, calculates proper attack/sustain/release timing
- ✅ Fractional cent precision (0.1 cent resolution) fully supported in frequency calculation
- ✅ Comprehensive tests exist in SineWaveNotePlayerTests.swift (24 tests passing)

**What Story 2.2 Adds:**
1. **Focused test coverage** for configuration scenarios (duration variations, reference pitch variations)
2. **Verification** that existing implementation meets all Story 2.2 acceptance criteria
3. **Documentation** and usage examples for configurable parameters
4. **Integration notes** for future Epic 6 Settings implementation

**This is NOT wasted work** - Story 2.2 ensures comprehensive test coverage of configuration behavior and documents how settings will integrate in Epic 6.

### Story Context

**Epic Context:** Epic 2 "Hear and Compare - Core Audio Engine" establishes the audio foundation. Story 2.1 built the NotePlayer protocol and SineWaveNotePlayer implementation. Story 2.2 focuses on ensuring configurable note duration and reference pitch work correctly for future customization.

**Why This Matters:**
- **Configurable duration:** Musicians may prefer shorter notes for rapid training or longer notes for careful listening. FR19 requires this flexibility.
- **Configurable reference pitch:** Different tuning standards exist (baroque: 442Hz, alternative: 432Hz, historical: 415Hz). FR20 requires supporting these. Users who play in orchestras or historical ensembles need the app to match their tuning context.

**User Impact:**
- Without configurable duration: users stuck with one note length, less flexible training
- Without configurable reference pitch: users training with non-standard tuning would hear mismatched frequencies, breaking the training value

**Cross-Story Dependencies:**
- **Story 2.1 (done):** Provides NotePlayer, SineWaveNotePlayer, FrequencyCalculation - all parameters already exist
- **Epic 6 Story 6.1 (future):** Will add Settings Screen UI to expose duration and reference pitch to users
- **Epic 6 Story 6.2 (future):** Will integrate settings with TrainingSession to apply user preferences

### Technical Stack — Exact Versions & Frameworks

**No changes from Story 2.1:**
- **Xcode:** 26.2
- **Swift:** 6.0
- **iOS Deployment Target:** iOS 26
- **Audio Framework:** AVFoundation (AVAudioEngine + AVAudioPlayerNode)
- **Testing Framework:** Swift Testing (@Test, #expect())
- **Dependencies:** Zero third-party (SPM clean)

### Existing Implementation Analysis

**NotePlayer Protocol (NotePlayer.swift):**
```swift
func play(frequency: Double, duration: TimeInterval, amplitude: Double) async throws
```
- ✅ `duration` parameter already present
- Duration is in seconds (TimeInterval = Double)
- Passed directly to SineWaveNotePlayer buffer generation

**FrequencyCalculation (FrequencyCalculation.swift):**
```swift
public static func frequency(midiNote: Int, cents: Double = 0.0, referencePitch: Double = 440.0) -> Double
```
- ✅ `referencePitch` parameter already present with 440Hz default
- Formula: `f = referencePitch * 2^((midiNote-69)/12) * 2^(cents/1200)`
- Default matches AC#2: A4 = 440Hz when not specified
- Supports custom reference pitch per AC#3

**SineWaveNotePlayer Buffer Generation (SineWaveNotePlayer.swift lines 113-164):**
```swift
private func generateBuffer(frequency: Double, duration: TimeInterval, amplitude: Double) throws -> AVAudioPCMBuffer
```
- Calculates total samples: `Int(duration * sampleRate)` (line 117)
- Envelope timing within duration:
  - Attack: 5ms (221 samples at 44.1kHz)
  - Release: 5ms (221 samples)
  - Sustain: remaining samples (duration - 10ms)
- ✅ Envelope stays within specified duration per AC#1
- No duration drift: exact sample count ensures precise timing

**Frequency Precision:**
- Uses `Double` for all calculations (15-17 decimal digits precision)
- 0.1 cent = 2^(0.1/1200) ≈ 1.000048 frequency ratio
- Double precision provides accuracy far exceeding 0.1 cent requirement
- ✅ Fractional cent precision supported per AC#5

### What's Missing: Test Coverage Gaps

**Existing Tests (SineWaveNotePlayerTests.swift):**
- ✅ Frequency calculation accuracy (5 tests)
- ✅ Basic playback (10 tests)
- ✅ Error handling (1 test)
- ⚠️ Duration variation scenarios: NOT specifically tested
- ⚠️ Reference pitch variation scenarios: NOT specifically tested
- ⚠️ Envelope timing within duration: NOT explicitly verified

**Gaps to Fill in This Story:**

1. **Duration Test Scenarios:**
   - Short notes (100ms) - verify envelope fits within duration
   - Default notes (1000ms) - verify standard case
   - Long notes (2000ms) - verify no timing issues
   - Edge case: duration < envelope overhead (10ms) - should still work
   - Invalid: zero/negative duration - should throw error

2. **Reference Pitch Test Scenarios:**
   - Default (no parameter) → 440Hz base
   - Baroque tuning (442Hz) → verify frequency shift
   - Alternative tuning (432Hz) → verify frequency shift
   - Historical tuning (415Hz) → verify frequency shift
   - Known frequency values: MIDI 60 at different reference pitches
   - Cent offset + custom reference pitch → verify combined calculation

3. **Integration Scenarios:**
   - Play sequential notes at different durations
   - Calculate frequencies for same MIDI note at different reference pitches
   - Verify duration parameter propagation from TrainingSession (future)

### Architecture Compliance Requirements

**From Architecture Document [docs/planning-artifacts/architecture.md]:**

**Service Boundaries (lines 149-156, 330-336):**
- **NotePlayer:** "Plays a single note at a given frequency with envelope. No sequencing, no concept of comparisons."
- Boundary: receives frequency in Hz and duration in seconds, plays sound
- ✅ Duration as parameter maintains this boundary - NotePlayer doesn't "know" about settings, just receives a value

**Settings Propagation (Cross-Cutting Concern, line 367):**
> "TrainingSession reads @AppStorage when requesting next comparison; passes duration to NotePlayer"

- This story ensures NotePlayer **can accept** duration - Epic 6 will provide the settings UI
- This story ensures FrequencyCalculation **can accept** reference pitch - Epic 6 will provide the settings UI
- No changes needed to NotePlayer/FrequencyCalculation architecture - parameters already exist

**Naming Conventions (lines 186-193):**
- ✅ All existing code follows Swift naming conventions
- Properties: `duration`, `referencePitch` (camelCase)
- Functions: `frequency(midiNote:cents:referencePitch:)` (camelCase with parameter labels)
- No new types to name in this story (all infrastructure exists)

**Error Handling (lines 248-260):**
- ✅ AudioError enum already exists with appropriate cases
- Duration validation: should throw `AudioError.invalidFrequency` for invalid duration (reuse existing error type)
- Reference pitch validation: currently none, but should validate reasonable range (e.g., 400-480 Hz)

### Previous Story Intelligence (from Story 2.1)

**Story 2.1 Outcomes:**
- ✅ All infrastructure for this story already built
- ✅ NotePlayer protocol with duration parameter (NotePlayer.swift line 40)
- ✅ FrequencyCalculation with reference pitch parameter (FrequencyCalculation.swift line 22)
- ✅ SineWaveNotePlayer respects duration with proper envelope timing
- ✅ Comprehensive test suite (24 tests passing)
- ✅ Zero warnings build
- ✅ Full code review completed with all fixes applied

**Key Learnings from Story 2.1:**

1. **Test-First Development Works:**
   - Story 2.1 wrote tests first, then implementation
   - Continue this pattern: write configuration tests, verify they pass

2. **Buffer-Based Playback Pattern:**
   - Story 2.1 switched from AVAudioSourceNode to AVAudioPlayerNode
   - Buffer pre-generation ensures precise duration (no realtime drift)
   - Duration = exact sample count / sample rate (mathematically precise)

3. **Envelope Timing:**
   - 5ms attack + 5ms release = 10ms total envelope overhead
   - Sustain = duration - 10ms (or 0 if duration < 10ms)
   - This pattern already handles short durations gracefully

4. **Frequency Calculation Best Practices:**
   - Use `Double` for all calculations (not Float)
   - Equal temperament formula: `referencePitch * 2^((n-69)/12) * 2^(cents/1200)`
   - Precondition checks for MIDI range (0-127)

5. **Code Review Emphasis:**
   - Public access control required for all types
   - Comprehensive documentation required
   - Edge case test coverage required
   - Magic numbers need explanatory comments

**Files Modified in Story 2.1:**
- Peach/Core/Audio/NotePlayer.swift
- Peach/Core/Audio/FrequencyCalculation.swift
- Peach/Core/Audio/SineWaveNotePlayer.swift
- PeachTests/Core/Audio/SineWaveNotePlayerTests.swift

**Files to Modify in Story 2.2:**
- PeachTests/Core/Audio/SineWaveNotePlayerTests.swift (add configuration tests)
- Possibly Peach/Core/Audio/SineWaveNotePlayer.swift (add duration validation if missing)
- Possibly Peach/Core/Audio/FrequencyCalculation.swift (add reference pitch validation if needed)

### Git Intelligence from Recent Commits

**Recent Commits (from git log):**
```
3ef6451 Code review fixes for Story 2.1: Address design gaps and add missing validation
0dc8799 Implement Story 2.1: NotePlayer Protocol and SineWaveNotePlayer
d07c6af Create Story 2.1: Implement NotePlayer Protocol and SineWaveNotePlayer
```

**Patterns Observed:**
1. **Story lifecycle:** create story → implement → code review → fixes → mark done
2. **Commit message format:** `[Action] Story X.Y: [Description]`
3. **Code review is mandatory:** Story 2.1 had a full code review with 10 fixes applied
4. **Validation emphasis:** "missing validation" in review - expect same scrutiny for duration/reference pitch validation

**What This Means for Story 2.2:**
- Expect code review after implementation
- Add validation for edge cases (invalid duration, unreasonable reference pitch)
- Write comprehensive tests before review to avoid "missing test coverage" feedback
- Document all design decisions

### Latest Technical Information

**No new web research needed** - Story 2.1 already researched:
- AVAudioEngine best practices
- Envelope shaping techniques
- Frequency calculation formulas
- Swift Testing framework usage

**Relevant findings from Story 2.1 research:**

**Duration Accuracy:**
- Buffer-based playback (AVAudioPlayerNode) provides sample-accurate duration
- Duration in seconds → sample count: `samples = duration * sampleRate`
- At 44.1kHz: 1 second = 44,100 samples (exact)
- No drift, no approximation - mathematically precise

**Reference Pitch Standards:**
- **A440 (Modern Standard):** 440Hz - ISO 16, adopted 1955, universal modern standard
- **A442 (Baroque/Orchestral):** 442Hz - some European orchestras, brighter sound
- **A432 (Alternative):** 432Hz - alternative tuning movement, "natural frequency"
- **A415 (Baroque Historical):** 415Hz - historically informed performance, one semitone below A440

**Frequency Calculation Validation:**
- Known values at A440:
  - C4 (MIDI 60): 261.626 Hz
  - A4 (MIDI 69): 440.000 Hz
  - C5 (MIDI 72): 523.251 Hz
- At A442 (1.0045 ratio):
  - C4: 262.806 Hz
  - A4: 442.000 Hz
  - C5: 525.613 Hz
- Tests should verify these known values

### Implementation Sequence for This Story

**Order of Implementation:**

1. **Add Duration Validation to SineWaveNotePlayer (if missing)**
   - Check if duration <= 0 → throw AudioError.invalidFrequency("Duration must be positive")
   - Minimum duration recommendation: > envelope overhead (10ms)
   - Document duration constraints in play() method documentation

2. **Add Reference Pitch Validation to FrequencyCalculation (if missing)**
   - Reasonable range check: 400-480 Hz (covers all common standards)
   - Throw error for extreme values (< 100 Hz, > 1000 Hz)
   - Document reference pitch parameter in function documentation

3. **Write Duration Configuration Tests**
   - Test: short duration (100ms)
   - Test: default duration (1000ms)
   - Test: long duration (2000ms)
   - Test: very short duration (5ms) - edge case
   - Test: negative duration → error
   - Test: zero duration → error
   - Run tests, verify all pass

4. **Write Reference Pitch Configuration Tests**
   - Test: default reference pitch (no parameter) → frequencies based on 440Hz
   - Test: baroque tuning (442Hz) → verify A4 frequency
   - Test: alternative tuning (432Hz) → verify A4 frequency
   - Test: historical tuning (415Hz) → verify A4 frequency
   - Test: known frequency values at different reference pitches
   - Test: cent offset + custom reference pitch (combined calculation)
   - Test: invalid reference pitch (< 100 Hz) → error
   - Test: invalid reference pitch (> 1000 Hz) → error
   - Run tests, verify all pass

5. **Add Usage Examples in Documentation**
   - Update NotePlayer.swift documentation with duration examples
   - Update FrequencyCalculation.swift documentation with reference pitch examples
   - Add code comments showing common use cases

6. **Integration Verification**
   - Run full test suite (all existing + new tests)
   - Verify zero warnings build
   - Manual verification: play notes at different durations (if UI available)
   - Manual verification: calculate frequencies at different reference pitches

7. **Document Settings Integration Path**
   - Add comments/documentation explaining how Epic 6 will integrate
   - Note where @AppStorage values will be read
   - Note where settings will propagate to NotePlayer/FrequencyCalculation

### What NOT To Do

- Do NOT modify NotePlayer protocol signature (already correct)
- Do NOT modify FrequencyCalculation function signature (already correct)
- Do NOT add UI for settings (that's Epic 6)
- Do NOT create @AppStorage properties yet (that's Epic 6)
- Do NOT modify SineWaveNotePlayer buffer generation logic (already correct)
- Do NOT add complex duration validation logic (simple positive check is sufficient)
- Do NOT add new audio features beyond configuration verification
- Do NOT use XCTest (use Swift Testing)

### Performance Requirements (NFRs)

**From PRD [docs/planning-artifacts/prd.md]:**

All NFRs from Story 2.1 still apply:
- ✅ Audio latency < 10ms: buffer-based playback achieves this
- ✅ Frequency precision 0.1 cent: Double precision achieves this
- ✅ Smooth envelopes: 5ms attack/release prevents clicks

**New consideration for this story:**
- **Duration accuracy:** Should be sample-accurate (no perceptible drift)
  - At 44.1kHz, 1-sample error = 0.023ms (imperceptible)
  - Buffer-based playback provides this precision automatically

### FR Coverage Map for This Story

| FR | Description | Current Status | Story 2.2 Action |
|---|---|---|---|
| FR19 | Configurable note duration | ✅ Implemented (duration parameter) | Verify with tests |
| FR20 | Configurable reference pitch | ✅ Implemented (referencePitch parameter) | Verify with tests |
| FR16 | Generate precise sine waves | ✅ Implemented in 2.1 | No changes |
| FR17 | Smooth envelopes | ✅ Implemented in 2.1 | No changes |
| FR18 | Same timbre | ✅ Implemented in 2.1 | No changes |

### Cross-Cutting Concerns

**Settings Propagation (from Architecture line 367):**
- Epic 6 will create @AppStorage properties for:
  - `noteDuration: Double` (default: 1.0 second)
  - `referencePitch: Double` (default: 440.0 Hz)
- TrainingSession will read these values and pass to:
  - NotePlayer.play(duration: noteDuration, ...)
  - FrequencyCalculation.frequency(referencePitch: referencePitch, ...)
- This story ensures these parameters exist and work correctly

**No other cross-cutting concerns affect this story** - duration and reference pitch are pure configuration values with no lifecycle or interruption handling needs.

### Testing Strategy

**Unit Tests (Automated):**
- Duration configuration scenarios (6 tests)
- Reference pitch configuration scenarios (8 tests)
- Validation edge cases (4 tests)
- Total new tests: ~18

**Test Coverage Targets:**
- All duration ranges: short, default, long, edge cases
- All common reference pitches: 440, 442, 432, 415 Hz
- All validation paths: invalid duration, invalid reference pitch
- Known frequency values verification

**Manual Verification:**
- Not needed for this story (all behavior testable via unit tests)
- Duration accuracy is sample-based (mathematically verifiable)
- Frequency calculation is formula-based (mathematically verifiable)

### Project Structure Notes

**Files Being Modified:**
- `PeachTests/Core/Audio/SineWaveNotePlayerTests.swift` (add ~18 new tests)
- Possibly `Peach/Core/Audio/SineWaveNotePlayer.swift` (add duration validation)
- Possibly `Peach/Core/Audio/FrequencyCalculation.swift` (add reference pitch validation)

**No new files created** - all infrastructure exists from Story 2.1

**Build Configuration:**
- No changes - same as Story 2.1
- Zero warnings standard continues

### References

All technical details sourced from:

- [Source: docs/planning-artifacts/epics.md#Story 2.2] — User story, acceptance criteria (lines 273-297)
- [Source: docs/planning-artifacts/epics.md#Epic 2] — Epic objectives and FRs (lines 237-240)
- [Source: docs/planning-artifacts/architecture.md#Audio Engine] — NotePlayer design (lines 149-152)
- [Source: docs/planning-artifacts/architecture.md#Settings Propagation] — Cross-cutting concern (line 367)
- [Source: docs/planning-artifacts/prd.md#Audio Engine] — FR19-FR20 (lines 274-275)
- [Source: docs/implementation-artifacts/2-1-implement-noteplayer-protocol-and-sinewavenoteplayer.md] — Previous story implementation, learnings, patterns
- [Source: Peach/Core/Audio/NotePlayer.swift] — Existing protocol with duration parameter
- [Source: Peach/Core/Audio/FrequencyCalculation.swift] — Existing frequency calculation with reference pitch
- [Source: Peach/Core/Audio/SineWaveNotePlayer.swift] — Existing implementation respecting duration

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

