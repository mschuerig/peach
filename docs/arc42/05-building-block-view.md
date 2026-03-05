# 5. Building Block View

## Level 1 — Overall System

```mermaid
graph TB
    subgraph "Peach App"
        App["App/<br><i>Composition root,<br>navigation shell</i>"]

        subgraph "Feature Modules"
            Start["Start/<br><i>Home screen,<br>training entry points</i>"]
            PitchComparison["PitchComparison/<br><i>Pitch comparison training<br>screen + UI</i>"]
            PitchMatching["PitchMatching/<br><i>Pitch matching<br>screen + slider</i>"]
            Profile["Profile/<br><i>Profile visualization,<br>statistics</i>"]
            Settings["Settings/<br><i>Configuration UI</i>"]
            Info["Info/<br><i>About screen</i>"]
        end

        subgraph "Core"
            Audio["Core/Audio/<br><i>NotePlayer, SoundFont,<br>PlaybackHandle</i>"]
            Algorithm["Core/Algorithm/<br><i>NextPitchComparisonStrategy,<br>KazezNoteStrategy</i>"]
            Data["Core/Data/<br><i>TrainingDataStore,<br>SwiftData models</i>"]
            ProfileCore["Core/Profile/<br><i>PerceptualProfile,<br>TrendAnalyzer</i>"]
            Training["Core/Training/<br><i>Session protocols,<br>domain value types</i>"]
        end
    end

    App --> Start
    Start --> PitchComparison
    Start --> PitchMatching
    Start --> Profile
    Start --> Settings
    Start --> Info

    PitchComparison --> Training
    PitchComparison --> Audio
    PitchMatching --> Training
    PitchMatching --> Audio

    Training --> Algorithm
    Training --> ProfileCore
    Training --> Data
    Algorithm --> ProfileCore

    Profile --> ProfileCore
    Profile --> Data
    Settings -.->|"@AppStorage<br>(UserDefaults)"| Training
```

### Contained Building Blocks

