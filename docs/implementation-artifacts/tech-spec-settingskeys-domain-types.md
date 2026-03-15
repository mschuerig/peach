# Tech Spec: Replace Primitive Types with Domain Types in SettingsKeys

**Status:** Ready for implementation
**Type:** Refactoring (code quality)
**Date:** 2026-03-15

## Problem

`SettingsKeys.swift` uses primitive types (`Int`, `Double`, `String`) for all default values and constants, violating the project rule that domain types must be used everywhere values carry domain meaning. This makes the code harder to read, removes compile-time safety, and sets a bad example that other code copies.

## Changes Required

### SettingsKeys.swift — Default Values

| Current | Target |
|---|---|
| `defaultNoteRangeMin: Int = 36` | `defaultNoteRangeMin: MIDINote = MIDINote(36)` |
| `defaultNoteRangeMax: Int = 84` | `defaultNoteRangeMax: MIDINote = MIDINote(84)` |
| `defaultNoteDuration: Double = 1.0` | `defaultNoteDuration: NoteDuration = NoteDuration(1.0)` |
| `defaultReferencePitch: Double = 440.0` | `defaultReferencePitch: Frequency = Frequency(440.0)` |
| `defaultSoundSource: String = "sf2:0:0"` | `defaultSoundSource: String = "sf2:0:0"` (see note below) |
| `defaultVaryLoudness: Double = 0.0` | `defaultVaryLoudness: UnitInterval = UnitInterval(0.0)` |
| `defaultTuningSystem: String = "equalTemperament"` | `defaultTuningSystem: TuningSystem = .equalTemperament` |
| `defaultNoteGap: Double = 0.0` | `defaultNoteGap: Duration = .zero` |

**Note on `defaultSoundSource`:** `SoundSourceID` is a protocol, not a concrete value type with a raw string initializer. The `@AppStorage` for sound source stores a raw string (`"sf2:0:0"`). Since there's no lightweight value type that wraps a sound source string, this one stays as `String` for now. If a `SoundSourceTag` or similar value type is introduced later, it should be updated then.

### SettingsKeys.swift — Range Constants

| Current | Target |
|---|---|
| `absoluteMinNote: Int = 21` | `absoluteMinNote: MIDINote = MIDINote(21)` |
| `absoluteMaxNote: Int = 108` | `absoluteMaxNote: MIDINote = MIDINote(108)` |

### SettingsKeys.swift — Range Functions

```swift
// Before
static func lowerBoundRange(noteRangeMax: Int) -> ClosedRange<Int> {
    absoluteMinNote...(noteRangeMax - NoteRange.minimumSpan)
}
static func upperBoundRange(noteRangeMin: Int) -> ClosedRange<Int> {
    (noteRangeMin + NoteRange.minimumSpan)...absoluteMaxNote
}

// After
static func lowerBoundRange(noteRangeMax: MIDINote) -> ClosedRange<MIDINote> {
    absoluteMinNote...MIDINote(noteRangeMax.rawValue - NoteRange.minimumSpan)
}
static func upperBoundRange(noteRangeMin: MIDINote) -> ClosedRange<MIDINote> {
    MIDINote(noteRangeMin.rawValue + NoteRange.minimumSpan)...absoluteMaxNote
}
```

**Prerequisite:** `MIDINote` must conform to `Strideable` (or the range functions must produce ranges a different way). Check if `MIDINote` already supports `ClosedRange`. If not, add `Strideable` conformance to `MIDINote` — this is a natural fit since MIDI notes are discrete integer steps.

### Call-Site Updates

**`SettingsScreen.swift`** — `@AppStorage` properties are necessarily primitive (`@AppStorage` only supports `Int`, `Double`, `String`, `Bool`, `Data`, `URL`). These lines must use `.rawValue` (or equivalent) to extract the primitive from the domain-typed default:

```swift
@AppStorage(SettingsKeys.noteRangeMin) private var noteRangeMin: Int = SettingsKeys.defaultNoteRangeMin.rawValue
@AppStorage(SettingsKeys.noteRangeMax) private var noteRangeMax: Int = SettingsKeys.defaultNoteRangeMax.rawValue
@AppStorage(SettingsKeys.noteDuration) private var noteDuration: Double = SettingsKeys.defaultNoteDuration.rawValue
@AppStorage(SettingsKeys.referencePitch) private var referencePitch: Double = SettingsKeys.defaultReferencePitch.rawValue
@AppStorage(SettingsKeys.varyLoudness) private var varyLoudness: Double = SettingsKeys.defaultVaryLoudness.rawValue
@AppStorage(SettingsKeys.noteGap) private var noteGap: Double = SettingsKeys.defaultNoteGap.seconds  // or however Duration exposes its raw value
```

For `tuningSystemIdentifier`, change the default to use the enum's persistence representation (e.g., `SettingsKeys.defaultTuningSystem.rawValue` if `TuningSystem` is `RawRepresentable<String>`, otherwise its `codable` key — check what `AppUserSettings` uses).

**`AppUserSettings.swift`** — Already wraps into domain types when reading. The fallback defaults change from e.g. `SettingsKeys.defaultNoteDuration` (Double) to `SettingsKeys.defaultNoteDuration.rawValue` (Double).

**`EnvironmentKeys.swift`** — `SettingsKeys.defaultSoundSource` stays String. The `noteGap` line simplifies from `.seconds(SettingsKeys.defaultNoteGap)` to just `SettingsKeys.defaultNoteGap` since it's already a `Duration`.

**`SoundFontNotePlayer.swift`** and **`PeachApp.swift`** — These pass `defaultSoundSource` as a String, unchanged.

### SettingsKeys.swift — `validateSoundSource`

The function's `userDefaults.set(defaultSoundSource, forKey: soundSource)` still writes a String to UserDefaults — this is correct since `defaultSoundSource` remains a String. No change needed here.

## Acceptance Criteria

1. All default values in `SettingsKeys` use their domain type where one exists
2. `absoluteMinNote` and `absoluteMaxNote` are `MIDINote`
3. `lowerBoundRange` and `upperBoundRange` accept and return `MIDINote` ranges
4. `@AppStorage` call sites use `.rawValue` to extract primitives
5. All existing tests pass without behavioral changes
6. No new warnings or errors

## Test Impact

- `SettingsKeysTests` may need minor updates if any assertions compare against the default values (they currently compare Strings for sound source validation, which is unchanged)
- Run full suite to verify no regressions from type changes at call sites

## Out of Scope

- Creating a new `SoundSourceTag` value type for sound source strings (separate concern)
- Refactoring `@AppStorage` usage patterns in `SettingsScreen` beyond updating defaults
- Adding `UnitInterval` if it doesn't exist yet (check first; if missing, creating it is in scope as a minimal value type)
