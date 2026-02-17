import SwiftUI
import Charts

/// Compact profile preview for the Start Screen
/// Reuses the same data pipeline and rendering as the full ProfileScreen
struct ProfilePreviewView: View {
    @Environment(\.perceptualProfile) private var profile

    private let layout = PianoKeyboardLayout(midiRange: 36...84)

    var body: some View {
        VStack(spacing: 0) {
            if hasTrainingData {
                let dataPoints = ConfidenceBandData.prepare(from: profile, midiRange: layout.midiRange)
                ConfidenceBandView(dataPoints: dataPoints, layout: layout)
                    .frame(height: 45)
            }

            PianoKeyboardView(midiRange: layout.midiRange, height: 25, showLabels: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var hasTrainingData: Bool {
        profile.overallMean != nil
    }

    var accessibilityLabel: String {
        if hasTrainingData {
            let trainedNotes = layout.midiRange.filter { profile.statsForNote($0).isTrained }
            let avgThreshold = trainedNotes.map { abs(profile.statsForNote($0).mean) }.reduce(0.0, +) / Double(trainedNotes.count)
            return "Your pitch profile. Tap to view details. Average threshold: \(Int(avgThreshold)) cents."
        } else {
            return "Your pitch profile. Tap to view details."
        }
    }
}

#Preview("With Data") {
    ProfilePreviewView()
        .padding(.horizontal)
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

#Preview("Cold Start") {
    ProfilePreviewView()
        .padding(.horizontal)
}
