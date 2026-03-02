# 10. Quality Requirements

## Quality Requirements Overview

| Category | Quality Goal | Priority |
|---|---|---|
| **Performance** | Imperceptible audio latency, instant transitions, precise frequencies | High |
| **Reliability** | Atomic data persistence, crash resilience, graceful interruption handling | High |
| **Usability** | Zero-friction training, one-handed operation, accessible | High |
| **Testability** | Protocol-based services, full mock coverage, test-first workflow | High |
| **Maintainability** | Clean module boundaries, consistent patterns, AI-agent-friendly structure | Medium |

## Quality Scenarios

### QS-1: Audio Latency

| Aspect | Detail |
|---|---|
| **Source** | User taps "Start Training" |
| **Stimulus** | First note of first comparison must play |
| **Response** | Audio output begins |
| **Metric** | Time from tap to audible sound < 10ms (imperceptible). AVAudioEngine with 64-sample buffer at 44.1 kHz achieves ~1.5ms. |

### QS-2: Comparison Transition Speed

| Aspect | Detail |
|---|---|
| **Source** | User answers a comparison (taps Higher/Lower) |
| **Stimulus** | Next comparison must begin |
| **Response** | First note of next comparison plays |
| **Metric** | Transition completes within 500ms (400ms feedback + ~100ms next comparison setup). |

### QS-3: Frequency Precision

| Aspect | Detail |
|---|---|
| **Source** | Algorithm requests a note at a specific cent offset |
| **Stimulus** | Audio engine generates the tone |
| **Response** | Audible frequency matches target |
| **Metric** | Accuracy within 0.1 cent of target frequency. Achieved through mathematical frequency calculation and 14-bit MIDI pitch bend resolution. |

### QS-4: Real-Time Pitch Adjustment

| Aspect | Detail |
|---|---|
| **Source** | User drags pitch matching slider |
| **Stimulus** | Continuous gesture input |
| **Response** | Playing note frequency changes in real time |
| **Metric** | Audible frequency change within 20ms of gesture input. MIDI pitch bend is processed at audio thread priority. |

### QS-5: Data Integrity Under Crash

| Aspect | Detail |
|---|---|
| **Source** | App crash or force quit during training |
| **Stimulus** | Process terminates unexpectedly |
| **Response** | All previously completed records are intact; incomplete attempt is lost |
| **Metric** | Zero completed records lost. SwiftData (SQLite) provides atomic writes. Only completed results are written — incomplete comparisons/matches exist only in memory. |

### QS-6: App Launch to Training-Ready

| Aspect | Detail |
|---|---|
| **Source** | User taps app icon |
| **Stimulus** | App launches |
| **Response** | Start Screen is interactive, profile rebuilt, audio engine ready |
| **Metric** | Interactive within 2 seconds. Profile rebuild from thousands of records completes in milliseconds. Audio engine initialization is fast (no network, no large asset loading). |

### QS-7: Graceful Audio Interruption

| Aspect | Detail |
|---|---|
| **Source** | Phone call, headphone disconnect, Siri activation |
| **Stimulus** | iOS audio session interruption notification |
| **Response** | Training stops, incomplete attempt discarded, no error shown |
| **Metric** | Session transitions to idle within one event loop cycle. No partial data persisted. No user-visible error. |

### QS-8: Accessibility

| Aspect | Detail |
|---|---|
| **Source** | VoiceOver user navigates the app |
| **Stimulus** | All interactive controls and feedback elements |
| **Response** | Correct labels, groupings, and adjustable actions |
| **Metric** | All controls labeled. Tap targets ≥ 44x44 points. Color contrast ≥ 4.5:1 (normal text), ≥ 3:1 (large text). Pitch slider supports `accessibilityAdjustableAction` for VoiceOver in 10% increments. |

### QS-9: Test Coverage

| Aspect | Detail |
|---|---|
| **Source** | Developer writes new feature |
| **Stimulus** | Feature implementation |
| **Response** | Tests written first, all pass before merge |
| **Metric** | Every public protocol method has test coverage. All domain logic tested independently of UI. Mock objects exist for every protocol boundary. |
