import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Settings Screen")
                .font(.largeTitle)

            Text("Epic 6: Make It Yours - Settings & Configuration")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
