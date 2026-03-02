# 1. Introduction and Goals

## Requirements Overview

Peach is a pitch ear training app for iOS that trains musicians' pitch perception through two complementary modes:

- **Pitch Comparison** — two notes play in sequence; the user judges whether the second is higher or lower
- **Pitch Matching** — a reference note plays, then the user tunes a second note to match a target pitch via a vertical slider

Both modes have **interval variants** that generalize from unison to any musical interval, training the user to perceive and produce precise intonation within intervals.

The app builds a perceptual profile of the user's hearing and relentlessly targets weak spots. There are no scores, no gamification, and no session boundaries. Every exercise makes the user better; no single answer matters.

**Design philosophy: "Training, not testing."**

| Capability | Description |
|---|---|
| Adaptive algorithm | Selects comparisons based on the user's perceptual profile; narrows difficulty on correct answers, widens on wrong |
| Perceptual profile | Per-note detection thresholds across the MIDI range, updated incrementally with Welford's algorithm |
| SoundFont audio engine | AVAudioEngine + AVAudioUnitSampler with configurable instrument presets and real-time pitch adjustment |
| Interval training | Musical intervals from Prime through Octave; tuning system abstraction (12-TET, Just Intonation) |
| Fully offline | No network, no backend, no account creation. All data stored locally on-device |

For the complete requirements specification, see [PRD](../planning-artifacts/prd.md).

## Quality Goals

| Priority | Quality Goal | Scenario |
|---|---|---|
| 1 | **Low-friction training experience** | A user opens the app, taps one button, and is training within 2 seconds. Stopping is equally instant — just navigate away. No session summaries, no confirmation dialogs. |
| 2 | **Audio precision and fidelity** | Generated tones are accurate to within 0.1 cent of the target frequency. Notes play with smooth envelopes — no clicks or artifacts on start, stop, or real-time pitch adjustment. Audio latency is imperceptible (< 10ms). |
| 3 | **Data integrity** | Every answered comparison or pitch matching attempt is persisted atomically. Training data survives app crashes, force quits, and device reboots without loss. |
| 4 | **Testability** | Every service boundary is a protocol. All dependencies are injected. The entire domain layer can be tested without UI, audio hardware, or persistence infrastructure. |
| 5 | **Adaptability** | The adaptive algorithm continuously recalibrates to the user's current ability — whether improving through regular training or regressing after a break. No manual intervention required. |

## Stakeholders

| Role | Person | Expectations |
|---|---|---|
| Developer, user, product owner | Michael | A working pitch training tool on his iPhone; a learning platform for iOS/SwiftUI development and AI-assisted workflows |
| AI development agents | Claude Code, etc. | Clear architectural boundaries, consistent patterns, and comprehensive documentation to enable autonomous implementation |
