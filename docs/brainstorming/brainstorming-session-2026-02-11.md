---
inputDocuments: []
session_topic: 'Core requirements for an iOS pitch discrimination ear training app for musicians'
session_goals: 'Discover and document essential requirements — what the app must do, who it serves, and what makes it effective for training fine pitch perception'
selected_approach: 'ai-recommended'
techniques_used: ['Question Storming', 'Role Playing', 'Morphological Analysis']
stepsCompleted: [1, 2, 3, 4]
ideas_generated: []
context_file: ''
session_active: false
workflow_completed: true
---

# Brainstorming Session Results

**Facilitator:** Michael
**Date:** 2026-02-11

## Session Overview

**Topic:** Core requirements for an iOS pitch discrimination ear training app for musicians
**Goals:** Discover and document essential requirements — what the app must do, who it serves, and what makes it effective for training fine pitch perception

### Project Context

This is a **personal project** with three learning goals:

1. **Improve pitch perception** — Michael wants to train his own ability to hear minute pitch differences
2. **Learn iOS development** — using Swift/SwiftUI at their latest iteration
3. **Explore AI-assisted development** — using AI tools throughout the development process

The app is not intended as a commercial product. Michael is the primary user. He has experience with InTune, an existing pitch training app, and identified a fundamental flaw in its approach: it follows a "training through testing" paradigm — escalating difficulty until failure to determine a score. Michael wants the opposite: an app that builds a perceptual profile and targets weak spots.

### Target Users

Musicians (singers, string, woodwind, brass players) for whom intonation is a practical challenge. The app trains the foundational skill underneath good intonation — the ability to precisely hear and distinguish pitches. It is a training tool for pitch discrimination, not a performance or production tool.

## Technique Selection

**Approach:** AI-Recommended Techniques
**Analysis Context:** Pitch discrimination ear training app with focus on comprehensive requirements discovery

**Recommended Techniques:**

- **Question Storming:** Map the full problem space through questions before jumping to solutions — ensures we cover user needs, technical constraints, pedagogical considerations, and edge cases
- **Role Playing:** Step into the shoes of the primary user at different points in their journey (first launch, daily use, returning after a break, settings, physical context) to surface interaction requirements
- **Morphological Analysis:** Systematically map requirements across key dimensions (training loop, algorithm, audio, UI, data, technology) to ensure completeness

**AI Rationale:** Requirements discovery benefits from structured divergent thinking. Question Storming prevents premature solution-jumping. Role Playing ensures real user scenario coverage. Morphological Analysis provides systematic gap-finding to complete the picture.

## Technique Execution Results

### Question Storming

**Interactive Focus:** Explored the core problem space — what musicians struggle with, how pitch discrimination varies across the frequency range, and why existing apps fall short.

**Key Discoveries:**

- **"Training through testing" vs. targeted weakness training** — the fundamental design philosophy. Existing apps like InTune escalate difficulty until failure to produce a score. This app should instead build a perceptual map and train weak spots.
- **Pitch discrimination is not uniform** — a 5-cent difference may be easily detectable in one register and imperceptible in another. Each person has a unique landscape of strong and weak areas.
- **The core interaction loop:** App plays two sequential notes, user answers higher or lower. The intelligence lives entirely in how the app chooses the next pair.
- **Musical model, not frequencies** — the app thinks in musical notes and cents (100 cents = 1 semitone), with A4=440Hz as the configurable reference pitch.
- **No gamification** — no games, trials, attempts, or scores. Continuous training with seamless resume.

### Role Playing

**Interactive Focus:** Walked through five scenarios as Michael using the app in different contexts.

**Scenario 1 — First Launch:** Start page with a prominent "Start Training" button, short app description, and a less prominent settings link. No onboarding, no tutorial — just go.

**Scenario 2 — Training Flow:** Minimal training screen with Higher/Lower buttons (disabled during first note, enabled on second), stop icon, immediate visual feedback (thumbs up/down), haptic on wrong answer. No replay or skip. The feel is instinctive and low-stakes — answering should be reflexive, not deliberate.

**Scenario 3 — Three Weeks In:** Visualization of the perceptual profile as a piano keyboard with a confidence band plot overlaid. Tappable for detail. Factual statistics (total pairs etc.) are fine; no scores. Settings should include note duration, range, algorithm slider, reference pitch, sound source.

**Scenario 4 — Returning After a Break:** No special handling. The algorithm picks up where it left off.

**Scenario 5 — Physical Context:** Designed for incidental use — practice breaks, waiting in line, sitting on the bus. Quick sessions with one-handed, imprecise-tap-friendly buttons. Speaker and headphones both fine. Portrait primary, landscape supported. iPhone and iPad with windowed mode on iPad.

### Morphological Analysis

**Interactive Focus:** Systematic dimension-by-dimension review to verify completeness and surface gaps.

