# Story 40.1: Add CSV Format Version Metadata

Status: ready-for-dev

## Story

As a user who exports and imports training data,
I want exported CSV files to contain a format version identifier,
so that future versions of the app can correctly interpret and import my data even if the format evolves.

## Acceptance Criteria

1. Exported CSV files include a metadata line before the header row that identifies the format version
2. The metadata line uses the format `# peach-export-format:1` as the very first line of the file
3. On import, a version reader extracts the format version from the metadata line before any parsing occurs
4. Files without a metadata line are rejected with a clear error (version metadata is required)
5. Files with an unrecognized version produce a localized error telling the user to update the app
6. Version-specific parsing uses a chain of responsibility: each versioned parser declares what version it supports and is consulted in turn
7. Adding a future v2 parser requires only: creating a new `CSVVersionedParser` conformance and registering it — no changes to existing parsers or the orchestrator
8. All current v1 parsing logic (header validation, row parsing, field validation, error collection) is preserved exactly in the v1 parser
9. All existing export and import tests continue to pass (no regressions)
10. New tests cover: version reading, versioned import, missing version rejection, unknown version rejection, malformed metadata, export-then-import round-trip

## Tasks / Subtasks

- [ ] Task 1: Add format version constants to CSVExportSchema (AC: #1, #2)
  - [ ] Add `static let formatVersion = 1` to `CSVExportSchema`
  - [ ] Add `static let metadataPrefix = "# peach-export-format:"` for parsing
  - [ ] Add `static let metadataLine` derived from prefix + formatVersion
  - [ ] Write tests: metadata line format, prefix derivation

- [ ] Task 2: Add new error cases to CSVImportError (AC: #4, #5)
  - [ ] Add `case missingVersion` — "This file does not contain format version metadata. It may have been created by an older version of Peach. Please re-export your data with the current version."
  - [ ] Add `case unsupportedVersion(version: Int)` — "This file uses export format version {version}, which is not supported by this version of Peach. Please update the app to import this file."
  - [ ] Add `case invalidFormatMetadata(line: String)` — "The file contains an unreadable format metadata line: '{line}'."
  - [ ] Add German translations for all three error messages
  - [ ] Write tests: all three error descriptions contain their respective dynamic values

- [ ] Task 3: Create CSVFormatVersionReader (AC: #3, #4)
  - [ ] Create new file `Peach/Core/Data/CSVFormatVersionReader.swift`
  - [ ] `nonisolated enum CSVFormatVersionReader` with a `VersionResult` type and a `static func readVersion(from csvContent: String)` method
  - [ ] `VersionResult` returns either `.success(version: Int, remainingLines: [String])` or `.error(CSVImportError)`
  - [ ] Move `splitIntoLines(_:)` from `CSVImportParser` into this type (it's the line-splitting consumer at this level)
  - [ ] Logic: split content into lines → check first line starts with `CSVExportSchema.metadataPrefix` → extract substring after prefix → parse as `Int` → return version + remaining lines (from line 2 onward, including header)
  - [ ] If first line does not start with prefix → return `.error(.missingVersion)`
  - [ ] If version is not a valid integer → return `.error(.invalidFormatMetadata(line:))`
  - [ ] Write tests in `CSVFormatVersionReaderTests.swift`: valid version line, missing version, malformed version, empty input, version with data lines preserved

- [ ] Task 4: Create CSVVersionedParser protocol (AC: #6, #7)
  - [ ] Create new file `Peach/Core/Data/CSVVersionedParser.swift`
  - [ ] Protocol with two requirements:
    ```swift
    nonisolated protocol CSVVersionedParser {
        var supportedVersion: Int { get }
        func parse(lines: [String]) -> CSVImportParser.ImportResult
    }
    ```
  - [ ] `lines` parameter receives everything after the metadata line (i.e., header + data rows)
  - [ ] No tests needed for the protocol itself

- [ ] Task 5: Extract CSVImportParserV1 from current CSVImportParser (AC: #6, #8)
  - [ ] Create new file `Peach/Core/Data/CSVImportParserV1.swift`
  - [ ] `nonisolated struct CSVImportParserV1: CSVVersionedParser` with `supportedVersion = 1`
  - [ ] Move all current parsing logic from `CSVImportParser` into this struct: `validateHeader`, `parseCSVLine`, `parseRow`, `parseISO8601`, interval reverse lookup, `RowResult` enum
  - [ ] The `parse(lines:)` method receives pre-split lines (header + data). First line is the header — validate it. Remaining lines are data rows — parse each one. Return `ImportResult`
  - [ ] `splitIntoLines` does NOT move here (it moved to `CSVFormatVersionReader` in Task 3)
  - [ ] Write tests in `CSVImportParserV1Tests.swift` — port the subset of current `CSVImportParserTests` that test header validation and row parsing (these now operate on pre-split line arrays rather than full CSV strings)

- [ ] Task 6: Refactor CSVImportParser into thin orchestrator (AC: #3, #5, #6, #7)
  - [ ] Gut `CSVImportParser.swift` — remove all parsing logic (now in V1 parser)
  - [ ] Keep: `ImportResult` struct definition (public API stays here)
  - [ ] Add `private static let parsers: [any CSVVersionedParser] = [CSVImportParserV1()]`
  - [ ] Rewrite `parse(_:)`:
    1. Call `CSVFormatVersionReader.readVersion(from: csvContent)`
    2. On error → return `ImportResult(errors: [error])`
    3. On success → find first parser where `supportedVersion == version`
    4. If no parser found → return `ImportResult(errors: [.unsupportedVersion(version:)])`
    5. Delegate to matched parser's `parse(lines:)`
  - [ ] Update `CSVImportParserTests.swift`: prepend `# peach-export-format:1\n` to all existing test CSV strings (they now go through the full orchestrator pipeline). Add new tests: missing version rejected, unknown version rejected, version dispatch works

- [ ] Task 7: Update TrainingDataExporter to prepend metadata line (AC: #1, #2)
  - [ ] Prepend `CSVExportSchema.metadataLine + "\n"` before the header row in `export(from:)`
  - [ ] Empty-store case: return `metadataLine + "\n" + headerRow` (not just `headerRow`)
  - [ ] Update ALL existing exporter tests — metadata line shifts every line index by +1 (see Exporter Test Update Guide below)
  - [ ] Add round-trip test: export records → `CSVImportParser.parse()` the output → verify parsed records match originals

- [ ] Task 8: Update test data generator script (AC: #2)
  - [ ] In `bin/generate-test-data.py`, write the metadata line `# peach-export-format:1` as the first line of the output file, before the CSV header
  - [ ] The `METADATA_LINE` constant should be defined near the existing `HEADER` constant
  - [ ] Write the metadata line directly with `f.write()` before `csv.writer` takes over (the `#` line is not a CSV row, so it bypasses the csv writer)
  - [ ] Verify generated file imports successfully in the app

- [ ] Task 9: Verify no UI changes needed (AC: #4, #5)
  - [ ] Confirm the existing import error alert in `SettingsScreen` displays all three new error messages correctly
  - [ ] The existing path calls `.errorDescription` on `CSVImportError` — new cases flow through automatically
  - [ ] No code changes needed in UI layer

## Dev Notes

### Architecture: Chain of Responsibility for Versioned Import

```
CSVImportParser.parse(csvContent)          ← public API (unchanged signature)
  │
  ├── CSVFormatVersionReader.readVersion() ← extracts version Int + remaining lines
  │     └── error if missing/malformed
  │
  └── find parser in [any CSVVersionedParser] where supportedVersion == version
        ├── CSVImportParserV1 (version 1)  ← current 12-column parsing logic
        ├── (future) CSVImportParserV2      ← just add here
        └── no match → .unsupportedVersion error
```

**Adding a v2 parser in the future requires only:**
1. Create `CSVImportParserV2: CSVVersionedParser` with `supportedVersion = 2`
2. Add `CSVImportParserV2()` to the `parsers` array in `CSVImportParser`
3. Bump `CSVExportSchema.formatVersion` to `2` (exports use new format)
4. No changes to `CSVImportParserV1`, `CSVFormatVersionReader`, or `CSVImportParser` orchestration logic

### Design Decision: Comment-Style Metadata Line

The metadata line uses `# ` prefix (comment-style) because:
- Standard CSV has no metadata mechanism; comment lines starting with `#` are a widely-used convention
- The header row remains intact on line 2, so the file is still valid CSV if opened in a spreadsheet
- Parsing is unambiguous: check if line 1 starts with `# peach-export-format:`
- Future metadata (e.g., app version, export date) can be added as additional `#` lines without breaking the version parser

### Design Decision: No Backward Compatibility with Unversioned Files

Files without a version metadata line are rejected with a `missingVersion` error. Rationale:
- The app has not yet shipped with export/import on the App Store, so there are no unversioned files in the wild
- Requiring the version line from day one avoids a permanent legacy code path
- The error message guides the user to re-export

### Export Format After This Story

```csv
# peach-export-format:1
trainingType,timestamp,referenceNote,referenceNoteName,targetNote,targetNoteName,interval,tuningSystem,centOffset,isCorrect,initialCentOffset,userCentError
pitchComparison,2026-03-03T14:30:00Z,60,C4,64,E4,M3,equalTemperament,15.5,true,,
pitchMatching,2026-03-03T14:31:00Z,60,C4,67,G4,P5,equalTemperament,,,25.0,3.2
```

### Key Implementation Patterns

- **CSVExportSchema** (`Peach/Core/Data/CSVExportSchema.swift`): Add version constant and metadata line string. Single source of truth for format definition.
- **CSVFormatVersionReader** (`Peach/Core/Data/CSVFormatVersionReader.swift`): New `nonisolated enum`. Reads first line, extracts version. Owns `splitIntoLines(_:)` (moved from current `CSVImportParser`). Returns version + remaining lines or error.
- **CSVVersionedParser** (`Peach/Core/Data/CSVVersionedParser.swift`): New `nonisolated protocol` with `supportedVersion: Int` and `parse(lines:) -> ImportResult`.
- **CSVImportParserV1** (`Peach/Core/Data/CSVImportParserV1.swift`): New `nonisolated struct`. Contains ALL current parsing logic extracted from `CSVImportParser`: `validateHeader`, `parseCSVLine`, `parseRow`, `parseISO8601`, interval lookup. Receives pre-split lines (header + data).
- **CSVImportParser** (`Peach/Core/Data/CSVImportParser.swift`): Becomes thin orchestrator. Keeps `ImportResult` struct. Holds `parsers` array. `parse(_:)` calls version reader then dispatches to matching parser.
- **TrainingDataExporter** (`Peach/Core/Data/TrainingDataExporter.swift`): Prepend `metadataLine + "\n"` before header. Empty-store: `metadataLine + "\n" + headerRow`.
- **CSVImportError** (`Peach/Core/Data/CSVImportError.swift`): Add `missingVersion`, `unsupportedVersion(version:)`, `invalidFormatMetadata(line:)`.

### Files Overview

| File | Action | Description |
|------|--------|-------------|
| `Peach/Core/Data/CSVExportSchema.swift` | Modify | Add `formatVersion`, `metadataLine`, `metadataPrefix` |
| `Peach/Core/Data/CSVImportError.swift` | Modify | Add 3 new error cases |
| `Peach/Core/Data/CSVFormatVersionReader.swift` | **Create** | Version reader with `splitIntoLines` |
| `Peach/Core/Data/CSVVersionedParser.swift` | **Create** | Protocol definition |
| `Peach/Core/Data/CSVImportParserV1.swift` | **Create** | V1 parsing logic extracted from CSVImportParser |
| `Peach/Core/Data/CSVImportParser.swift` | Modify | Gut to thin orchestrator keeping `ImportResult` |
| `Peach/Core/Data/TrainingDataExporter.swift` | Modify | Prepend metadata line |
| `Peach/Resources/Localizable.xcstrings` | Modify | German translations for 3 new error messages |
| `PeachTests/Core/Data/CSVExportSchemaTests.swift` | Modify | Tests for new constants |
| `PeachTests/Core/Data/CSVFormatVersionReaderTests.swift` | **Create** | Version reader tests |
| `PeachTests/Core/Data/CSVImportParserV1Tests.swift` | **Create** | V1 parser unit tests (pre-split line arrays) |
| `PeachTests/Core/Data/CSVImportParserTests.swift` | Modify | Prepend version to all CSV strings; add orchestrator tests |
| `PeachTests/Core/Data/TrainingDataExporterTests.swift` | Modify | Metadata line shifts all indices +1 |
| `bin/generate-test-data.py` | Modify | Prepend metadata line before CSV header |

### Exporter Test Update Guide

The metadata line shifts every line index by +1 in `TrainingDataExporterTests`:

| Test Function | Current Expectation | New Expectation |
|---|---|---|
| `exportMixedRecords` | `lines.count == 3` | `lines.count == 4`; data at `lines[2]`/`lines[3]` |
| `exportComparisonOnly` | `lines.count == 2` | `lines.count == 3`; data at `lines[2]` |
| `exportPitchMatchingOnly` | `lines.count == 2` | `lines.count == 3`; data at `lines[2]` |
| `exportEmptyStore` | csv == `headerRow` | csv == `metadataLine + "\n" + headerRow` |
| `timestampOrdering` | `lines.count == 5` | `lines.count == 6`; all data indices +1 |
| `sameTimestampStableOrder` | `lines.count == 3` | `lines.count == 4`; data indices +1 |
| `csvStartsWithHeader` | `lines[0] == headerRow` | `lines[0] == metadataLine`, `lines[1] == headerRow` |
| `rowCountEqualsRecordsPlusHeader` | `lines.count == 4` | `lines.count == 5` |

**Pattern**: Every `lines[N]` accessing data rows becomes `lines[N+1]`. Every `lines.count == X` becomes `lines.count == X+1`. `lines[0]` is now the metadata line, `lines[1]` is the header.

### Import Parser Test Migration Guide

All existing `CSVImportParserTests` construct CSV strings via the `makeCSV()` helper which prepends the header. After this story:
- Update `makeCSV()` to prepend `CSVExportSchema.metadataLine + "\n"` before the header
- All existing tests then exercise the full pipeline: version reader → v1 parser
- This is correct — `CSVImportParserTests` test the public `CSVImportParser.parse()` API end-to-end
- Add dedicated `CSVImportParserV1Tests` for unit-testing the v1 parser in isolation (receives pre-split lines, no version reader involved)

### Testing Strategy

- **TDD workflow**: Write failing tests first for each task, then implement
- **Swift Testing only**: `@Test`, `@Suite`, `#expect()` — no XCTest
- **Three test levels**: `CSVFormatVersionReaderTests` (version extraction), `CSVImportParserV1Tests` (v1 parsing in isolation), `CSVImportParserTests` (end-to-end orchestration)
- **Round-trip integration test**: Export records via `TrainingDataExporter`, then parse via `CSVImportParser.parse()`, verify parsed records match originals
- **New orchestrator tests**: missing version rejected, unknown version (e.g., 99) rejected, valid version dispatches to v1 parser

### Project Structure Notes

- All files stay within `Core/Data/` (no cross-feature coupling)
- 3 new source files + 2 new test files — all in existing directories
- No new dependencies or imports required
- Follows project conventions: `nonisolated enum` for stateless services, `nonisolated struct` for the v1 parser (value type, no state), `nonisolated protocol` for the parser contract

### References

- [Source: Peach/Core/Data/CSVExportSchema.swift] — Column definitions, header row, training type enum
- [Source: Peach/Core/Data/CSVRecordFormatter.swift] — Record-to-CSV row formatting (unchanged)
- [Source: Peach/Core/Data/TrainingDataExporter.swift] — Export orchestration
- [Source: Peach/Core/Data/CSVImportParser.swift] — Current monolithic parser (to be split)
- [Source: Peach/Core/Data/CSVImportError.swift] — Error types
- [Source: Peach/Core/Data/TrainingDataImporter.swift] — Replace/merge modes (no changes needed)
- [Source: Peach/Settings/SettingsScreen.swift] — Import/export UI (no changes needed)

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
