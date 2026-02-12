import SwiftUI
import SwiftData

@main
struct PeachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ComparisonRecord.self])
    }
}
