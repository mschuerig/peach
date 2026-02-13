import SwiftUI
import SwiftData

@main
struct PeachApp: App {
    @State private var modelContainer: ModelContainer
    @State private var trainingSession: TrainingSession

    init() {
        // Create model container
        do {
            let container = try ModelContainer(for: ComparisonRecord.self)
            _modelContainer = State(wrappedValue: container)

            // Create dependencies
            let dataStore = TrainingDataStore(modelContext: container.mainContext)
            let notePlayer = try SineWaveNotePlayer()

            // Create training session
            _trainingSession = State(wrappedValue: TrainingSession(
                notePlayer: notePlayer,
                dataStore: dataStore
            ))
        } catch {
            fatalError("Failed to initialize app: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.trainingSession, trainingSession)
                .modelContainer(modelContainer)
        }
    }
}
