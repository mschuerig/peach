import Testing
import SwiftUI
@testable import Peach

/// Tests for Profile Screen and PerceptualProfile environment integration
@Suite("ProfileScreen Tests")
@MainActor
struct ProfileScreenTests {

    // MARK: - Task 1: PerceptualProfile Environment Key

    @Test("PerceptualProfile environment key provides default value")
    func environmentKeyDefaultValue() async throws {
        var env = EnvironmentValues()
        let profile = env.perceptualProfile
        #expect(profile.overallMean == nil)
    }

    @Test("PerceptualProfile environment key can be set and retrieved")
    func environmentKeySetAndGet() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: 50, isCorrect: true)

        var env = EnvironmentValues()
        env.perceptualProfile = profile

        let retrieved = env.perceptualProfile
        #expect(retrieved.statsForNote(60).mean == 50.0)
    }

    // MARK: - Task 2: Piano Keyboard Layout

    @Test("Piano layout identifies white and black keys correctly")
    func pianoKeyTypes() async throws {
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 36) == true)  // C2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 37) == false) // C#2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 38) == true)  // D2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 39) == false) // D#2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 40) == true)  // E2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 41) == true)  // F2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 42) == false) // F#2
        #expect(PianoKeyboardLayout.isWhiteKey(midiNote: 60) == true)  // C4 (middle C)
    }

    @Test("Piano layout counts white keys in default range")
    func whiteKeyCount() async throws {
        let layout = PianoKeyboardLayout(midiRange: 36...84)
        #expect(layout.whiteKeyCount == 29)
    }

    @Test("Piano layout provides note name for octave boundaries")
    func noteNames() async throws {
        #expect(PianoKeyboardLayout.noteName(midiNote: 36) == "C2")
        #expect(PianoKeyboardLayout.noteName(midiNote: 48) == "C3")
        #expect(PianoKeyboardLayout.noteName(midiNote: 60) == "C4")
        #expect(PianoKeyboardLayout.noteName(midiNote: 72) == "C5")
        #expect(PianoKeyboardLayout.noteName(midiNote: 84) == "C6")
    }

    @Test("Piano layout X position maps MIDI notes to horizontal coordinates")
    func xPositionMapping() async throws {
        let layout = PianoKeyboardLayout(midiRange: 36...84)
        let totalWidth: CGFloat = 290

        let firstX = layout.xPosition(forMidiNote: 36, totalWidth: totalWidth)
        #expect(firstX >= 0)
        #expect(firstX < totalWidth / 2)

        let lastX = layout.xPosition(forMidiNote: 84, totalWidth: totalWidth)
        #expect(lastX > totalWidth / 2)
        #expect(lastX <= totalWidth)

        let midX = layout.xPosition(forMidiNote: 60, totalWidth: totalWidth)
        #expect(midX > firstX)
        #expect(midX < lastX)
    }

    // MARK: - Task 3: Confidence Band Data Preparation

    @Test("Confidence band data extracts trained notes only")
    func confidenceBandTrainedNotes() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: 30, isCorrect: true)
        profile.update(note: 60, centOffset: 40, isCorrect: true)
        profile.update(note: 62, centOffset: 20, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)

        let trainedPoints = data.filter { $0.isTrained }
        #expect(trainedPoints.count == 2)
    }

    @Test("Confidence band data uses absolute mean for threshold")
    func confidenceBandAbsoluteMean() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: -50, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)
        let point = data.first { $0.midiNote == 60 }!

        #expect(point.threshold == 50.0)
    }

    @Test("Confidence band data computes upper and lower bounds from stdDev")
    func confidenceBandBounds() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: 40, isCorrect: true)
        profile.update(note: 60, centOffset: 50, isCorrect: true)
        profile.update(note: 60, centOffset: 60, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)
        let point = data.first { $0.midiNote == 60 }!

        // mean = 50, stdDev = 10
        #expect(point.threshold == 50.0)
        #expect(point.upperBound == 60.0) // mean + stdDev
        #expect(point.lowerBound == 40.0) // mean - stdDev
    }

    @Test("Confidence band lower bound clamped to log floor")
    func confidenceBandLowerBoundClamped() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: 5, isCorrect: true)
        profile.update(note: 60, centOffset: -5, isCorrect: true)
        profile.update(note: 60, centOffset: 15, isCorrect: true)
        profile.update(note: 60, centOffset: -15, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)
        let point = data.first { $0.midiNote == 60 }!

        // Lower bound clamped to logFloor (0.5) for log scale compatibility
        #expect(point.lowerBound >= ConfidenceBandData.logFloor)
    }

    @Test("Confidence band marks untrained notes as not trained")
    func confidenceBandUntrainedNotes() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: 50, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)

        let untrainedPoint = data.first { $0.midiNote == 61 }!
        #expect(untrainedPoint.isTrained == false)
    }

    // MARK: - Segmentation (Sparse Data)

    @Test("Segments groups contiguous trained notes")
    func segmentsContiguous() async throws {
        let profile = PerceptualProfile()
        // Train notes 60, 61, 62 (contiguous)
        for note in 60...62 {
            profile.update(note: note, centOffset: 30, isCorrect: true)
        }

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 58...64)
        let segments = ConfidenceBandData.segments(from: data)

        // Should be exactly 1 segment with 3 points
        #expect(segments.count == 1)
        #expect(segments[0].points.count == 3)
    }

    @Test("Segments breaks on untrained gaps")
    func segmentsBreaksOnGaps() async throws {
        let profile = PerceptualProfile()
        // Two separate clusters: 60-61 and 64-65 with a gap at 62-63
        profile.update(note: 60, centOffset: 30, isCorrect: true)
        profile.update(note: 61, centOffset: 30, isCorrect: true)
        profile.update(note: 64, centOffset: 30, isCorrect: true)
        profile.update(note: 65, centOffset: 30, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 58...67)
        let segments = ConfidenceBandData.segments(from: data)

        // Should be 2 segments
        #expect(segments.count == 2)
        #expect(segments[0].points.count == 2) // notes 60, 61
        #expect(segments[1].points.count == 2) // notes 64, 65
    }

    @Test("Sparse data far apart creates separate segments")
    func sparseDataSeparateSegments() async throws {
        let profile = PerceptualProfile()
        // Train only notes 36 and 84 (far apart)
        profile.update(note: 36, centOffset: 50, isCorrect: true)
        profile.update(note: 84, centOffset: 30, isCorrect: true)

        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)
        let segments = ConfidenceBandData.segments(from: data)

        // Should be 2 separate segments (no interpolation between them)
        #expect(segments.count == 2)
        #expect(segments[0].points.count == 1)
        #expect(segments[0].points[0].midiNote == 36)
        #expect(segments[1].points.count == 1)
        #expect(segments[1].points[0].midiNote == 84)
    }

    @Test("No segments when no data")
    func segmentsEmpty() async throws {
        let profile = PerceptualProfile()
        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)
        let segments = ConfidenceBandData.segments(from: data)

        #expect(segments.isEmpty)
    }

    // MARK: - Cold Start / Empty State

    @Test("Cold start has no trained data points")
    func coldStartNoData() async throws {
        let profile = PerceptualProfile()
        let data = ConfidenceBandData.prepare(from: profile, midiRange: 36...84)

        let trainedPoints = data.filter { $0.isTrained }
        #expect(trainedPoints.count == 0)
    }
}
