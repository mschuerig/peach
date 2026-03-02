# 6. Runtime View

## Comparison Training Loop

The core training interaction — the user answers a stream of pitch comparisons.

```mermaid
sequenceDiagram
    actor User
    participant CS as ComparisonSession
    participant Strategy as KazezNoteStrategy
    participant Profile as PerceptualProfile
    participant NP as SoundFontNotePlayer
    participant Observers as Observers<br>(DataStore, Profile,<br>Haptic, Trend, Timeline)

    User->>CS: start(intervals)
    activate CS

    loop Each comparison
        CS->>Strategy: nextComparison(profile, settings, lastComparison, interval)
        Strategy->>Profile: read weak spots, mean threshold
        Strategy-->>CS: Comparison(referenceNote, targetNote)

        CS->>CS: state = playingNote1
        CS->>NP: play(frequency1, duration)
        Note over NP: Note 1 plays for configured duration

        CS->>CS: state = playingNote2
        CS->>NP: play(frequency2, duration)
        Note over CS: Buttons enabled — user can answer<br>while note 2 is still playing

        User->>CS: handleAnswer(isHigher: true/false)
        CS->>CS: compute isCorrect
        CS->>Observers: comparisonCompleted(result)
        Note over Observers: DataStore persists record<br>Profile updates statistics<br>HapticManager buzzes on wrong<br>TrendAnalyzer/Timeline update

        CS->>CS: state = showingFeedback (400ms)
        Note over User: Sees thumbs up/down
    end

    User->>CS: stop() [navigate away / background]
    CS->>NP: stop current handle
    CS->>CS: state = idle
    deactivate CS
```

**Key behavior:**
- Buttons are enabled during `playingNote2` — the user can answer before the second note finishes
- The 400ms feedback phase is skippable if the user navigates away
- Audio interruptions (phone call, headphone disconnect) trigger `stop()` automatically via `AudioSessionInterruptionMonitor`

## Pitch Matching Loop

The user tunes a note to match a target pitch.

```mermaid
sequenceDiagram
    actor User
    participant PMS as PitchMatchingSession
    participant NP as SoundFontNotePlayer
    participant Handle as PlaybackHandle
    participant Observers as Observers<br>(DataStore, Profile)

    User->>PMS: start(intervals)
    activate PMS

    loop Each pitch matching attempt
        PMS->>PMS: generate PitchMatchingChallenge<br>(reference + random ±20¢ offset)

        PMS->>PMS: state = playingReference
        PMS->>NP: play(referenceFreq, duration)
        Note over NP: Reference note plays<br>for configured duration

        PMS->>PMS: state = playingTunable
        PMS->>NP: play(tunableFreq) → handle
        Note over PMS: Slider becomes active

        loop User drags slider
            User->>PMS: adjustPitch(sliderValue)
            PMS->>Handle: adjustFrequency(newFreq)
            Note over NP: Real-time pitch bend<br>(14-bit MIDI resolution)
        end

        User->>PMS: commitPitch(finalValue) [releases slider]
        PMS->>Handle: stop()
        PMS->>PMS: compute userCentError
        PMS->>Observers: pitchMatchingCompleted(result)

        PMS->>PMS: state = showingFeedback (400ms)
        Note over User: Sees arrow + cent error
    end

    User->>PMS: stop()
    PMS->>Handle: stop current handle
    PMS->>PMS: state = idle
    deactivate PMS
```

**Key behavior:**
- The slider maps -1.0..+1.0 to ±20 cents from the initial offset
- No visual feedback during active tuning — only after release
- `adjustFrequency()` on the `PlaybackHandle` uses MIDI pitch bend for real-time frequency change

## App Startup and Profile Rebuild

```mermaid
sequenceDiagram
    participant App as PeachApp.init()
    participant DS as TrainingDataStore
    participant Profile as PerceptualProfile
    participant Trend as TrendAnalyzer
    participant Timeline as ThresholdTimeline

    App->>App: Create ModelContainer<br>(ComparisonRecord + PitchMatchingRecord)
    App->>DS: init(modelContext)
    App->>Profile: init()

    App->>DS: fetchAllComparisons()
    DS-->>App: [ComparisonRecord]

    loop Each historical record
        App->>Profile: update(note, centOffset, isCorrect)
        App->>Trend: comparisonCompleted(record)
        App->>Timeline: comparisonCompleted(record)
    end

    App->>DS: fetchAllPitchMatchings()
    DS-->>App: [PitchMatchingRecord]

    loop Each historical record
        App->>Profile: updateMatching(note, centError)
    end

    Note over App: All services wired.<br>Inject into SwiftUI environment.
```

The perceptual profile is never persisted — it is always rebuilt from raw records. This ensures the profile is always consistent with the stored data and simplifies the data model.

## Audio Interruption Handling

```mermaid
stateDiagram-v2
    [*] --> Training : User taps Start

    Training --> Interrupted : Phone call / Headphone disconnect /<br>App backgrounded

    state Interrupted {
        [*] --> StopCurrentNote : AudioSessionInterruptionMonitor<br>fires onStopRequired
        StopCurrentNote --> DiscardIncomplete : Incomplete comparison/<br>match discarded
        DiscardIncomplete --> ReturnToStart : state = idle
    }

    Interrupted --> StartScreen : Navigation stack<br>pops to root

    StartScreen --> Training : User taps Start again
```

Interruption handling is identical for both training modes. The session discards any incomplete attempt — no partial data is ever persisted.
