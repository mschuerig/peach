# Story 44.4: Typed Metrics, Generic Accumulator, and Incremental Profile Init

Status: pending

## Story

As a **developer**,
I want MetricPoint to carry typed measurement data, WelfordAccumulator to be generic over measurement type, and PerceptualProfile to initialize incrementally via a closure-based builder,
So that domain typing is preserved through the statistical pipeline, the accumulator is reusable for future measurement types (including 2D), and profile initialization doesn't require loading all records into memory at once.

## Acceptance Criteria

1. **Given** MetricPoint currently stores a bare `Double` value, **when** the refactoring is complete, **then** MetricPoint carries a typed measurement (e.g., `Cents` for pitch comparisons) rather than an erased `Double`, and the type information is preserved through the statistical pipeline.

2. **Given** WelfordAccumulator currently operates on `Double` with `Cents`-specific accessors (`centsMean`, `centsStdDev`) baked in, **when** the refactoring is complete, **then** WelfordAccumulator is generic over measurement type, the statistical algorithm is separated from domain units, and `Cents`-specific accessors are removed from the accumulator itself.

3. **Given** PerceptualProfile currently requires `rebuild(metrics: [TrainingMode: [MetricPoint]])` which loads all records into a dictionary, **when** the refactoring is complete, **then** `rebuild` is removed; PerceptualProfile offers a closure-based initializer where the closure receives an accumulator proxy with a single `addPoint` method, and derived computations (EWMA, trend) run once after the closure completes.

4. **Given** PeachApp.loadPerceptualProfile currently fetches all records, maps them, and passes the full dictionary to `rebuild`, **when** the refactoring is complete, **then** PeachApp uses the closure-based initializer, streaming records through MetricPointMapper into the proxy without materializing the full dataset.

5. **Given** the closure-based initializer receives a proxy parameter, **when** the closure executes, **then** the proxy is a separate type with only an `addPoint` method — not the profile itself — because the profile is not yet fully initialized during the closure.

6. **Given** all existing tests, **when** they are run after the refactoring, **then** all tests pass — no behavioral changes to user-visible functionality.

## Tasks / Subtasks

_To be planned before implementation._

## Dev Notes

### Design sketch: closure-based initializer

```swift
let profile = PerceptualProfile { accumulator in
    // PeachApp fetches records from dataStore, maps each one
    for record in dataStore.fetchPitchComparisons() {
        if let (mode, point) = MetricPointMapper.map(record) {
            accumulator.addPoint(point, for: mode)
        }
    }
}
// EWMA, trend computed once here — not during accumulation
```

The `accumulator` parameter is a proxy type (e.g., `PerceptualProfile.Builder`) that holds `[TrainingMode: TrainingModeStatistics]` and exposes only `addPoint`. Inside `addPoint`, only Welford update + metrics append runs — no EWMA/trend recomputation. After the closure returns, the initializer finalizes all modes.

### Design sketch: generic WelfordAccumulator

```swift
protocol WelfordMeasurement {
    var statisticalValue: Double { get }
    init(statisticalValue: Double)
}

struct WelfordAccumulator<Measurement: WelfordMeasurement> {
    func update(_ value: Measurement)
    var mean: Measurement? { get }
    var stdDev: Measurement? { get }
}
```

`Cents`, and future rhythm measurement types, conform to `WelfordMeasurement`. The accumulator does math on `Double` internally, wraps results in the measurement type on output.

### Design sketch: typed MetricPoint

```swift
struct MetricPoint<Measurement: WelfordMeasurement> {
    let timestamp: Date
    let value: Measurement
}
```

`TrainingModeStatistics` becomes generic over `Measurement`, or uses type erasure internally. The exact approach depends on whether different modes need different measurement types within the same profile — to be determined during planning.

### What this enables for 2D metrics

When rhythm matching introduces a 2D metric (timing + pitch), the measurement type can carry both dimensions. The generic accumulator can be instantiated for the 2D type, and MetricPoint preserves both values through the pipeline without domain erasure.

### Anti-patterns to avoid

- **Do NOT add rhythm types** — that's Epic 45 work
- **Do NOT change EWMA, trend, or bucketing algorithms** — only restructure how data flows in
- **Do NOT make PerceptualProfile generic** — it should use concrete mode-specific measurement types internally