**Dimensions analyzed:** Sound Engine, Adaptive Algorithm, User Interface, Data & Persistence, Accessibility, Technology & Architecture, Audio Generation. This surfaced requirements around audio interruption handling (discard the pair), the per-answer data model (two notes, correct/wrong, timestamp), cold start behavior (random pairs at 100 cents, all notes = weak), iCloud sync, CSV export, test-first development, and localization.

## Organized Requirements

### Core Training Loop

- Sequential note pairs, no overlap, no pause between notes, ~1s per note (configurable)
- User answers Higher or Lower — instinctive, low-stakes interaction
- Immediate feedback: thumbs up/down visual, haptic on wrong
- No replay, no skip — maintains high throughput
- No gamification, no sessions/trials/attempts — continuous training, stop anytime
- Interrupted pairs (phone call, headphone unplug) silently discarded

### Adaptive Algorithm

- Builds a perceptual profile from answer history
- Per-answer data stored: two notes, correct/wrong, timestamp
- On correct: tunable ratio of "harder nearby" vs. "jump to weak spot"
- On wrong: tunable ratio of "easier nearby" vs. "jump to weak spot"
- Weak spots selected randomly, weighted by weakness
- Cold start: random pairs at 100 cents (1 semitone), all notes treated as weak
- Fractional cents (0.1 precision), practical floor ~1 cent
- User-facing "natural vs. mechanical" slider controlling multiple algorithm parameters
- Primary training axis: narrowing the cent gap
- Note range expansion is secondary/incidental
- No special decay handling — the algorithm naturally resurfaces weak areas

### Note Range & Musical Model

- Musical notes as the reference frame, not frequencies
- A4 = 440Hz as configurable reference pitch
- Cents as the unit of pitch difference (100 cents = 1 semitone)
- Configurable range or adaptive mode starting from an octave around C4
- Adaptive expansion when performance at the edges passes a threshold

### Audio Engine

- Smooth playback with proper attack/release envelopes (no clicks)
- V1: sine wave generation
- Swappable sound source architecture — exchangeable at runtime via protocol/interface
- Candidates: AVAudioEngine, possibly AudioKit (if it carries its weight)
- Both notes in a pair always use the same timbre
- System volume only, no in-app volume control
- Future: sampled sounds, MIDI output to external instruments/apps

### User Interface & Experience

- **Start page:** Prominent "Start Training" button, short app description, settings link (less prominent), stylized perceptual profile preview (tappable for detail)
- **Training screen:** Higher/Lower buttons (or symbols), visually disabled during first note, enabled when second note starts. Stop button (icon only). No other controls.
- **Visualization:** Piano keyboard as X-axis with confidence band plot overlaid. Tappable points for detailed statistics.
- **Statistics:** Factual data (total pairs etc.), no scores or levels
- **Settings:** Note duration, note range (manual or adaptive), algorithm slider ("natural vs. mechanical"), reference pitch (A4=440Hz), sound source
- **Design for incidental use:** Bus, queue, practice break. One-handed, quick-tap friendly.

### Technology & Architecture

- Swift / SwiftUI (latest iteration), targeting iOS 26
- Entirely on-device, no backend
- Local persistence + optional iCloud sync across devices
- CSV export of training history
- Test-first development — comprehensive test coverage, non-negotiable
- Portrait + landscape orientation
- iPhone + iPad, with iPad supporting windowed/compact mode
- English + German localization
- Accessibility: low-hanging fruit first (labels, contrast, VoiceOver basics)

### Future Roadmap

- Progress visualization over time (daily/weekly/monthly aggregated plots)
- Manual algorithm focus override (choose a note range to train)
- Configurable pause between notes
- Sampled sounds and MIDI output to external instruments/apps
- Deeper accessibility improvements

## Design Philosophy

**"Training, not testing."** The app doesn't assess the user and give a score. It builds a perceptual map of their hearing and relentlessly trains weak spots. Every interaction makes the user better; no single answer matters. The experience should feel like a pocket trainer — pull it out, do 30 seconds of pairs, put it away.

## Session Summary

**Working Name:** Peach (phonetic similarity to "pitch")

**Key Achievements:**

- Identified the fundamental design philosophy that differentiates this app from existing solutions
- Defined a complete core interaction loop that is minimal, instinctive, and high-throughput
- Specified the adaptive algorithm's behavior, parameters, and cold start strategy
- Established a clear technology stack and architectural decisions (swappable audio, test-first, iCloud sync)
- Mapped the full UI across all screens (start page, training, visualization, settings)
- Clearly separated V1 scope from future enhancements

**Creative Facilitation Narrative:**

This session moved efficiently from problem definition to concrete requirements. The critical breakthrough came early — Michael's articulation of "training through testing" as the paradigm to reject. Everything else flowed from that insight: no scores, no gamification, no sessions, continuous adaptive training targeting weak spots. Role Playing grounded the requirements in real usage scenarios, and Morphological Analysis filled in technical gaps around data persistence, interruption handling, and architecture.
