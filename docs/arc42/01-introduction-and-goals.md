# 1. Introduction and Goals

## What is Peach?

Peach is an iOS ear training app that improves pitch discrimination through adaptive, rapid two-note comparisons. Two tones play in sequence; the user taps "Higher" or "Lower." The app builds a perceptual profile of the user's hearing across their pitch range and targets weak spots.

**Design philosophy: "Training, not testing."** No scores, no sessions, no gamification. Every comparison makes the user better; no single answer matters.

## Requirements Overview

The architecture must support three core capabilities:

| Capability | Description | Key Requirement |
|---|---|---|
| **Adaptive training loop** | Continuous comparisons with immediate feedback. Start/stop with zero friction. One-handed, reflexive interaction. | < 100ms round-trip between comparisons |
| **Precision audio** | Sine wave generation at exact frequencies derived from MIDI notes and cent offsets. Smooth envelopes, no artifacts. | < 10ms latency, 0.1-cent accuracy |
| **Perceptual profile** | Per-note aggregate of detection thresholds. Rebuilt from raw data on launch, updated incrementally during training. Drives adaptive note selection. | 128-slot MIDI array, Welford's algorithm |

44 functional requirements (FR1–FR43 + FR7a) across 8 categories: Training Loop, Adaptive Algorithm, Audio Engine, Profile & Statistics, Data Persistence, Settings, Localization, Device & Platform.

12 non-functional requirements covering performance, accessibility, and data integrity.

See the [PRD](../planning-artifacts/prd.md) for the full specification.

## Quality Goals

| Priority | Goal | Measure |
|---|---|---|
| 1 | **Low-friction training** | User can begin training with a single tap. Stopping is instant (navigate away or background the app). No session boundaries. |
| 2 | **Audio precision** | Tones accurate to 0.1 cent. Latency < 10ms (achieved: ~1.5ms with 64-sample buffer at 44.1kHz). No clicks or artifacts. |
| 3 | **Data integrity** | Every answered comparison persisted atomically. Data survives crashes, force quits, device reboots. |
| 4 | **Testability** | Protocol-based services with injected dependencies. Full test suite runs before every commit. |
| 5 | **Simplicity** | Architecture matches project complexity. No over-engineering. Solo developer on unfamiliar platform; favor clarity over abstraction depth. |

## Stakeholders

| Role | Expectations |
|---|---|
| **Michael (developer & primary user)** | Usable app for daily pitch training. Learning vehicle for iOS/SwiftUI development and AI-assisted workflows. |
| **AI coding agents** | Clear architectural boundaries and implementation rules (documented in [project-context.md](../project-context.md)). Testable interfaces. Unambiguous file placement conventions. |
| **Future contributors** | Understandable codebase with comprehensive tests. Self-documenting service boundaries. |
