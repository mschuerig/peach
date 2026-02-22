# 10. Quality Requirements

## Quality Tree

```
Quality
├── Performance
│   ├── Audio latency < 10ms
│   ├── Frequency precision 0.1 cent
│   ├── Comparison round-trip < 100ms
│   ├── App launch < 2s
│   └── Profile rendering < 1s
├── Reliability
│   ├── Atomic data writes
│   ├── Crash-resilient persistence
│   └── Graceful error handling
├── Usability
│   ├── Single-tap start
│   ├── One-handed operation
│   ├── 44×44pt tap targets
│   └── Instant start/stop
├── Testability
│   ├── Protocol-based DI
│   ├── Full suite before commit
│   └── In-memory test containers
└── Maintainability
    ├── Clear service boundaries
    ├── Feature-based organization
    └── 85 documented rules
```

## Quality Scenarios

### QS-1: Audio Latency

| Aspect | Detail |
|---|---|
| **Stimulus** | `TrainingSession` calls `notePlayer.play(frequency:duration:amplitude:)` |
| **Response** | Audible tone output begins |
| **Measure** | < 10ms from method call to sound. Achieved: ~1.5ms (64-sample buffer at 44.1kHz) |
| **Mechanism** | `AVAudioEngine` + `AVAudioPlayerNode` with pre-generated buffer. Audio session configured once at startup. Engine kept running between notes. |

### QS-2: Frequency Precision

| Aspect | Detail |
|---|---|
| **Stimulus** | Algorithm generates a comparison with 2.3-cent difference |
| **Response** | Two tones play at frequencies differing by exactly 2.3 cents |
| **Measure** | Accuracy within 0.1 cent of target. Verified by `FrequencyCalculation` unit tests. |
| **Mechanism** | Mathematical sine generation at `2π × frequency × t / sampleRate`. No pitch quantization. `FrequencyCalculation.swift` is the sole Hz conversion authority. |

### QS-3: Data Integrity Under Crash

| Aspect | Detail |
|---|---|
| **Stimulus** | App is force-quit or crashes mid-training |
| **Response** | All previously answered comparisons are intact on next launch |
| **Measure** | Zero data loss for completed comparisons. Current (unanswered) comparison is discarded. |
| **Mechanism** | SwiftData atomic writes. `TrainingDataStore.save()` calls `modelContext.save()` after each record insert. SQLite WAL journaling handles crash recovery. |

### QS-4: Comparison Round-Trip

| Aspect | Detail |
|---|---|
| **Stimulus** | User answers a comparison |
| **Response** | Next comparison's first note begins playing |
| **Measure** | < 100ms total (feedback phase 400ms is intentional UX, not latency) |
| **Mechanism** | After 0.4s feedback delay, `playNextComparison()` runs immediately. `AdaptiveNoteStrategy.nextComparison()` is < 1ms (in-memory math only). Buffer generation is fast (simple sine wave). |

### QS-5: App Launch Time

| Aspect | Detail |
|---|---|
| **Stimulus** | User launches app |
| **Response** | Start Screen is interactive |
| **Measure** | < 2 seconds |
| **Mechanism** | Minimal startup: create services, rebuild profile from stored records. Profile rebuild from hundreds of records takes < 100ms. No network calls, no heavy asset loading. |

### QS-6: Testability

| Aspect | Detail |
|---|---|
| **Stimulus** | Developer adds a new feature or fixes a bug |
| **Response** | Can write targeted tests using mocks |
| **Measure** | Every service testable in isolation. Full suite runs in < 30 seconds. |
| **Mechanism** | Protocol-based DI. `MockNotePlayer`, `MockNextNoteStrategy`, `MockTrainingDataStore` conform to production protocols. `instantPlayback` mode eliminates real audio delays in tests. In-memory SwiftData containers. |
