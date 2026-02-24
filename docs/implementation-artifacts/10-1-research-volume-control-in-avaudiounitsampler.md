# Story 10.1: Research Volume Control in AVAudioUnitSampler

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want to understand how to control sound volume (dB) independently of MIDI velocity in AVAudioUnitSampler / AVAudioEngine,
So that I can make informed implementation decisions for the amplitude parameter in subsequent stories.

## Acceptance Criteria

1. **Given** the current SoundFontNotePlayer uses AVAudioUnitSampler with MIDI velocity to control note intensity, **When** the developer researches AVAudioEngine's audio graph capabilities, **Then** a short findings document is produced that answers:
   - Can sound volume be controlled independently of MIDI velocity? If so, through what mechanism (e.g., node volume, mixer gain, AVAudioUnitSampler properties)?
   - What unit does the mechanism use (linear 0.0–1.0, dB, other)?
   - How to convert between dB offsets and the native unit?
   - Are there any gotchas (e.g., clipping, latency, per-note vs. global volume)?

2. The findings document is saved to `docs/implementation-artifacts/` for reference during implementation of stories 10.3–10.5.

## Tasks / Subtasks

- [x] Task 1: Audit current audio graph (AC: #1)
  - [x] Read `Peach/Core/Audio/SoundFontNotePlayer.swift` to understand the AVAudioEngine → AVAudioUnitSampler topology
  - [x] Identify all nodes in the audio graph and their connections
  - [x] Document how amplitude currently flows: `amplitude: Double` → `midiVelocity(forAmplitude:)` → `sampler.startNote(withVelocity:)`
- [x] Task 2: Research independent volume control mechanisms (AC: #1)
  - [x] Investigate `AVAudioNode.volume` property (inherited by AVAudioUnitSampler) — does setting it before/after `startNote` affect output level independently of velocity?
  - [x] Investigate `AVAudioMixerNode` — can a mixer node be inserted between sampler and output for gain control?
  - [x] Investigate `AVAudioUnitEQ` or other AU effects for gain staging
  - [x] Investigate `AVAudioEngine.mainMixerNode.outputVolume` — global vs. per-node control
  - [x] Check Apple developer docs and WWDC sessions for recommended volume control patterns
- [x] Task 3: Determine unit system and conversion (AC: #1)
  - [x] Document what unit the chosen mechanism uses (linear 0.0–1.0, dB, or other)
  - [x] Provide conversion formula: dB offset → native unit (likely `pow(10, dB / 20)` for linear)
  - [x] Confirm whether ±2 dB range (the max offset from Story 10.5) is achievable without clipping
- [x] Task 4: Identify gotchas and constraints (AC: #1)
  - [x] Per-note vs. global volume: Can volume be changed between two notes in rapid succession (within ~1s)?
  - [x] Latency: Does changing volume introduce any audible artifacts or delay?
  - [x] Clipping: What happens if volume boost pushes signal beyond 0 dBFS?
  - [x] Thread safety: Can volume be set from main actor while audio runs on render thread?
  - [x] Interaction with MIDI velocity: Does volume multiply with velocity or override it?
- [x] Task 5: Write findings document (AC: #2)
  - [x] Save structured findings to `docs/implementation-artifacts/10-1-volume-control-findings.md`
  - [x] Include recommended approach for Story 10.3 (Add Amplitude Parameter to NotePlayer)
  - [x] Include code sketch showing where in SoundFontNotePlayer the volume control would be applied

## Dev Notes

### Current Audio Architecture

**SoundFontNotePlayer** (`Peach/Core/Audio/SoundFontNotePlayer.swift`):
- Owns `AVAudioEngine` + `AVAudioUnitSampler`
- Audio graph: `sampler` → `engine.mainMixerNode` → `engine.outputNode` (implicit default wiring)
- `play()` converts amplitude (0.0–1.0) to MIDI velocity (1–127) via `midiVelocity(forAmplitude:)`
- Pitch bend used for fine frequency control (±100 cents)
- Preset loading happens per-play via `loadPreset(program:bank:)` if sound source changed

**NotePlayer Protocol** (`Peach/Core/Audio/NotePlayer.swift`):
- `play(frequency: Double, duration: TimeInterval, amplitude: Double) async throws`
- `stop() async throws`
- `AudioError.invalidAmplitude` for out-of-range values

**TrainingSession** (`Peach/Training/TrainingSession.swift`):
- Uses fixed `amplitude = 0.5` for all notes
- Both note1 and note2 currently play at same amplitude

### Key Technical Pointers for Research

**AVAudioNode.volume** (most likely candidate):
- `AVAudioUnitSampler` inherits from `AVAudioUnit` → `AVAudioNode`
- `AVAudioNode` has a `volume` property: `var volume: Float` (linear, 0.0–1.0 per Apple docs, but may accept >1.0)
- Wait — actually, `volume` is on `AVAudioMixerNode`, not `AVAudioNode` directly. Verify this.
- `AVAudioUnitSampler` does NOT directly expose a volume property at the node level
- The `engine.mainMixerNode` does have `.outputVolume` (Float, 0.0–1.0)

**Potential approaches to investigate:**
1. `sampler.volume` — if available on the sampler's audio unit
2. `engine.mainMixerNode.outputVolume` — global output volume
3. Insert a dedicated `AVAudioMixerNode` between sampler and main mixer for per-channel gain
4. Use `AVAudioUnitEQ` as a gain stage
5. `AudioUnitSetParameter` on the underlying Audio Unit with `kAudioUnitParameterUnit_LinearGain`

**dB ↔ Linear conversion:**
- Linear to dB: `dB = 20 * log10(linear)`
- dB to linear: `linear = pow(10, dB / 20)`
- ±2 dB range: linear range 0.794 – 1.259
- At default volume (assume 1.0 baseline): +2 dB = 1.259 (may clip if already near max)

### Relevant Epic Context

Epic 10 introduces "Vary Loudness" as a training complication. The full story arc:
- **10.1** (this): Research volume control — find the right mechanism
- **10.2**: Rename `amplitude` to `velocity` in NotePlayer protocol (pure rename/retype)
- **10.3**: Add new `amplitude` parameter to NotePlayer for true volume control
- **10.4**: "Vary Loudness" slider in Settings
- **10.5**: TrainingSession applies random loudness offset to note2

The research here directly informs 10.3's implementation. The mechanism chosen must:
- Control volume independently of MIDI velocity (velocity affects timbre/dynamics in SF2 samples)
- Allow per-note volume changes between note1 and note2 (~1s apart)
- Support ±2 dB offset range without audible artifacts
- Work with AVAudioUnitSampler's SF2 playback pipeline

### Project Structure Notes

- Findings document goes to: `docs/implementation-artifacts/10-1-volume-control-findings.md`
- No code changes in this story — research output only
- All existing patterns and conventions from `docs/project-context.md` apply to subsequent implementation stories

### References

- [Source: docs/planning-artifacts/epics.md#Epic 10] — Epic 10 overview and all story definitions
- [Source: docs/planning-artifacts/architecture.md#Audio Engine] — AVAudioEngine architecture decisions
- [Source: docs/project-context.md#AVAudioEngine] — SoundFontNotePlayer rules and audio constraints
- [Source: Peach/Core/Audio/NotePlayer.swift] — Protocol definition with amplitude parameter
- [Source: Peach/Core/Audio/SoundFontNotePlayer.swift] — Current amplitude → velocity implementation
- [Source: Peach/Training/TrainingSession.swift] — Fixed amplitude = 0.5 usage

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None — research-only story, no code changes or debugging required.

### Research Methodology

Findings are based on Apple developer documentation review and AVFoundation header inspection. Reference URLs listed in the findings document were consulted. Empirical validation (calling `sampler.masterGain` on a real device) will occur during Story 10.3 implementation.

### Completion Notes List

- Audited current audio graph: `AVAudioUnitSampler` → `engine.mainMixerNode` → `engine.outputNode`
- Key finding: `AVAudioUnitSampler` does NOT have a `.volume` property (it doesn't conform to `AVAudioMixing`)
- Recommended mechanism: `AVAudioUnitSampler.masterGain` (Float, dB, range -90.0 to +12.0, default 0.0)
- `masterGain` is dB-native — no conversion needed for ±2 dB offset range
- `masterGain` is independent of MIDI velocity — velocity controls timbre/dynamics, `masterGain` controls output gain
- `masterGain` is an Audio Unit parameter — thread-safe, immediate, no artifacts between notes
- No audio graph changes required for Stories 10.3–10.5
- Alternatives investigated and rejected: `mainMixerNode.outputVolume` (global, linear), intermediate mixer (over-engineered), `AVAudioUnitEQ.globalGain` (over-engineered), MIDI CC7 (unreliable)
- Findings document saved to `docs/implementation-artifacts/10-1-volume-control-findings.md`

### Change Log

- 2026-02-24: Completed research — produced findings document with recommended `masterGain` approach
- 2026-02-24: Code review — fixed File List accuracy (new vs modified), added sprint-status.yaml to File List, added research methodology section, simplified findings code sketch to post-rename only

## Senior Developer Review (AI)

**Reviewer:** Michael (via adversarial code review workflow)
**Date:** 2026-02-24
**Outcome:** Approved with fixes applied

### Findings Summary

- **1 HIGH** (dirty working tree — `Localizable.xcstrings` has unrelated changes from story 9-2; must be committed separately before this story)
- **4 MEDIUM** (File List inaccuracies, undocumented sprint-status change, misleading code sketch, missing methodology) — all fixed
- **3 LOW** (stale dev notes, no empirical validation, third-party WWDC link) — noted, not fixed

### Action Required Before Commit

- [ ] Commit or stash the unrelated `Peach/Resources/Localizable.xcstrings` changes (leftover from story 9-2) before committing this story's artifacts

### File List

- `docs/implementation-artifacts/10-1-volume-control-findings.md` (new) — structured research findings
- `docs/implementation-artifacts/10-1-research-volume-control-in-avaudiounitsampler.md` (new) — story file with dev agent record
- `docs/implementation-artifacts/sprint-status.yaml` (modified) — added Epic 10 tracking block
