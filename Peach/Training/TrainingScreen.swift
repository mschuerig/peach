import SwiftUI
import os

struct TrainingScreen: View {
    /// Training session injected via environment
    @Environment(\.trainingSession) private var trainingSession

    /// Whether the user has enabled Reduce Motion in system accessibility settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Vertical size class: .compact in landscape iPhone, .regular in portrait and iPad
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Logger for debugging lifecycle events
    private let logger = Logger(subsystem: "com.peach.app", category: "TrainingScreen")

    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        Group {
            if isCompactHeight {
                HStack(spacing: 8) {
                    higherButton
                    lowerButton
                }
            } else {
                VStack(spacing: 8) {
                    higherButton
                    lowerButton
                }
            }
        }
        .padding()
        .overlay {
            FeedbackIndicator(
                isCorrect: trainingSession.isLastAnswerCorrect,
                iconSize: Self.feedbackIconSize(isCompact: isCompactHeight)
            )
            .opacity(trainingSession.showFeedback ? 1 : 0)
            .animation(Self.feedbackAnimation(reduceMotion: reduceMotion), value: trainingSession.showFeedback)
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
            logger.info("TrainingScreen appeared - starting training")
            trainingSession.startTraining()
        }
        .onDisappear {
            logger.info("TrainingScreen disappeared - stopping training")
            trainingSession.stop()
        }
    }

    // MARK: - Button Views

    private var higherButton: some View {
        Button {
            trainingSession.handleAnswer(isHigher: true)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: Self.buttonIconSize(isCompact: isCompactHeight)))
                Text("Higher")
                    .font(Self.buttonTextFont(isCompact: isCompactHeight))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: Self.buttonMinHeight(isCompact: isCompactHeight))
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .disabled(!buttonsEnabled)
        .accessibilityLabel("Higher")
    }

    private var lowerButton: some View {
        Button {
            trainingSession.handleAnswer(isHigher: false)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: Self.buttonIconSize(isCompact: isCompactHeight)))
                Text("Lower")
                    .font(Self.buttonTextFont(isCompact: isCompactHeight))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: Self.buttonMinHeight(isCompact: isCompactHeight))
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .disabled(!buttonsEnabled)
        .accessibilityLabel("Lower")
    }

    // MARK: - Layout Parameters (extracted for testability)

    static func buttonIconSize(isCompact: Bool) -> CGFloat {
        isCompact ? 60 : 80
    }

    static func buttonMinHeight(isCompact: Bool) -> CGFloat {
        isCompact ? 120 : 200
    }

    static func buttonTextFont(isCompact: Bool) -> Font {
        isCompact ? .title2 : .title
    }

    static func feedbackIconSize(isCompact: Bool) -> CGFloat {
        isCompact ? 70 : 100
    }

    // MARK: - Helpers

    /// Buttons are enabled when in playingNote2 or awaitingAnswer states
    private var buttonsEnabled: Bool {
        trainingSession.state == .playingNote2 || trainingSession.state == .awaitingAnswer
    }

    /// Returns the animation for feedback indicator transitions
    /// Returns nil when Reduce Motion is enabled (instant show/hide)
    static func feedbackAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
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
