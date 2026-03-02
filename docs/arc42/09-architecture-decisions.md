# 9. Architecture Decisions

Key architecture decisions are documented in the [Architecture Decision Document](../planning-artifacts/architecture.md). This section summarizes the most significant decisions and their rationale.

## ADR-1: SwiftData over Core Data

**Context:** The app needs atomic, crash-resilient persistence for per-answer training records.

**Decision:** Use SwiftData (iOS 17+, backed by SQLite via Core Data).

**Rationale:** Native SwiftUI integration with `@Model` macro. Minimal boilerplate for flat record models (`ComparisonRecord`, `PitchMatchingRecord`). Atomic writes and crash resilience handled by the underlying SQLite engine. No need for Core Data's full complexity.

**Consequences:** Tied to Apple's SwiftData evolution. Migration tooling is less mature than Core Data. Acceptable for a greenfield project with simple models.

## ADR-2: AVAudioUnitSampler with SoundFont over Custom Synthesis

**Context:** The MVP used sine wave generation via `AVAudioSourceNode`. Users need more musical timbres.

**Decision:** Replace custom synthesis with `AVAudioUnitSampler` loading SoundFont (.sf2) instrument files.

**Rationale:** SoundFonts provide hundreds of realistic instrument timbres with zero DSP code. `AVAudioUnitSampler` handles MIDI note-on/off, pitch bend, and velocity natively. The bundled GeneralUser GS.sf2 provides comprehensive preset coverage. Real-time pitch adjustment works via standard MIDI pitch bend (14-bit resolution, ±2 semitone range).

**Consequences:** App size increases by ~30 MB for the SoundFont. Sine wave option removed (the SoundFont includes a sine-like "Sine Wave" preset). Pitch bend limited to ±200 cents — sufficient for all current use cases.

## ADR-3: Kazez Psychoacoustic Staircase Algorithm

**Context:** The adaptive algorithm must continuously adjust difficulty based on user performance without session boundaries.

**Decision:** Implement a modified Kazez staircase method with asymmetric step sizes.

**Rationale:** Correct answers narrow difficulty by `p * (1.0 - 0.05 * sqrt(p))`, wrong answers widen by `p * (1.0 + 0.09 * sqrt(p))`. The asymmetry prevents the algorithm from getting stuck at boundaries. Square-root scaling makes steps proportional to the current difficulty level. No session-level state — the algorithm reads the perceptual profile and last comparison only.

**Consequences:** Algorithm parameters are tunable but not configurable by the user. Convergence behavior validated through implementation testing.

## ADR-4: In-Memory Profile Rebuilt from Records

**Context:** The perceptual profile must be accurate, consistent, and resilient to data corruption.

**Decision:** Never persist the `PerceptualProfile` to SwiftData. Rebuild it from all `ComparisonRecord` and `PitchMatchingRecord` entries on every app launch. Update incrementally during training.

**Rationale:** Raw records are the single source of truth. Rebuilding eliminates consistency bugs between cached profile and stored records. Welford's algorithm makes incremental updates O(1). Full rebuild from thousands of records completes in milliseconds on modern hardware.

**Consequences:** App startup includes a full aggregation pass. Acceptable for the expected data volume (thousands of records, not millions).

## ADR-5: PlaybackHandle Protocol for Note Lifecycle

**Context:** Pitch matching requires indefinite note playback with real-time frequency adjustment. The MVP `NotePlayer.stop()` method was ambient (stop whatever is playing).

**Decision:** Redesign `NotePlayer` to return a `PlaybackHandle` from `play()`. The handle owns the playing note and provides `stop()` and `adjustFrequency()`.

**Rationale:** Makes note ownership explicit. The caller that starts a note controls that specific note's lifecycle. Supports both fixed-duration (comparison: play → wait → auto-stop) and indefinite (pitch matching: play → drag → commit → stop) patterns through the same protocol.

**Consequences:** All playback code uses handle-based lifecycle. Fixed-duration convenience method preserved via protocol extension. `stopAll()` retained for emergency cleanup only.

## ADR-6: No Third-Party Dependencies

**Context:** The project is a learning exercise in native iOS development.

**Decision:** Use zero third-party packages. Entire stack is first-party Apple frameworks.

**Rationale:** Eliminates dependency risk, version conflicts, and build complexity. Forces understanding of Apple's APIs. The project scope doesn't require anything beyond what Apple provides (SwiftUI, SwiftData, AVAudioEngine, Swift Charts, Swift Testing).

**Consequences:** Some "solved problems" (e.g., SoundFont preset parsing) require custom implementation. Acceptable as a learning opportunity.

## ADR-7: Feature-Based Project Organization

**Context:** Need a project structure that scales with features and is navigable by both humans and AI agents.

**Decision:** Organize by feature at the top level (`Comparison/`, `PitchMatching/`, `Profile/`, etc.) with shared code in `Core/` subdivided by concern (`Audio/`, `Algorithm/`, `Data/`, `Profile/`, `Training/`).

**Rationale:** Feature directories map directly to screens — easy to find code for any given functionality. `Core/` prevents duplication of shared logic. Test target mirrors source structure.

**Consequences:** Some types could arguably belong to either a feature or Core. The rule: if two or more features use it, it goes in Core.
