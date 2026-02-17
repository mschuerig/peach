import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @AppStorage(SettingsKeys.naturalVsMechanical)
    private var naturalVsMechanical: Double = SettingsKeys.defaultNaturalVsMechanical

    @AppStorage(SettingsKeys.noteRangeMin)
    private var noteRangeMin: Int = SettingsKeys.defaultNoteRangeMin

    @AppStorage(SettingsKeys.noteRangeMax)
    private var noteRangeMax: Int = SettingsKeys.defaultNoteRangeMax

    @AppStorage(SettingsKeys.noteDuration)
    private var noteDuration: Double = SettingsKeys.defaultNoteDuration

    @AppStorage(SettingsKeys.referencePitch)
    private var referencePitch: Double = SettingsKeys.defaultReferencePitch

    @AppStorage(SettingsKeys.soundSource)
    private var soundSource: String = SettingsKeys.defaultSoundSource

    @Environment(\.modelContext) private var modelContext
    @Environment(\.perceptualProfile) private var profile
    @Environment(\.trendAnalyzer) private var trendAnalyzer

    @State private var showResetConfirmation = false

    private static let minimumNoteGap = 12

    var body: some View {
        Form {
            algorithmSection
            noteRangeSection
            audioSection
            dataSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var algorithmSection: some View {
        Section("Algorithm") {
            VStack(alignment: .leading) {
                Text("Natural vs. Mechanical")
                Slider(value: $naturalVsMechanical, in: 0.0...1.0, step: 0.05) {
                    Text("Natural vs. Mechanical")
                } minimumValueLabel: {
                    Text("Natural")
                        .font(.caption2)
                } maximumValueLabel: {
                    Text("Mechanical")
                        .font(.caption2)
                }
            }
        }
    }

    private var noteRangeSection: some View {
        Section("Note Range") {
            Stepper(
                "Lower: \(PianoKeyboardLayout.noteName(midiNote: noteRangeMin))",
                value: $noteRangeMin,
                in: 21...(noteRangeMax - Self.minimumNoteGap),
                step: 1
            )
            Stepper(
                "Upper: \(PianoKeyboardLayout.noteName(midiNote: noteRangeMax))",
                value: $noteRangeMax,
                in: (noteRangeMin + Self.minimumNoteGap)...108,
                step: 1
            )
        }
    }

    private var audioSection: some View {
        Section("Audio") {
            Stepper(
                "Duration: \(noteDuration, specifier: "%.1f")s",
                value: $noteDuration,
                in: 0.3...3.0,
                step: 0.1
            )
            Stepper(
                "Reference Pitch: \(Int(referencePitch)) Hz",
                value: $referencePitch,
                in: 380...500,
                step: 1
            )
            Picker("Sound Source", selection: $soundSource) {
                Text("Sine Wave").tag("sine")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Reset All Training Data", role: .destructive) {
                showResetConfirmation = true
            }
            .confirmationDialog(
                "Reset Training Data",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    resetAllTrainingData()
                }
            } message: {
                Text("This will permanently delete all training data and reset your profile. This cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func resetAllTrainingData() {
        // Delete all ComparisonRecords from SwiftData
        do {
            try modelContext.delete(model: ComparisonRecord.self)
        } catch {
            // SwiftData delete failure — non-fatal, profile/trend still reset
        }

        // Reset PerceptualProfile
        profile.reset()

        // Reset TrendAnalyzer
        trendAnalyzer.reset()
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
    .modelContainer(for: ComparisonRecord.self, inMemory: true)
}