| Building Block | Responsibility |
|---|---|
| **App/** | Composition root (`PeachApp.swift`): wires all dependencies, injects services into SwiftUI environment. Navigation shell (`ContentView.swift`): hub-and-spoke `NavigationStack`. |
| **Start/** | Home screen with four training entry points (Pitch Comparison, Pitch Matching, Interval Pitch Comparison, Interval Pitch Matching), profile preview sparkline, and navigation to Settings/Profile/Info. |
| **PitchComparison/** | Pitch comparison training UI: Higher/Lower buttons, feedback indicator, difficulty display. Reads `PitchComparisonSession` from environment. |
| **PitchMatching/** | Pitch matching UI: vertical pitch slider, feedback indicator. Reads `PitchMatchingSession` from environment. |
| **Profile/** | Perceptual profile visualization: threshold timeline chart (Swift Charts), summary statistics with trend, matching statistics. |
| **Settings/** | Configuration interface: interval selector, note range, duration, reference pitch, loudness variation, tuning system, sound source picker, reset button. All backed by `@AppStorage`. |
| **Info/** | Static about screen: app name, developer, copyright, version. |
| **Core/Audio/** | Audio playback: `NotePlayer` protocol, `SoundFontNotePlayer` (AVAudioEngine + AVAudioUnitSampler), `PlaybackHandle` for note lifecycle, `SoundFontLibrary` for preset discovery, `AudioSessionInterruptionMonitor`. |
| **Core/Algorithm/** | Pitch comparison selection: `NextPitchComparisonStrategy` protocol, `KazezNoteStrategy` (psychoacoustic staircase algorithm). |
| **Core/Data/** | Persistence: `TrainingDataStore` (SwiftData CRUD), `PitchComparisonRecord` and `PitchMatchingRecord` (`@Model` classes). |
| **Core/Profile/** | User model: `PerceptualProfile` (128-slot per-note statistics via Welford's algorithm), `PitchComparisonProfile` and `PitchMatchingProfile` protocols, `TrendAnalyzer`, `ThresholdTimeline`. |
| **Core/Training/** | Domain types and session protocols: `PitchComparison`, `CompletedPitchComparison`, `CompletedPitchMatching`, `PitchMatchingChallenge`, `PitchComparisonObserver`, `PitchMatchingObserver`, `TrainingSession` protocol, `Resettable`. |

---

## Level 2 — Core/Audio

```mermaid
classDiagram
    class NotePlayer {
        <<protocol>>
        +play(frequency, velocity, amplitudeDB) PlaybackHandle
        +play(frequency, duration, velocity, amplitudeDB)
        +stopAll()
    }

    class PlaybackHandle {
        <<protocol>>
        +stop()
        +adjustFrequency(Frequency)
    }

    class SoundFontNotePlayer {
        -audioEngine: AVAudioEngine
        -sampler: AVAudioUnitSampler
        -userSettings: UserSettings
        +play(...) SoundFontPlaybackHandle
        +stopAll()
        -decompose(frequency) (MIDINote, Cents)
    }

    class SoundFontPlaybackHandle {
        -sampler: AVAudioUnitSampler
        -midiNote: UInt8
        -channel: UInt8
        -hasStopped: Bool
        +stop()
        +adjustFrequency(Frequency)
    }

    class SoundSourceProvider {
        <<protocol>>
        +availableSources: [SoundSourceID]
        +displayName(for: SoundSourceID) String
    }

    class SoundFontLibrary {
        -presets: [SoundSourceID]
        +availableSources: [SoundSourceID]
        +displayName(for: SoundSourceID) String
    }

    class AudioSessionInterruptionMonitor {
        -onStopRequired: () -> Void
        +startMonitoring()
    }

    NotePlayer <|.. SoundFontNotePlayer
    PlaybackHandle <|.. SoundFontPlaybackHandle
    SoundSourceProvider <|.. SoundFontLibrary
    SoundFontNotePlayer ..> SoundFontPlaybackHandle : creates
    SoundFontNotePlayer ..> AudioSessionInterruptionMonitor : uses
```

The audio layer knows only frequencies (Hz), velocities, and amplitudes. It has no concept of MIDI notes, musical intervals, comparisons, or training. The `SoundFontNotePlayer` internally decomposes a frequency into the nearest MIDI note + cent remainder for pitch bend, but this is an implementation detail.

**Key interface — `PlaybackHandle`:** Every `play()` call returns a handle. The caller owns the handle and is responsible for stopping playback. This makes note ownership explicit and enables both fixed-duration (comparison) and indefinite (pitch matching) playback patterns.

---

## Level 2 — Core/Training (Sessions)

```mermaid
classDiagram
    class TrainingSession {
        <<protocol>>
        +start(intervals: Set~DirectedInterval~)
        +stop()
        +isIdle: Bool
    }

    class PitchComparisonSession {
        -state: PitchComparisonSessionState
        -notePlayer: NotePlayer
        -strategy: NextPitchComparisonStrategy
        -profile: PitchComparisonProfile
        -userSettings: UserSettings
        -observers: [PitchComparisonObserver]
        +start(intervals)
        +stop()
        +handleAnswer(isHigher: Bool)
    }

    class PitchMatchingSession {
        -state: PitchMatchingSessionState
        -notePlayer: NotePlayer
        -profile: PitchMatchingProfile
        -observers: [PitchMatchingObserver]
        -userSettings: UserSettings
        +start(intervals)
        +stop()
        +adjustPitch(Double)
        +commitPitch(Double)
    }

    class PitchComparisonObserver {
        <<protocol>>
        +pitchComparisonCompleted(CompletedPitchComparison)
    }

    class PitchMatchingObserver {
        <<protocol>>
        +pitchMatchingCompleted(CompletedPitchMatching)
    }

    TrainingSession <|.. PitchComparisonSession
    TrainingSession <|.. PitchMatchingSession
    PitchComparisonSession ..> PitchComparisonObserver : notifies
    PitchMatchingSession ..> PitchMatchingObserver : notifies
```

Both sessions follow the same patterns: `@Observable` state machines, protocol-based dependency injection, observer fan-out for side effects, and error boundary behavior (audio/persistence failures don't crash the training loop).

---

## Level 2 — Core/Profile

```mermaid
classDiagram
    class PitchComparisonProfile {
        <<protocol>>
        +update(note, centOffset, isCorrect)
        +overallMean: Double?
        +overallStdDev: Double?
        +statsForNote(MIDINote) PerceptualNote
        +weakSpots(count) [MIDINote]
        +setDifficulty(note, difficulty)
        +reset()
    }

    class PitchMatchingProfile {
        <<protocol>>
        +updateMatching(note, centError)
        +matchingMean: Double?
        +matchingStdDev: Double?
        +matchingSampleCount: Int
        +resetMatching()
    }

    class PerceptualProfile {
        -notes: [PerceptualNote] // 128 slots
        -matchingMeanAbs: Double
        -matchingM2: Double
        -matchingCount: Int
        +update(...)
        +updateMatching(...)
    }

    class TrendAnalyzer {
        -absOffsets: [Double]
        +trend: Trend?
    }

    class ThresholdTimeline {
        -dataPoints: [TimelineDataPoint]
        +aggregatedPoints: [AggregatedDataPoint]
        +rollingMean() [Double]
    }

    PitchComparisonProfile <|.. PerceptualProfile
    PitchMatchingProfile <|.. PerceptualProfile
    PitchComparisonObserver <|.. PerceptualProfile
    PitchMatchingObserver <|.. PerceptualProfile
    PitchComparisonObserver <|.. TrendAnalyzer
    PitchComparisonObserver <|.. ThresholdTimeline
```

`PerceptualProfile` is the central user model — a 128-slot array indexed by MIDI note, each slot holding Welford's online statistics (mean, variance, standard deviation, sample count, current difficulty). It is never persisted directly; it is rebuilt from `PitchComparisonRecord` entries on every app launch and updated incrementally during training.
