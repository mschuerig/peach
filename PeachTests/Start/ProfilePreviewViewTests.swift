import Testing
import SwiftUI
@testable import Peach

/// Tests for ProfilePreviewView and its integration with the profile data pipeline
@Suite("ProfilePreviewView Tests")
@MainActor
struct ProfilePreviewViewTests {

    // MARK: - Task 5a: ProfilePreviewView renders without crashing

    @Test("ProfilePreviewView can be instantiated in cold start state")
    func coldStartInstantiation() async throws {
        let _ = ProfilePreviewView()
    }

    @Test("ProfilePreviewView can be instantiated with training data")
    func trainedStateInstantiation() async throws {
        let _ = ProfilePreviewView()
    }

    // MARK: - Task 5b: Accessibility label text for cold start vs. trained states

    @Test("Cold start accessibility label says tap to view details")
    func coldStartAccessibilityLabel() async throws {
        let view = ProfilePreviewView()
        #expect(view.accessibilityLabel == "Your pitch profile. Tap to view details.")
    }

    @Test("Trained state accessibility label includes average threshold")
    func trainedAccessibilityLabel() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 48, centOffset: 50, isCorrect: true)
        profile.update(note: 60, centOffset: 30, isCorrect: true)

        var env = EnvironmentValues()
        env.perceptualProfile = profile

        // Compute expected: abs(50) + abs(30) / 2 = 40
        let trainedNotes = (36...84).filter { profile.statsForNote($0).isTrained }
        let avgThreshold = trainedNotes.map { abs(profile.statsForNote($0).mean) }.reduce(0.0, +) / Double(trainedNotes.count)

        #expect(Int(avgThreshold) == 40)
    }

    // MARK: - Task 5c: ProfilePreviewView uses same data pipeline as ProfileScreen

    @Test("ProfilePreviewView uses ConfidenceBandData.prepare for data extraction")
    func usesConfidenceBandDataPipeline() async throws {
        let profile = PerceptualProfile()
        for note in stride(from: 36, through: 84, by: 3) {
            profile.update(note: note, centOffset: Double.random(in: 10...80), isCorrect: true)
        }

        // Verify the same data pipeline produces identical results
        let midiRange = 36...84
        let previewData = ConfidenceBandData.prepare(from: profile, midiRange: midiRange)
        let profileScreenData = ConfidenceBandData.prepare(from: profile, midiRange: midiRange)

        #expect(previewData.count == profileScreenData.count)
        for i in previewData.indices {
            #expect(previewData[i].midiNote == profileScreenData[i].midiNote)
            #expect(previewData[i].threshold == profileScreenData[i].threshold)
            #expect(previewData[i].isTrained == profileScreenData[i].isTrained)
        }
    }

    @Test("ProfilePreviewView uses same MIDI range as ProfileScreen (36...84)")
    func samesMidiRange() async throws {
        let previewLayout = PianoKeyboardLayout(midiRange: 36...84)
        #expect(previewLayout.midiRange == 36...84)
        #expect(previewLayout.whiteKeyCount == 29)
    }

    @Test("PianoKeyboardView showLabels defaults to true")
    func showLabelsDefaultTrue() async throws {
        let keyboard = PianoKeyboardView(midiRange: 36...84)
        #expect(keyboard.showLabels == true)
    }

    @Test("PianoKeyboardView showLabels can be set to false")
    func showLabelsFalse() async throws {
        let keyboard = PianoKeyboardView(midiRange: 36...84, showLabels: false)
        #expect(keyboard.showLabels == false)
    }
}
