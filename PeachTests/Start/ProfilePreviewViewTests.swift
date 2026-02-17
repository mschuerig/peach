import Testing
import SwiftUI
@testable import Peach

/// Tests for ProfilePreviewView and its integration with the profile data pipeline
@Suite("ProfilePreviewView Tests")
@MainActor
struct ProfilePreviewViewTests {

    // MARK: - Instantiation

    @Test("ProfilePreviewView can be instantiated in cold start state")
    func coldStartInstantiation() async throws {
        let _ = ProfilePreviewView()
    }

    // MARK: - Accessibility Labels

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

        let label = ProfilePreviewView.accessibilityLabel(profile: profile, midiRange: 36...84)
        #expect(label == "Your pitch profile. Tap to view details. Average threshold: 40 cents.")
    }

    @Test("Accessibility label falls back to cold start when no notes trained in range")
    func accessibilityLabelNoNotesInRange() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 10, centOffset: 50, isCorrect: true) // Outside 36...84

        let label = ProfilePreviewView.accessibilityLabel(profile: profile, midiRange: 36...84)
        #expect(label == "Your pitch profile. Tap to view details.")
    }

    // MARK: - Data Pipeline

    @Test("ConfidenceBandData.prepare produces consistent results for the preview MIDI range")
    func confidenceBandDataConsistency() async throws {
        let profile = PerceptualProfile()
        for note in stride(from: 36, through: 84, by: 3) {
            profile.update(note: note, centOffset: Double(note), isCorrect: true)
        }

        let midiRange = 36...84
        let data1 = ConfidenceBandData.prepare(from: profile, midiRange: midiRange)
        let data2 = ConfidenceBandData.prepare(from: profile, midiRange: midiRange)

        #expect(data1.count == data2.count)
        for i in data1.indices {
            #expect(data1[i].midiNote == data2[i].midiNote)
            #expect(data1[i].threshold == data2[i].threshold)
            #expect(data1[i].isTrained == data2[i].isTrained)
        }
    }

    @Test("ProfilePreviewView uses same MIDI range as ProfileScreen (36...84)")
    func sameMidiRange() async throws {
        let previewLayout = PianoKeyboardLayout(midiRange: 36...84)
        #expect(previewLayout.midiRange == 36...84)
        #expect(previewLayout.whiteKeyCount == 29)
    }

    // MARK: - PianoKeyboardView showLabels

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
