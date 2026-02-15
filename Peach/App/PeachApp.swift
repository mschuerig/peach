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

            // Create and populate perceptual profile from existing data (Story 4.1)
            let profile = PerceptualProfile()
            let existingRecords = try dataStore.fetchAll()
            for record in existingRecords {
                profile.update(
                    note: record.note1,
                    centOffset: record.note2CentOffset,
                    isCorrect: record.isCorrect
                )
            }

            // Create adaptive strategy (Story 4.3)
            let strategy = AdaptiveNoteStrategy()

            // Create training session with observer pattern (Story 4.1) and adaptive strategy (Story 4.3)
            // Observers: dataStore (persistence), profile (analytics), hapticManager (feedback)
            let hapticManager = HapticFeedbackManager()
            let observers: [ComparisonObserver] = [dataStore, profile, hapticManager]
            _trainingSession = State(wrappedValue: TrainingSession(
                notePlayer: notePlayer,
                strategy: strategy,
                profile: profile,
                observers: observers
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
