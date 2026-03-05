# 3. Context and Scope

## Business Context

Peach is a standalone, fully offline iOS app. It has no backend, no network communication, and no external service dependencies. The system boundary is the app itself running on the user's device.

```mermaid
C4Context
    title System Context — Peach

    Person(user, "Musician", "Trains pitch perception<br>through comparison and<br>pitch matching exercises")

    System(peach, "Peach", "iOS pitch ear training app.<br>Adaptive algorithm builds<br>perceptual profile and<br>targets weak spots.")

    System_Ext(audio, "iOS Audio System", "AVAudioEngine,<br>AVAudioUnitSampler,<br>device speakers/headphones")
    System_Ext(haptic, "Haptic Engine", "UIImpactFeedbackGenerator<br>for wrong-answer feedback")
    System_Ext(storage, "On-Device Storage", "SwiftData (SQLite)<br>for training records.<br>UserDefaults for settings.")

    Rel(user, peach, "Taps buttons, drags slider,<br>adjusts settings")
    Rel(peach, audio, "Plays notes at precise<br>frequencies via SoundFont")
    Rel(peach, haptic, "Triggers haptic on<br>incorrect comparison answers")
    Rel(peach, storage, "Persists training records<br>and user settings")
```

| Actor / System | Input to Peach | Output from Peach |
|---|---|---|
| **User (musician)** | Tap higher/lower, drag pitch slider, adjust settings | Audio playback, visual feedback, haptic feedback, perceptual profile visualization |
| **iOS Audio System** | Audio interruption notifications (phone call, headphone disconnect) | Note playback commands (MIDI note on/off, pitch bend, preset selection) |
| **On-Device Storage** | Persisted training records, user settings | New comparison/pitch matching records, settings updates |

## Technical Context

```mermaid
graph LR
    subgraph "iOS Device"
        subgraph "Peach App Process"
            UI["SwiftUI Views"]
            Sessions["PitchComparisonSession<br>PitchMatchingSession"]
            Core["Core Services<br>(Algorithm, Profile, Data)"]
            Audio["SoundFontNotePlayer"]
        end

        subgraph "System Frameworks"
            AVAudio["AVAudioEngine<br>+ AVAudioUnitSampler"]
            SwiftData["SwiftData<br>(SQLite)"]
            UserDef["UserDefaults"]
            UIKit["UIImpactFeedbackGenerator"]
        end

        subgraph "Hardware"
            Speaker["Speaker /<br>Headphones"]
            Haptic["Taptic Engine"]
            Flash["Flash Storage"]
        end
    end

    UI --> Sessions
    Sessions --> Core
    Sessions --> Audio
    Core --> SwiftData
    Core --> UserDef
    Audio --> AVAudio
    AVAudio --> Speaker
    Sessions --> UIKit
    UIKit --> Haptic
    SwiftData --> Flash
    UserDef --> Flash
```

All communication is in-process. There are no network channels, no IPC, and no remote services. The only external signals are iOS system notifications (audio interruptions, app lifecycle events).
