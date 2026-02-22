# 5. Building Block View

## Level 1: System Decomposition

```
Peach/
├── App/              Composition root, navigation shell
├── Core/             Shared services (cross-feature)
│   ├── Audio/        Tone generation
│   ├── Algorithm/    Comparison selection
│   ├── Data/         Persistence
│   └── Profile/      User statistics
├── Training/         Training loop feature
├── Profile/          Profile visualization feature
├── Settings/         Configuration feature
├── Start/            Home screen feature
├── Info/             About screen feature
└── Resources/        Localization, assets
```

## Level 2: Core Services

### Service Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      TrainingSession                        │
│              (state machine, error boundary)                │
│                                                             │
│    ┌──────────┐  ┌──────────────┐  ┌──────────────────┐    │
│    │NotePlayer│  │NextNoteStrat.│  │PerceptualProfile │    │
│    │(protocol)│  │  (protocol)  │  │   (@Observable)  │    │
│    └────┬─────┘  └──────┬───────┘  └────────┬─────────┘    │
│         │               │                    │              │
│         │               │                    │              │
│    ┌────▼─────┐  ┌──────▼───────┐           │              │
│    │SineWave  │  │Adaptive      │           │              │
│    │NotePlayer│  │NoteStrategy  │◀──────────┘              │
│    └──────────┘  └──────────────┘  reads profile           │
│                                                             │
│    Observers: [ComparisonObserver]                          │
│    ┌──────────────┬──────────────┬──────────┬─────────┐    │
│    │TrainingData  │Perceptual   │Haptic    │Trend    │    │
│    │Store         │Profile      │Feedback  │Analyzer │    │
│    │(persistence) │(analytics)  │Manager   │(trends) │    │
│    └──────────────┴──────────────┴──────────┴─────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### TrainingSession

**File:** `Training/TrainingSession.swift`
**Role:** Central orchestrator. The only component that understands a "comparison" as two notes played in sequence with a user answer.

- `@MainActor @Observable final class`
- State machine: `idle` → `playingNote1` → `playingNote2` → `awaitingAnswer` → `showingFeedback` → loop
- Coordinates `NotePlayer`, `NextNoteStrategy`, `PerceptualProfile`
- Notifies `[ComparisonObserver]` on each completed comparison
- Catches all service errors — training continues gracefully
- Reads `@AppStorage` settings live on each comparison

### NotePlayer (protocol) → SineWaveNotePlayer

**Files:** `Core/Audio/NotePlayer.swift`, `Core/Audio/SineWaveNotePlayer.swift`
**Role:** Plays a tone at a given frequency for a given duration.

- Knows only frequencies (Hz), durations, amplitudes
- No concept of MIDI notes, comparisons, or training
- `AVAudioEngine` + `AVAudioPlayerNode` with pre-generated PCM buffers
- 5ms attack/release envelopes to prevent clicks
- 44.1kHz sample rate, mono

### NextNoteStrategy (protocol) → AdaptiveNoteStrategy

**Files:** `Core/Algorithm/NextNoteStrategy.swift`, `Core/Algorithm/AdaptiveNoteStrategy.swift`
**Role:** Selects the next comparison based on the user's profile and settings.

- Stateless: reads `PerceptualProfile` and `lastComparison`, returns a `Comparison`
- **Note selection:** weighted random between Natural (nearby, ±12 semitones) and Mechanical (weak spots from profile), controlled by user's slider setting
- **Difficulty:** Kazez convergence formulas — correct answer narrows (`N = P × [1 - 0.08 × √P]`), wrong answer widens (`N = P × [1 + 0.09 × √P]`)
- **Bootstrap:** when no previous comparison exists, uses neighbor-weighted effective difficulty from up to 5 trained notes in each direction

Also present: `KazezNoteStrategy` — a reference implementation using original Kazez (2001) coefficients, used for evaluation only.

### PerceptualProfile

**File:** `Core/Profile/PerceptualProfile.swift`
**Role:** In-memory aggregate of pitch discrimination ability per MIDI note.

