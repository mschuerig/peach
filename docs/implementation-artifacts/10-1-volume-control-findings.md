# Volume Control Findings — Story 10.1

Research date: 2026-02-24

## Current Audio Graph

```
AVAudioUnitSampler (sampler)
  → engine.mainMixerNode (AVAudioMixerNode, implicit)
  → engine.outputNode (AVAudioOutputNode, implicit)
```

**Amplitude flow today:**
`amplitude: Double (0.0–1.0)` → `midiVelocity(forAmplitude:)` → `sampler.startNote(withVelocity:)` (1–127)

MIDI velocity in SF2 samples controls timbre and dynamics (different velocity layers trigger different sample data), not just loudness.

## Recommended Mechanism: `AVAudioUnitSampler.masterGain`

**`masterGain: Float`** — built-in property on `AVAudioUnitSampler`

| Property | Unit | Range | Default |
|---|---|---|---|
| `masterGain` | dB | -90.0 to +12.0 | 0.0 |

### Why `masterGain` Is the Best Choice

1. **Built-in** — no audio graph changes required; `sampler.masterGain` is already available
2. **dB-native** — the ±2 dB offset range needed by Story 10.5 maps directly with no conversion
3. **Independent of MIDI velocity** — velocity controls timbre/dynamics in SF2 samples; `masterGain` controls output gain
4. **Thread-safe** — it's an Audio Unit parameter (`AudioUnitSetParameter`), designed to be set from any thread
5. **No artifacts between notes** — changing gain after `stopNote` and before `startNote` has no overlapping audio at the change point
6. **Zero latency** — parameter changes take effect immediately

### Alternatives Considered (and Rejected)

| Approach | Unit | Pros | Cons | Verdict |
|---|---|---|---|---|
| `sampler.masterGain` | dB | Built-in, dB-native, no graph change | None significant | **Recommended** |
| `engine.mainMixerNode.outputVolume` | Linear 0.0–1.0 | Simple | Global (affects all audio), needs dB→linear conversion | Rejected: global scope |
| Intermediate `AVAudioMixerNode` | Linear 0.0–1.0 | Per-channel control | Unnecessary graph complexity, needs conversion | Rejected: over-engineered |
| `AVAudioUnitEQ.globalGain` | dB | dB-native | Adds unnecessary node | Rejected: over-engineered |
| MIDI CC7 (`sendController(7, ...)`) | 0–127 | Standard MIDI | Interacts with SF2 in undocumented ways | Rejected: unreliable |

### Key Finding: `AVAudioUnitSampler` Does NOT Have `volume`

The class hierarchy is: `AVAudioUnitSampler` → `AVAudioUnitMIDIInstrument` → `AVAudioUnit` → `AVAudioNode`

`AVAudioNode` and `AVAudioUnit` do **not** conform to the `AVAudioMixing` protocol, so there is no `.volume` property. The `volume` property exists only on nodes that conform to `AVAudioMixing` (e.g., `AVAudioMixerNode`, `AVAudioPlayerNode`).

What `AVAudioUnitSampler` exposes instead:
- `masterGain: Float` (dB, -90.0 to +12.0)
- `stereoPan: Float` (-1.0 to +1.0)
- `globalTuning: Float` (cents)

## Unit System and Conversion

### `masterGain` Uses dB Directly

Since `masterGain` is already in dB, no conversion is needed for the ±2 dB offset range:

```swift
// Set a +2 dB boost
sampler.masterGain = 2.0

// Set a -2 dB cut
sampler.masterGain = -2.0

// Reset to neutral
sampler.masterGain = 0.0
```

### dB ↔ Linear Reference (for context)

If linear conversion is ever needed elsewhere:
- Linear → dB: `dB = 20 * log10(linear)`
- dB → Linear: `linear = pow(10, dB / 20)`
- ±2 dB range in linear: 0.794 – 1.259

### ±2 dB Range Validation

