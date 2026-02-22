# 4. Solution Strategy

## Technology Choices

| Decision | Choice | Rationale |
|---|---|---|
| **Language** | Swift 6.0 | Strict concurrency (compile-time actor isolation). Latest iOS APIs. |
| **UI** | SwiftUI | Declarative, state-driven. `@Observable` macro for reactive updates. No UIKit view code. |
| **Persistence** | SwiftData | Native SwiftUI integration. SQLite-backed atomic writes. Minimal boilerplate for the simple data model. |
| **Audio** | AVAudioEngine + AVAudioPlayerNode | Pre-generated PCM buffers for precise sine waves. ~1.5ms latency (64 samples at 44.1kHz). No third-party audio library needed. |
| **Testing** | Swift Testing | `@Test`/`@Suite`/`#expect()`. Parallel by default. Async-native. Struct-based suites. |
| **DI** | SwiftUI `@Environment` | Custom `EnvironmentKey` types. Composition root in `PeachApp.swift`. |
| **Settings** | `@AppStorage` | UserDefaults wrapper. Keys centralized in `SettingsKeys.swift`. Read live on each comparison. |
| **Localization** | String Catalogs | `Localizable.xcstrings` for English + German. Xcode-native workflow. |

## Architectural Approach

**Feature-based organization with a shared Core layer.** Each screen is a feature module. Cross-feature services live in `Core/` subdirectories grouped by domain (Audio, Algorithm, Data, Profile).

**Protocol-first design.** Every service has a protocol (`NotePlayer`, `NextNoteStrategy`, `ComparisonRecordStoring`). Implementations are injected. Tests use mocks conforming to the same protocols.

**Single orchestrator.** `TrainingSession` is the only component that crosses service boundaries. It coordinates the training loop state machine: generate comparison → play notes → await answer → record result → show feedback → repeat.

**Observer pattern for decoupling.** `ComparisonObserver` protocol allows `TrainingDataStore`, `PerceptualProfile`, `HapticFeedbackManager`, and `TrendAnalyzer` to react to completed comparisons without `TrainingSession` knowing their concrete types.

**In-memory profile, persisted records.** `PerceptualProfile` is never serialized. It is rebuilt from `ComparisonRecord`s on app launch and updated incrementally during training. This keeps the data model flat and the profile computation flexible.

## Key Design Decisions

1. **No session boundaries.** Training starts and stops instantly. There is no "session" object, no timer, no summary screen. The user trains for as long as they want and stops by navigating away.

2. **Cent offset applies to note 2 only.** Note 1 is always an exact MIDI frequency. Note 2 = note 1 ± cent offset. This simplifies the comparison model and frequency calculation.

3. **TrainingSession as error boundary.** Audio or data failures are caught and handled silently. The user never sees error states during training. One lost comparison record is acceptable.

4. **Settings read live.** `TrainingSession` reads `@AppStorage` on every new comparison. Settings changes take effect immediately without restart or re-injection.

5. **Stateless algorithm.** `AdaptiveNoteStrategy` holds no mutable state. It reads the `PerceptualProfile` and `lastComparison` parameter to select the next comparison. Difficulty progression is tracked in the profile and the comparison chain.
