import SwiftUI

struct TrainingScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Training Screen")
                .font(.largeTitle)

            Text("Epic 3 Story 2: TrainingSession State Machine and Comparison Loop")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Navigation buttons (Settings, Profile) - consistent with Start Screen
            HStack(spacing: 32) {
                NavigationLink(value: NavigationDestination.settings) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
                .accessibilityLabel("Settings")

                NavigationLink(value: NavigationDestination.profile) {
                    Image(systemName: "chart.xyaxis.line")
                        .imageScale(.large)
                }
                .accessibilityLabel("Profile")
            }
            .padding(.bottom)
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .settings:
                SettingsScreen()
            case .profile:
                ProfileScreen()
            case .training:
                TrainingScreen()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainingScreen()
    }
}
