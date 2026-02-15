import SwiftUI
import os

struct TrainingScreen: View {
    /// Training session injected via environment
    @Environment(\.trainingSession) private var trainingSession

    /// Logger for debugging lifecycle events
    private let logger = Logger(subsystem: "com.peach.app", category: "TrainingScreen")

    var body: some View {
        VStack(spacing: 8) {
            // Higher button - fills top half of screen
            Button {
                trainingSession.handleAnswer(isHigher: true)
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 80))
                    Text("Higher")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 200) // Ensure button exceeds 44x44pt minimum (AC #1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .disabled(!buttonsEnabled)
            .accessibilityLabel("Higher")

            // Lower button - fills bottom half of screen
            Button {
                trainingSession.handleAnswer(isHigher: false)
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 80))
                    Text("Lower")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 200) // Ensure button exceeds 44x44pt minimum (AC #1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .disabled(!buttonsEnabled)
            .accessibilityLabel("Lower")
        }
        .padding()
        .overlay {
            // Feedback indicator overlay (Story 3.3)
            FeedbackIndicator(isCorrect: trainingSession.isLastAnswerCorrect)
                .opacity(trainingSession.showFeedback ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: trainingSession.showFeedback)
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 20) {
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
            }
        }
        .onAppear {
            // Start training immediately when screen appears
            logger.info("TrainingScreen appeared - starting training")
            trainingSession.startTraining()
        }
        .onDisappear {
            // Stop training when leaving screen
            logger.info("TrainingScreen disappeared - stopping training")
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
            let dataStore = MockDataStoreForPreview()
            let profile = PerceptualProfile()
            let strategy = AdaptiveNoteStrategy()
            let hapticManager = MockHapticFeedbackManager()
            let observers: [ComparisonObserver] = [dataStore, profile, hapticManager]
            return TrainingSession(
                notePlayer: MockNotePlayerForPreview(),
                strategy: strategy,
                profile: profile,
                observers: observers
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
private final class MockDataStoreForPreview: ComparisonRecordStoring, ComparisonObserver {
    func save(_ record: ComparisonRecord) throws {}
    func fetchAll() throws -> [ComparisonRecord] { [] }

    func comparisonCompleted(_ completed: CompletedComparison) {
        // No-op for preview
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TrainingScreen()
    }
}
