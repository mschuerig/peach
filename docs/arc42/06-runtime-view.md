# 6. Runtime View

## App Startup

```
PeachApp.init()
    │
    ├── ModelContainer(for: ComparisonRecord.self)
    ├── TrainingDataStore(modelContext: container.mainContext)
    ├── SineWaveNotePlayer()
    │
    ├── PerceptualProfile()
    │   └── for record in dataStore.fetchAll():
    │       profile.update(note:centOffset:isCorrect:)    ← rebuild from all records
    │
    ├── TrendAnalyzer(records: existingRecords)
    ├── AdaptiveNoteStrategy()
    ├── HapticFeedbackManager()
    │
    └── TrainingSession(
            notePlayer: notePlayer,
            strategy: strategy,
            profile: profile,
            observers: [dataStore, profile, hapticManager, trendAnalyzer]
        )

    → Inject via @Environment:
        \.trainingSession, \.perceptualProfile, \.trendAnalyzer
    → Inject via .modelContainer():
        SwiftData ModelContainer
```

All services are created once in `PeachApp.init()` and live for the app's lifetime. No lazy initialization, no service locator.

## Training Loop (Core Runtime Scenario)

This is the central runtime behavior — everything else serves this loop.

```
User taps "Start Training"
    │
    ▼
TrainingSession.start()
    │  guard state == .idle
    │  spawn Task { runTrainingLoop() }
    │
    ▼
┌─── playNextComparison() ◀────────────────────────────────┐
│       │                                                    │
│       ├── Read @AppStorage settings (live)                 │
│       ├── strategy.nextComparison(profile, settings,       │
│       │       lastComparison)                              │
│       │       ├── selectNote(): Natural vs Mechanical      │
│       │       └── determineCentDifference(): Kazez formula │
│       │                                                    │
│       ├── comparison.note1Frequency(referencePitch)        │
│       ├── comparison.note2Frequency(referencePitch)        │
│       │                                                    │
│  ┌────▼────────────────────┐                               │
│  │ state = .playingNote1   │                               │
│  │ notePlayer.play(freq1)  │  buttons disabled             │
│  └────┬────────────────────┘                               │
│       │ await completion                                   │
│  ┌────▼────────────────────┐                               │
│  │ state = .playingNote2   │                               │
│  │ notePlayer.play(freq2)  │  buttons enabled              │
│  └────┬────────────────────┘                               │
│       │ await completion (or user answers early)           │
│  ┌────▼────────────────────┐                               │
│  │ state = .awaitingAnswer │  (skipped if answered during  │
│  └────┬────────────────────┘   note2 playback)             │
│       │                                                    │
│       ▼                                                    │
│  User taps Higher or Lower                                 │
│       │                                                    │
│  handleAnswer(isHigher:)                                   │
│       ├── CompletedComparison(comparison, userAnsweredHigher)
│       ├── lastCompletedComparison = completed              │
│       │                                                    │
│       ├── recordComparison(completed)                      │
│       │   └── for observer in observers:                   │
│       │       observer.comparisonCompleted(completed)      │
│       │       ├── TrainingDataStore: save record            │
│       │       ├── PerceptualProfile: update(note,offset)   │
│       │       ├── HapticFeedbackManager: buzz if wrong     │
│       │       └── TrendAnalyzer: update trend              │
│       │                                                    │
│  ┌────▼────────────────────┐                               │
│  │ state = .showingFeedback│                               │
│  │ showFeedback = true     │  thumbs up/down visible       │
│  │ 0.4s delay              │                               │
│  └────┬────────────────────┘                               │
│       │                                                    │
│       └── showFeedback = false ────────────────────────────┘
│
```

### Key Timing

- **Note duration:** configurable (default 1.0s), read from `@AppStorage` per comparison
- **Feedback phase:** 0.4s fixed — perceptual learning design decision
- **Round-trip:** effectively zero delay between feedback end and next note1 start
- **Early answer:** user can tap during note2 playback; note2 stops immediately

## Audio Interruption Handling

```
AVAudioSession.interruptionNotification
    │ (phone call, Siri, alarm)
    ▼
TrainingSession.handleAudioInterruption(typeValue:)
    │ case .began:
    │     stop()  → state = .idle, cancel tasks, stop audio
    │ case .ended:
    │     (no auto-restart — user must tap Start again)

AVAudioSession.routeChangeNotification
    │ (headphone disconnect)
    ▼
TrainingSession.handleAudioRouteChange(reasonValue:)
    │ case .oldDeviceUnavailable:
    │     stop()
    │ other reasons:
    │     continue training
```

Incomplete comparisons are always discarded. No partial data is persisted.

## App Lifecycle

```
App backgrounded during training
    │
    ▼
ContentView.onChange(scenePhase)
    │ .background or .inactive:
    │     trainingSession.stop()
    │
    ▼
App foregrounded
    │ → User sees Start Screen (training was stopped)
    │ → Profile is intact (was updated incrementally)
    │ → Convergence chain lost (lastComparison is nil)
    │   → Bootstrap from neighbor-weighted difficulty on next start
```

## Profile Rebuild on Launch

```
PeachApp.init()
    │
    ├── dataStore.fetchAll()  → [ComparisonRecord] sorted by timestamp
    │
    └── for each record:
            profile.update(
                note: record.note1,
                centOffset: record.note2CentOffset,
                isCorrect: record.isCorrect
            )
            │
            └── Welford's online algorithm:
                    count += 1
                    delta = centOffset - mean
                    mean += delta / count
                    delta2 = centOffset - mean
                    m2 += delta × delta2
                    stdDev = sqrt(m2 / (count - 1))
```

The profile is rebuilt from the complete history on every launch. With hundreds to low thousands of records, this completes in < 100ms.

## Settings Propagation

```
User adjusts slider in SettingsScreen
    │
    ▼
@AppStorage writes to UserDefaults (immediate)
    │
    ▼
Next call to playNextComparison()
    │
    ├── currentSettings reads @AppStorage:
    │   noteRangeMin, noteRangeMax,
    │   naturalVsMechanical, referencePitch
    │
    └── strategy.nextComparison(profile, settings, lastComparison)
        └── Uses updated settings for note selection and range
```

No restart needed. No re-injection. Settings take effect on the very next comparison.
