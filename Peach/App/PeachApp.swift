import SwiftUI
import SwiftData

@main
struct PeachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Empty schema for now — ComparisonRecord.self added in Story 1.2
        .modelContainer(for: [])
    }
}
