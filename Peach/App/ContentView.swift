import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            StartScreen()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [])
}
