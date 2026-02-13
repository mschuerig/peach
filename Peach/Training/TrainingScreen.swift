import SwiftUI

struct TrainingScreen: View {
    /// Training session injected via environment
    @Environment(\.trainingSession) private var trainingSession

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Higher/Lower buttons
            HStack(spacing: 60) {
                Button {
                    trainingSession.handleAnswer(isHigher: false)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 60))
                        Text("Lower")
                            .font(.title2)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!buttonsEnabled)
                .accessibilityLabel("Lower")

                Button {
                    trainingSession.handleAnswer(isHigher: true)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 60))
                        Text("Higher")
                            .font(.title2)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!buttonsEnabled)
                .accessibilityLabel("Higher")
            }

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
        .onAppear {
            // Start training immediately when screen appears
            trainingSession.startTraining()
        }
        .onDisappear {
            // Stop training when leaving screen
            trainingSession.stop()
        }
    }

    /// Buttons are enabled when in playingNote2 or awaitingAnswer states
    private var buttonsEnabled: Bool {
        trainingSession.state == .playingNote2 || trainingSession.state == .awaitingAnswer
    }
}

// MARK: - Environment Key for TrainingSession

private struct TrainingSessionKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: TrainingSession = {
        // Default value for previews - uses mock dependencies
        @MainActor func makeDefault() -> TrainingSession {
            TrainingSession(
                notePlayer: MockNotePlayerForPreview(),
                dataStore: MockDataStoreForPreview()
            )
        }
        return MainActor.assumeIsolated {
            makeDefault()
        }
    }()
}

extension EnvironmentValues {
    var trainingSession: TrainingSession {
        get { self[TrainingSessionKey.self] }
        set { self[TrainingSessionKey.self] = newValue }
    }
}

// MARK: - Preview Mocks

@MainActor
private final class MockNotePlayerForPreview: NotePlayer {
    func play(frequency: Double, duration: TimeInterval, amplitude: Double) async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    func stop() async throws {}
}

@MainActor
private final class MockDataStoreForPreview: ComparisonRecordStoring {
    func save(_ record: ComparisonRecord) throws {}
    func fetchAll() throws -> [ComparisonRecord] { [] }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TrainingScreen()
    }
}
