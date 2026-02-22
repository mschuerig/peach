# 2. Constraints

## Technical Constraints

| Constraint | Rationale |
|---|---|
| **Swift 6.0, iOS 26+** | Latest APIs freely, no backward compatibility. Strict concurrency enforced at compile time (`@MainActor`, `Sendable`). |
| **SwiftUI only** | No UIKit in views. UIKit permitted only through protocol abstractions (e.g., `HapticFeedback` wrapping `UIImpactFeedbackGenerator`). |
| **Zero third-party dependencies** | All first-party Apple frameworks. No external packages without explicit approval. |
| **Single-module app** | No `public`/`open` access control. Default to `private`; `internal` only for cross-file access within the module. |
| **Entirely on-device** | No network layer, no backend, no authentication. All data local. No cloud sync in MVP. |
| **SwiftData for persistence** | `ComparisonRecord` is the only `@Model`. `TrainingDataStore` is the sole accessor — no direct `ModelContext` usage elsewhere. |
| **AVAudioEngine for audio** | Single engine instance, created at app startup. No AudioKit. Protocol-based for future swappable sound sources. |
| **Swift Testing only** | `@Test`, `@Suite`, `#expect()`. No XCTest, no `setUp`/`tearDown`, no class-based suites. Every test is `@MainActor async`. |

## Organizational Constraints

| Constraint | Rationale |
|---|---|
| **Solo developer** | Architecture must be approachable, not over-engineered. Favor clarity over abstraction depth. |
| **AI-assisted development** | AI agents are primary implementers. 85 implementation rules in [project-context.md](../project-context.md) govern agent behavior. |
| **Test-first workflow** | TDD: write failing tests → implement → refactor → full suite → commit. Bug fixes require a reproducing test first. |
| **Commit to main** | No feature branches unless explicitly requested. One commit per story. Full test suite passes before every commit. |

## Conventions

| Area | Convention |
|---|---|
| **Observation** | `@Observable` macro. Never `ObservableObject`/`@Published`. |
| **Dependency injection** | `@Environment` with custom `EnvironmentKey` types. Never `@EnvironmentObject`. |
| **Async** | `async/await` only. No completion handlers, no Combine. |
| **Composition root** | All service instantiation in `PeachApp.swift`. Never create service instances elsewhere. |
| **Screens vs views** | Top-level navigable views: `{Name}Screen.swift`. Child components: `{Name}View.swift`. |
| **Mocks** | `Mock{Name}.swift` in test target. Track calls, support error injection, provide `instantPlayback` mode. |
| **File placement** | Cross-feature service → `Core/{subdomain}/`. Screen → `{Feature}/{Feature}Screen.swift`. No `Utils/`, `Helpers/`, `Shared/`, `Common/` directories. |
