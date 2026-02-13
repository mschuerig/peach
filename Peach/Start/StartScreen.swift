import SwiftUI

struct StartScreen: View {
    @State private var showInfoSheet = false
    @State private var navigateToTraining = false
    @State private var navigateToSettings = false
    @State private var navigateToProfile = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Profile Preview Placeholder (Epic 5)
            profilePreviewPlaceholder

            Spacer()

            // Start Training Button (Primary Action)
            NavigationLink(value: NavigationDestination.training) {
                Text("Start Training")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()

            // Secondary Navigation Buttons
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

                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .imageScale(.large)
                }
                .accessibilityLabel("Info")
            }
        }
        .padding()
        .navigationTitle("Peach")
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .training:
                TrainingScreen()
            case .settings:
                SettingsScreen()
            case .profile:
                ProfileScreen()
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoScreen()
        }
    }

    private var profilePreviewPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Start training to build your profile")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(.secondary.opacity(0.1))
        .cornerRadius(12)
        .accessibilityLabel("Profile preview: Start training to build your profile")
    }
}

enum NavigationDestination: Hashable {
    case training
    case settings
    case profile
}

#Preview {
    NavigationStack {
        StartScreen()
    }
}
