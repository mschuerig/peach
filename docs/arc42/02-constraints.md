# 2. Architecture Constraints

## Technical Constraints

| Constraint | Rationale |
|---|---|
| **iOS 26+, latest Swift/SwiftUI** | No backward compatibility. Enables use of newest APIs (`@Observable`, `@Entry`, Swift Testing, Liquid Glass) without legacy constraints. |
| **Entirely on-device** | No network layer, no backend, no authentication. All data local. Privacy by architecture. |
| **Zero third-party dependencies** | Entire stack is first-party Apple frameworks (SwiftUI, SwiftData, AVAudioEngine, Swift Testing). Eliminates dependency risk and App Store review friction. |
| **Test-first development** | Comprehensive test coverage is a non-negotiable constraint. Influences module structure: every service boundary must be a protocol with injectable dependencies. |
| **iPhone + iPad, portrait + landscape** | Responsive layouts required. No platform-specific branching — same codebase adapts to all form factors. |

## Organizational Constraints

| Constraint | Rationale |
|---|---|
| **Solo developer** | Michael is learning iOS/SwiftUI. Architecture must be approachable — favor clarity over abstraction depth. |
| **AI-assisted development** | AI agents implement features based on tech specs. Architecture documentation and consistent patterns are critical for agent effectiveness. |
| **Personal/learning project** | No commercial metrics, no team coordination overhead. Allows aggressive use of latest-only APIs. |

## Conventions

| Convention | Description |
|---|---|
| **Swift naming conventions** | Types: `PascalCase`. Properties/methods: `camelCase`. Protocols: noun describing capability (`NotePlayer`, not `NotePlayable`). |
| **Feature-based project organization** | Top-level directories by feature (`PitchComparison/`, `PitchMatching/`, `Profile/`, etc.). Shared code in `Core/` with subdirectories by concern. |
| **`@Observable` over `ObservableObject`** | iOS 26 observation model throughout. No `@Published`, no Combine for state management. |
| **Protocol-first service design** | Every service boundary is defined as a protocol before implementation. Enables mock-based testing and future substitution. |
