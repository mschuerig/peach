---
title: 'Extend generate-test-data.py for all training modes'
slug: 'extend-generate-test-data-all-modes'
created: '2026-03-05'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['Python 3']
files_to_modify: ['bin/generate-test-data.py']
code_patterns: ['CSV export schema', 'argparse CLI']
test_patterns: []
---

# Tech-Spec: Extend generate-test-data.py for all training modes

**Created:** 2026-03-05

## Overview

### Problem Statement

The `bin/generate-test-data.py` script only generates `pitchComparison` records with unison intervals (P1). The app has 4 training modes (unison comparison, interval comparison, unison matching, interval matching), but the script cannot produce test data for the other 3 modes. Additionally, the script has a function name typo (`pitch_pitch_comparison_row`) that would crash at runtime.

### Solution

Add CLI options to select which training mode(s) to generate and how many records. Without any options, generate 100 records distributed across random training modes. Fix the existing function name bug.

### Scope

**In Scope:**
- CLI options for each training mode: `--comparison-unison`, `--comparison-interval`, `--matching-unison`, `--matching-interval`
- Optional `--count N` to set number of records (default: 100)
- Without options: 100 records across random training modes
- Generate realistic data for each mode (correct CSV fields, varied intervals for interval modes, varied MIDI notes)
- Fix the `pitch_pitch_comparison_row` typo

**Out of Scope:**
- Changes to the app's CSV import logic
- Changes to CSV schema
- Automated tests for the Python script

## Context for Development

### Codebase Patterns

- CSV schema defined in `CSVExportSchema.swift` — 12 columns, shared header for both training types
- `pitchComparison` records use `centOffset` + `isCorrect` (leave `initialCentOffset`/`userCentError` empty)
- `pitchMatching` records use `initialCentOffset` + `userCentError` (leave `centOffset`/`isCorrect` empty)
- Unison = interval `P1` (rawValue 0); interval modes use non-zero intervals (e.g., `P5`, `M3`)
- The interval column stores abbreviations: P1, m2, M2, m3, M3, P4, d5, P5, m6, M6, m7, M7, P8
- MIDI note range 0-127; typical training range ~48-84 (C3-C6)

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `bin/generate-test-data.py` | Script to modify |
| `Peach/Core/Data/CSVExportSchema.swift` | CSV column definitions and training types |
| `Peach/Core/Data/CSVRecordFormatter.swift` | How records are formatted to CSV |
| `Peach/Core/Audio/Interval.swift` | Interval enum with abbreviations |
| `Peach/Core/Profile/ProgressTimeline.swift` | TrainingMode enum — how modes are distinguished |

### Technical Decisions

- Use `argparse` for CLI option parsing
- Mode options are flags (can combine multiple); `--count` takes an integer
- When no mode flags given, randomly distribute records across all 4 modes
- Spread records across time ranges (months/weeks/days/today) as the current script does
- For interval modes, randomly pick from common intervals (P5, M3, P4, m3, etc.)
- For matching modes, generate realistic `initialCentOffset` (10-50 cents) and `userCentError` (1-15 cents)

## Implementation Plan

### Tasks

- [ ] Task 1: Add interval constants and helpers
  - File: `bin/generate-test-data.py`
  - Action: Add `INTERVALS` dict mapping semitone count to abbreviation (e.g., `{0: "P1", 1: "m2", ...}`). Add helper `random_interval()` that returns `(abbreviation, semitones)` excluding P1. Add helper `random_ref_note()` returning MIDI note in range 48-84.
  - Notes: Must match abbreviations from `Interval.swift`

- [ ] Task 2: Fix and generalize pitch comparison row generator
  - File: `bin/generate-test-data.py`
  - Action: Rename `pitch_pitch_comparison_row` to `pitch_comparison_row`. Add parameters for `interval_abbrev`, `ref_note`, `target_note` instead of hardcoding C4/P1. Default `isCorrect` to random true/false.
  - Notes: Unison mode passes `"P1"` with same ref/target; interval mode passes random interval with target = ref + semitones

- [ ] Task 3: Add pitch matching row generator
  - File: `bin/generate-test-data.py`
  - Action: New function `pitch_matching_row(timestamp, initial_cent_offset, user_cent_error, interval_abbrev, ref_note, target_note)`. Returns row with `trainingType=pitchMatching`, populates `initialCentOffset` and `userCentError`, leaves `centOffset` and `isCorrect` empty.
  - Notes: Mirror structure of `pitch_comparison_row`

- [ ] Task 4: Refactor record generation to support modes
  - File: `bin/generate-test-data.py`
  - Action: Replace `generate_records()` with `generate_records(modes: list[str], count: int)`. Distribute `count` evenly across selected modes. For each mode's share, distribute records across time buckets (months/weeks/days/today) proportionally. Each record uses `random_ref_note()` and appropriate interval/fields per mode.
  - Notes: Modes are `"comparison-unison"`, `"comparison-interval"`, `"matching-unison"`, `"matching-interval"`

- [ ] Task 5: Add argparse CLI and update main
  - File: `bin/generate-test-data.py`
  - Action: Add `argparse.ArgumentParser` with flags `--comparison-unison`, `--comparison-interval`, `--matching-unison`, `--matching-interval`, `--count N` (default 100), and positional `output` (default `test-data.csv`). If no mode flags given, select all 4 modes. Update summary output to show per-mode record counts. Update module docstring.
  - Notes: Positional output arg preserves backward compatibility with `python3 bin/generate-test-data.py output.csv`

### Acceptance Criteria

**AC1: Default behavior (no options)**
- Given: script is run without any options
- When: `python3 bin/generate-test-data.py`
- Then: generates exactly 100 records distributed across random training modes, writes to `test-data.csv`

**AC2: Single mode selection**
- Given: script is run with `--comparison-unison --count 50`
- When: CSV is generated
- Then: all 50 records have `trainingType=pitchComparison` and `interval=P1`

**AC3: Multiple mode selection**
- Given: script is run with `--comparison-unison --matching-interval --count 80`
- When: CSV is generated
- Then: ~40 records each for the two modes, total 80

**AC4: Pitch matching records have correct fields**
- Given: matching mode records are generated
- When: inspecting CSV rows with `trainingType=pitchMatching`
- Then: `initialCentOffset` and `userCentError` are populated; `centOffset` and `isCorrect` are empty

**AC5: Interval mode records have non-unison intervals**
- Given: interval mode records are generated
- When: inspecting CSV rows
- Then: `interval` column contains values other than `P1` (e.g., `P5`, `M3`, etc.)

**AC6: Valid CSV header**
- Given: any invocation of the script
- When: CSV is generated
- Then: header row matches the 12-column schema from `CSVExportSchema`

**AC7: Custom output path**
- Given: `python3 bin/generate-test-data.py custom.csv`
- When: script completes
- Then: file is written to `custom.csv`

## Additional Context

### Dependencies

None — pure Python 3 standard library (csv, random, argparse, datetime).

### Testing Strategy

Manual verification: run script with various option combinations and import into app via Settings > Import Training Data.

### Notes

- The existing time distribution pattern (month/week/day/session buckets) should be preserved — it exercises the chart expansion feature.
- Output path is positional arg (backwards compatible with current usage).
