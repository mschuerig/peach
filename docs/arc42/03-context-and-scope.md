# 3. Context and Scope

## System Context

Peach is a self-contained iOS app with no external system dependencies at runtime.

```
                    ┌─────────────────────────┐
                    │                         │
   User ──────────▶│         Peach           │
   (taps,          │                         │
    listens)       │  ┌───────────────────┐  │
                    │  │  Training Loop    │  │
                    │  │  Audio Engine     │  │
                    │  │  Adaptive Algo    │  │
                    │  │  Profile Store    │  │
                    │  └───────────────────┘  │
                    │                         │
                    └──────────┬──────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │   iOS Platform APIs     │
                    │                         │
                    │  AVAudioEngine          │
                    │  SwiftData / SQLite     │
                    │  UserDefaults           │
                    │  UIImpactFeedbackGen.   │
                    │  AVAudioSession         │
                    └─────────────────────────┘
```

## External Interfaces

| Interface | Direction | Purpose | Technology |
|---|---|---|---|
| **Audio output** | App → Speaker/Headphones | Sine wave tone playback | AVAudioEngine → AVAudioSession |
| **Haptic engine** | App → Taptic Engine | Wrong-answer tactile feedback | UIImpactFeedbackGenerator |
| **Local storage** | App ↔ Filesystem | Comparison records (SwiftData/SQLite) | SwiftData `ModelContainer` |
| **User preferences** | App ↔ Filesystem | Settings (range, duration, pitch, slider) | `@AppStorage` / UserDefaults |
| **Audio interruptions** | iOS → App | Phone calls, Siri, headphone disconnect | AVAudioSession notifications |
| **App lifecycle** | iOS → App | Backgrounding, foregrounding | SwiftUI `ScenePhase` |

## What Peach Does Not Have

- No network access, no API calls, no backend
- No user accounts, no authentication
- No push notifications, no camera, no location
- No in-app purchases
- No iCloud sync (planned post-MVP)