At default `masterGain = 0.0`:
- +2 dB boost = `masterGain = 2.0` — well within the +12.0 dB ceiling; no clipping at the gain stage itself
- -2 dB cut = `masterGain = -2.0` — well within the -90.0 dB floor
- Whether the boosted signal clips at the output depends on the source sample's peak level, but +2 dB on typical SF2 samples with MIDI velocity ≤ 100 should be safe

## Gotchas and Constraints

### Per-Note vs. Global Volume

`masterGain` is **per-sampler** (there is only one sampler instance). It affects all notes played through that sampler. Since `SoundFontNotePlayer` plays one note at a time (note1 stops before note2 starts), setting `masterGain` between notes effectively gives per-note volume control.

**Between-note timing:** notes are ~1s apart. Changing `masterGain` after `stopNote` and before `startNote` is safe — no overlapping audio at the change point.

### Latency

`masterGain` is an Audio Unit parameter. Changes take effect immediately at the audio render level (within the current audio buffer, typically 256–512 samples ≈ 5–11ms at 44.1 kHz). There is no audible delay.

### Clipping

- `masterGain = +2.0 dB` amplifies the sampler's output by a factor of ~1.26
- If the source sample is already near 0 dBFS at the chosen MIDI velocity, +2 dB could push the signal above 0 dBFS, causing digital clipping at the output
- Mitigation: the current `amplitude = 0.5` maps to velocity ~63, which is well below maximum; SF2 samples at mid-velocity are typically -6 dB or more below peak, providing adequate headroom
- If clipping becomes audible, reduce the base velocity or cap `masterGain` at a lower ceiling

### Thread Safety

`masterGain` wraps `AudioUnitSetParameter`, which is documented as safe to call from any thread, including the real-time render thread. Setting `sampler.masterGain` from the main actor while audio renders on the audio thread is the standard expected usage pattern.

**Do NOT** make structural graph changes (attach/detach/connect) on the audio thread — but parameter changes are fine.

### Interaction with MIDI Velocity

`masterGain` and MIDI velocity are **multiplicative** in the signal chain:
1. MIDI velocity selects the sample layer and initial amplitude within the SF2 instrument
2. `masterGain` applies a gain offset to the sampler's output

They are independent — changing `masterGain` does not affect which sample layer the velocity selects. This is exactly the separation needed: velocity controls timbre/dynamics, `masterGain` controls loudness offset.

## Recommended Implementation for Story 10.3

Story 10.2 renames `amplitude` → `velocity` (retyped to `UInt8`). After that, Story 10.3 adds a new `amplitudeDB` parameter for true volume control via `masterGain`. In `SoundFontNotePlayer.play()`, set `masterGain` before starting the note:

```swift
// Story 10.3 sketch (after 10.2 rename is complete):
func play(frequency: Double, duration: TimeInterval, velocity: UInt8 = 64, amplitudeDB: Float = 0.0) async throws {
    // ... existing validation and preset loading ...

    // Set volume offset (independent of MIDI velocity)
    sampler.masterGain = amplitudeDB

    // ... existing note playing logic ...
    sampler.startNote(midiNote, withVelocity: velocity, onChannel: Self.channel)
    // ...
}
```

**No audio graph changes needed.** The current `sampler → mainMixerNode → outputNode` topology stays the same.

## References

- [AVAudioUnitSampler.masterGain — Apple Documentation](https://developer.apple.com/documentation/avfaudio/avaudiounitsampler/mastergain)
- [AVAudioUnitSampler — Apple Documentation](https://developer.apple.com/documentation/avfaudio/avaudiounitsampler)
- [AVAudioMixing protocol — Apple Documentation](https://developer.apple.com/documentation/avfaudio/avaudiomixing)
- [AVAudioMixerNode.outputVolume — Apple Documentation](https://developer.apple.com/documentation/avfaudio/avaudiomixernode/outputvolume)
- [WWDC 2014 Session 502 — AVAudioEngine in Practice](https://asciiwwdc.com/2014/sessions/502)
