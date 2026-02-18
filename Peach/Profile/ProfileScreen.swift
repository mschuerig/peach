import SwiftUI
import Charts

struct ProfileScreen: View {
    @Environment(\.perceptualProfile) private var profile
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let layout = PianoKeyboardLayout(midiRange: 36...84)

    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    // MARK: - Layout Parameters (extracted for testability)

    static func confidenceBandMinHeight(isCompact: Bool) -> CGFloat {
        isCompact ? 120 : 200
    }

    static func keyboardHeight(isCompact: Bool) -> CGFloat {
        isCompact ? 40 : 60
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasTrainingData {
                // Trained state: confidence band + keyboard
                profileVisualization
            } else {
                // Cold start: keyboard + empty state message
                coldStartView
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Trained State

    private var profileVisualization: some View {
        let dataPoints = ConfidenceBandData.prepare(from: profile, midiRange: layout.midiRange)

        return VStack(spacing: 0) {
            Spacer()

            ConfidenceBandView(dataPoints: dataPoints, layout: layout)
                .frame(minHeight: Self.confidenceBandMinHeight(isCompact: isCompactHeight))
                .padding(.horizontal)

            PianoKeyboardView(midiRange: layout.midiRange, height: Self.keyboardHeight(isCompact: isCompactHeight))
                .padding(.horizontal)

            SummaryStatisticsView(midiRange: layout.midiRange)

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Cold Start State

    private var coldStartView: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Start training to build your profile")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            PianoKeyboardView(midiRange: layout.midiRange, height: Self.keyboardHeight(isCompact: isCompactHeight))
                .padding(.horizontal)

            SummaryStatisticsView(midiRange: layout.midiRange)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private var hasTrainingData: Bool {
        profile.overallMean != nil
    }

    private var accessibilitySummary: String {
        Self.accessibilitySummary(profile: profile, midiRange: layout.midiRange)
    }

    /// Computes VoiceOver summary using absolute per-note means
    /// to avoid directional cancellation of signed centOffset values
    @MainActor
    static func accessibilitySummary(profile: PerceptualProfile, midiRange: ClosedRange<Int>) -> String {
        let trainedNotes = midiRange.filter { profile.statsForNote($0).isTrained }

        guard let lowestTrained = trainedNotes.first,
              let highestTrained = trainedNotes.last,
              !trainedNotes.isEmpty else {
            return String(localized: "Perceptual profile. No training data available.")
        }

        let lowestName = PianoKeyboardLayout.noteName(midiNote: lowestTrained)
        let highestName = PianoKeyboardLayout.noteName(midiNote: highestTrained)
        let roundedThreshold = profile.averageThreshold(midiRange: midiRange) ?? 0

        return String(localized: "Perceptual profile showing detection thresholds from \(lowestName) to \(highestName). Average threshold: \(roundedThreshold) cents.")
    }
}

#Preview("With Data") {
    NavigationStack {
        ProfileScreen()
            .environment(\.perceptualProfile, {
                let p = PerceptualProfile()
                for note in stride(from: 36, through: 84, by: 3) {
                    let threshold = Double.random(in: 10...80)
                    p.update(note: note, centOffset: threshold, isCorrect: true)
                    p.update(note: note, centOffset: threshold + 5, isCorrect: true)
                    p.update(note: note, centOffset: threshold - 5, isCorrect: false)
                }
                return p
            }())
            .environment(\.trendAnalyzer, {
                let records = (0..<20).map { i in
                    ComparisonRecord(
                        note1: 60, note2: 60,
                        note2CentOffset: i < 10 ? 50.0 : 30.0,
                        isCorrect: true,
                        timestamp: Date(timeIntervalSince1970: Double(i) * 60)
                    )
                }
                return TrendAnalyzer(records: records)
            }())
    }
}

#Preview("Cold Start") {
    NavigationStack {
        ProfileScreen()
    }
}

// MARK: - Environment Key for PerceptualProfile

private struct PerceptualProfileKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: PerceptualProfile = {
        @MainActor func makeDefault() -> PerceptualProfile {
            PerceptualProfile()
        }
        return MainActor.assumeIsolated {
            makeDefault()
        }
    }()
}

extension EnvironmentValues {
    var perceptualProfile: PerceptualProfile {
        get { self[PerceptualProfileKey.self] }
        set { self[PerceptualProfileKey.self] = newValue }
    }
}
