import SwiftUI

/// Layout calculator for piano keyboard rendering
/// Computes key positions, types, and note names for a given MIDI range
struct PianoKeyboardLayout {
    let midiRange: ClosedRange<Int>

    /// Standard piano key pattern per octave: which pitch classes are white keys
    /// C=0, C#=1, D=2, D#=3, E=4, F=5, F#=6, G=7, G#=8, A=9, A#=10, B=11
    private static let whitePitchClasses: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

    /// Whether a MIDI note is a white key
    static func isWhiteKey(midiNote: Int) -> Bool {
        let pitchClass = midiNote % 12
        return whitePitchClasses.contains(pitchClass)
    }

    /// Note name for a MIDI note (only meaningful at octave boundaries for display)
    static func noteName(midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let pitchClass = midiNote % 12
        let octave = (midiNote / 12) - 1
        return "\(noteNames[pitchClass])\(octave)"
    }

    /// Whether a MIDI note is an octave boundary (C note)
    static func isOctaveBoundary(midiNote: Int) -> Bool {
        midiNote % 12 == 0
    }

    /// Number of white keys in the range
    var whiteKeyCount: Int {
        (midiRange.lowerBound...midiRange.upperBound).filter { Self.isWhiteKey(midiNote: $0) }.count
    }

    /// Width of a single white key given total width
    func whiteKeyWidth(totalWidth: CGFloat) -> CGFloat {
        totalWidth / CGFloat(whiteKeyCount)
    }

    /// X position (center) for a MIDI note within the total width
    /// White keys are evenly distributed; black keys sit between adjacent white keys
    func xPosition(forMidiNote midiNote: Int, totalWidth: CGFloat) -> CGFloat {
        let keyWidth = whiteKeyWidth(totalWidth: totalWidth)

        if Self.isWhiteKey(midiNote: midiNote) {
            // Count white keys before this one
            let whiteIndex = (midiRange.lowerBound..<midiNote).filter { Self.isWhiteKey(midiNote: $0) }.count
            return (CGFloat(whiteIndex) + 0.5) * keyWidth
        } else {
            // Black key sits between the surrounding white keys
            // Find the white key just before and just after
            let prevWhite = (midiRange.lowerBound..<midiNote).reversed().first { Self.isWhiteKey(midiNote: $0) } ?? midiRange.lowerBound
            let nextWhite = ((midiNote + 1)...midiRange.upperBound).first { Self.isWhiteKey(midiNote: $0) } ?? midiRange.upperBound

            let prevX = xPosition(forMidiNote: prevWhite, totalWidth: totalWidth)
            let nextX = xPosition(forMidiNote: nextWhite, totalWidth: totalWidth)
            return (prevX + nextX) / 2.0
        }
    }

    /// Octave boundary notes in the range (C notes) with their note names
    var octaveBoundaries: [(midiNote: Int, name: String)] {
        (midiRange.lowerBound...midiRange.upperBound)
            .filter { Self.isOctaveBoundary(midiNote: $0) }
            .map { (midiNote: $0, name: Self.noteName(midiNote: $0)) }
    }
}

/// Renders a stylized piano keyboard using SwiftUI Canvas
/// Keys are simple rectangles with standard piano proportions
struct PianoKeyboardView: View {
    let layout: PianoKeyboardLayout
    let height: CGFloat
    let showLabels: Bool

    init(midiRange: ClosedRange<Int> = 36...84, height: CGFloat = 60, showLabels: Bool = true) {
        self.layout = PianoKeyboardLayout(midiRange: midiRange)
        self.height = height
        self.showLabels = showLabels
    }

    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                let keyWidth = layout.whiteKeyWidth(totalWidth: size.width)
                let blackKeyWidth = keyWidth * 0.6
                let blackKeyHeight = size.height * 0.6

                // Draw white keys first
                var whiteIndex = 0
                for note in layout.midiRange.lowerBound...layout.midiRange.upperBound {
                    guard PianoKeyboardLayout.isWhiteKey(midiNote: note) else { continue }
                    let x = CGFloat(whiteIndex) * keyWidth
                    let rect = CGRect(x: x, y: 0, width: keyWidth, height: size.height)

                    context.fill(Path(rect), with: .color(.white))
                    context.stroke(Path(rect), with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

                    whiteIndex += 1
                }

                // Draw black keys on top
                for note in layout.midiRange.lowerBound...layout.midiRange.upperBound {
                    guard !PianoKeyboardLayout.isWhiteKey(midiNote: note) else { continue }
                    let centerX = layout.xPosition(forMidiNote: note, totalWidth: size.width)
                    let x = centerX - blackKeyWidth / 2
                    let rect = CGRect(x: x, y: 0, width: blackKeyWidth, height: blackKeyHeight)

                    context.fill(Path(rect), with: .color(.black))
                }
            }
            .frame(height: height)

            if showLabels {
                // Note names at octave boundaries
                GeometryReader { geometry in
                    ForEach(layout.octaveBoundaries, id: \.midiNote) { boundary in
                        let x = layout.xPosition(forMidiNote: boundary.midiNote, totalWidth: geometry.size.width)
                        Text(boundary.name)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .position(x: x, y: 8)
                    }
                }
                .frame(height: 16)
            }
        }
    }
}