- `@Observable @MainActor final class`
- 128-slot array (MIDI 0–127), each slot holds `PerceptualNote`: mean, stdDev, m2, sampleCount, currentDifficulty
- Welford's online algorithm for incremental mean and variance
- Never persisted — rebuilt from `ComparisonRecord`s on every app launch
- Weak spot identification: untrained notes prioritized, then highest absolute threshold
- Also implements `ComparisonObserver` for automatic incremental updates

### TrainingDataStore

**File:** `Core/Data/TrainingDataStore.swift`
**Role:** Pure persistence layer for `ComparisonRecord`.

- `@MainActor final class`
- CRUD operations: `save`, `fetchAll`, `delete`, `deleteAll`
- Sole accessor of SwiftData `ModelContext`
- Implements `ComparisonObserver` — automatically persists each completed comparison
- Errors are logged but don't propagate (observers don't block training)

### ComparisonRecord

**File:** `Core/Data/ComparisonRecord.swift`
**Role:** SwiftData model — the only persisted entity.

- Fields: `note1` (Int), `note2` (Int), `note2CentOffset` (Double), `isCorrect` (Bool), `timestamp` (Date)
- `note1` and `note2` are always the same MIDI note (note2 differs by cents only)
- Signed `note2CentOffset`: positive = higher, negative = lower

### TrendAnalyzer

**File:** `Core/Profile/TrendAnalyzer.swift`
**Role:** Computes improving/stable/declining trend from historical records.

- Bisects comparison history to compare recent vs. older performance
- Implements `ComparisonObserver` for incremental updates
- Injected via `@Environment(\.trendAnalyzer)`

### FrequencyCalculation

**File:** `Core/Audio/FrequencyCalculation.swift`
**Role:** MIDI note + cent offset → frequency in Hz.

- Static methods, no state
- 0.1-cent precision required — all frequency conversion must go through this file
- Standard formula: `f = referencePitch × 2^((midiNote - 69 + cents/100) / 12)`

## Level 2: Features (UI)

### Screens

| Screen | File | Observes | User Actions |
|---|---|---|---|
| **StartScreen** | `Start/StartScreen.swift` | `PerceptualProfile` (preview) | Start Training, navigate to Profile/Settings/Info |
| **TrainingScreen** | `Training/TrainingScreen.swift` | `TrainingSession` | Higher/Lower buttons, navigate to Settings/Profile |
| **ProfileScreen** | `Profile/ProfileScreen.swift` | `PerceptualProfile`, `TrendAnalyzer` | View confidence band, summary stats |
| **SettingsScreen** | `Settings/SettingsScreen.swift` | `@AppStorage` | Adjust slider, range, duration, pitch; reset data |
| **InfoScreen** | `Info/InfoScreen.swift` | — | View app info |

### Supporting Views

| View | File | Purpose |
|---|---|---|
| `ProfilePreviewView` | `Start/ProfilePreviewView.swift` | Miniature profile on Start Screen |
| `FeedbackIndicator` | `Training/FeedbackIndicator.swift` | Thumbs up/down overlay |
| `HapticFeedbackManager` | `Training/HapticFeedbackManager.swift` | Wrong-answer haptic (ComparisonObserver) |
| `PianoKeyboardView` | `Profile/PianoKeyboardView.swift` | Canvas-rendered keyboard axis |
| `ConfidenceBandView` | `Profile/ConfidenceBandView.swift` | Swift Charts AreaMark visualization |
| `SummaryStatisticsView` | `Profile/SummaryStatisticsView.swift` | Mean, stdDev, trend display |
| `ContentView` | `App/ContentView.swift` | Root navigation shell |
| `NavigationDestination` | `App/NavigationDestination.swift` | Type-safe routing enum |

## File Counts

- **Source:** 30 Swift files in `Peach/`
- **Tests:** 29 Swift files in `PeachTests/` (mirrors source structure)
