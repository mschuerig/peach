# 8. Crosscutting Concepts

## Dependency Injection

All services are created in `PeachApp.init()` (composition root) and injected into the view hierarchy via SwiftUI `@Environment`:

```swift
// PeachApp.swift — composition root
ContentView()
    .environment(\.trainingSession, trainingSession)
    .environment(\.perceptualProfile, profile)
    .environment(\.trendAnalyzer, trendAnalyzer)
    .modelContainer(modelContainer)
```

Each injectable service has a custom `EnvironmentKey`:

```swift
struct TrainingSessionKey: EnvironmentKey {
    static var defaultValue: TrainingSession = ...
}
extension EnvironmentValues {
    var trainingSession: TrainingSession { ... }
}
```

Views consume services via `@Environment(\.trainingSession)`. Tests inject mocks directly into `TrainingSession`'s initializer — no environment needed.

## Concurrency Model

**`@MainActor` everywhere UI-facing.** All service classes, all mocks, all test functions are `@MainActor`. The compiler enforces isolation boundaries — there is no manual thread management.

**`async/await` only.** No completion handlers, no Combine, no `DispatchQueue`. Asynchronous work uses structured concurrency with `Task`s that are stored for cancellation.

**`Sendable` at boundaries.** Value types (`Comparison`, `CompletedComparison`, `TrainingSettings`, `PerceptualNote`) are `Sendable` by construction. Reference types stay on `@MainActor`.

## Observer Pattern

`ComparisonObserver` decouples `TrainingSession` from its side-effect handlers:

```swift
protocol ComparisonObserver {
    func comparisonCompleted(_ completed: CompletedComparison)
}
```

Four observers are wired in `PeachApp.init()`:

| Observer | Responsibility |
|---|---|
| `TrainingDataStore` | Persist the `ComparisonRecord` to SwiftData |
| `PerceptualProfile` | Update per-note statistics (Welford's) |
| `HapticFeedbackManager` | Trigger haptic feedback on wrong answer |
| `TrendAnalyzer` | Update improving/stable/declining trend |

Each observer handles its own errors internally. A failure in one observer does not affect the others or the training loop.

## Error Handling Strategy

**Typed error enums per service:**
- `AudioError` — `engineStartFailed`, `nodeAttachFailed`, `renderFailed`, `invalidFrequency`, `contextUnavailable`
- `DataStoreError` — `saveFailed`, `fetchFailed`, `deleteFailed`

**TrainingSession as error boundary:**
- Audio errors → stop training silently (transition to idle)
- Data write errors → log internally, continue training (one lost record is acceptable)
- The user never sees an error screen during training

**Observer error isolation:**
- Each `ComparisonObserver` catches its own errors
- `TrainingDataStore.comparisonCompleted()` wraps `save()` in do/catch
- A failed observer does not block other observers or the training loop

## Testing Approach

**Protocol-based mocking.** Every service has a protocol. Tests inject mocks that conform to the same protocol:

```swift
// Production
TrainingSession(notePlayer: SineWaveNotePlayer(), strategy: AdaptiveNoteStrategy(), ...)

// Test
TrainingSession(notePlayer: MockNotePlayer(), strategy: MockNextNoteStrategy(), ...)
```

**Mock contract (all mocks must provide):**
- Call tracking: `playCallCount`, `lastFrequency`, `playHistory`
- Error injection: `shouldThrowError`, `errorToThrow`
- Synchronous callbacks: `onPlayCalled`, `onStopCalled`
- `instantPlayback` mode for deterministic timing
- `reset()` method for cleanup

**Async testing pattern:**
```swift
@Test("plays note 1 after starting")
@MainActor func playsNote1AfterStarting() async {
    let (session, notePlayer, _) = makeTrainingSession()
    session.startTraining()
    try await waitForState(session, expected: .playingNote1)
    #expect(notePlayer.playCallCount == 1)
}
```

`waitForState` polls the session's state with a timeout — never use raw `#expect` immediately after an async action.

**SwiftData in tests:** Always `ModelConfiguration(isStoredInMemoryOnly: true)`. Never use the production container.

## Data Integrity

- SwiftData atomic writes backed by SQLite — no partial `ComparisonRecord`s
- Only complete comparison results are written (after user answers)
- Incomplete comparisons (interrupted by navigation, phone call, backgrounding) are discarded entirely
- `TrainingDataStore` is the sole writer — no concurrent access to `ModelContext`

## Localization

- String Catalogs (`Localizable.xcstrings`) for English and German
- SwiftUI native `Text("key")` localization
- All user-facing strings are localized; technical terms in logs/comments stay in English

## Accessibility

- All interactive controls labeled for VoiceOver
- Tap targets ≥ 44×44pt (Apple HIG)
- Sufficient color contrast ratios
- Haptic feedback as non-visual complement to the feedback indicator
- `@Environment(\.verticalSizeClass)` for responsive layout (compact vs. regular)
