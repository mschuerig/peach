import SwiftUI
import Charts

struct ProfileScreen: View {
    @Environment(\.perceptualProfile) private var profile

    private let midiRange = 36...84
    private let layout = PianoKeyboardLayout(midiRange: 36...84)

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
        let dataPoints = ConfidenceBandData.prepare(from: profile, midiRange: midiRange)

        return VStack(spacing: 0) {
            Spacer()

            ConfidenceBandView(dataPoints: dataPoints, layout: layout)
                .frame(minHeight: 200)
                .padding(.horizontal)

            PianoKeyboardView(midiRange: midiRange)
                .padding(.horizontal)

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

            PianoKeyboardView(midiRange: midiRange)
                .padding(.horizontal)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private var hasTrainingData: Bool {
        profile.overallMean != nil
    }

    private var accessibilitySummary: String {
        let trainedNotes = (midiRange.lowerBound...midiRange.upperBound)
            .filter { profile.statsForNote($0).isTrained }

        guard let lowestTrained = trainedNotes.first,
              let highestTrained = trainedNotes.last,
              let avgThreshold = profile.overallMean else {
            return "Perceptual profile. No training data available."
        }

        let lowestName = PianoKeyboardLayout.noteName(midiNote: lowestTrained)
        let highestName = PianoKeyboardLayout.noteName(midiNote: highestTrained)
        let roundedThreshold = Int(abs(avgThreshold))

        return "Perceptual profile showing detection thresholds from \(lowestName) to \(highestName). Average threshold: \(roundedThreshold) cents."
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
