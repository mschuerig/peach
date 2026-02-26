import SwiftUI

// REVIEW: The slider should not know anything about cents and frequencies. I should only provide a in the range -1.0 .. 1.0. All calculations should be done by PitchMatchingSession.

struct VerticalPitchSlider: View {

    /// Whether the slider responds to touch (active during `playingTunable`)
    var isActive: Bool

    /// Maximum cent deviation in each direction (default ±100 = one semitone)
    var centRange: Double = 100

    /// Reference frequency in Hz for the current challenge
    var referenceFrequency: Double

    /// Called continuously during drag with the current computed frequency
    var onFrequencyChange: (Double) -> Void

    /// Called when the user releases the slider with the final frequency
    var onRelease: (Double) -> Void

    // MARK: - Internal State

    @State private var currentCentOffset: Double = 0

    // MARK: - Layout Constants

    private static let thumbWidth: CGFloat = 80
    private static let thumbHeight: CGFloat = 60

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let trackHeight = geometry.size.height

            ZStack {
                // Blank track — no markings, no labels, no center indicator
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())

                // Thumb handle
                RoundedRectangle(cornerRadius: 12)
                    .fill(.tint)
                    .frame(width: Self.thumbWidth, height: Self.thumbHeight)
                    .position(
                        x: geometry.size.width / 2,
                        y: Self.thumbPosition(
                            centOffset: currentCentOffset,
                            trackHeight: trackHeight,
                            centRange: centRange
                        )
                    )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let result = Self.dragResult(
                            isActive: isActive,
                            dragY: value.location.y,
                            trackHeight: trackHeight,
                            centRange: centRange,
                            referenceFrequency: referenceFrequency
                        ) {
                            currentCentOffset = result.centOffset
                            onFrequencyChange(result.frequency)
                        }
                    }
                    .onEnded { value in
                        if let result = Self.dragResult(
                            isActive: isActive,
                            dragY: value.location.y,
                            trackHeight: trackHeight,
                            centRange: centRange,
                            referenceFrequency: referenceFrequency
                        ) {
                            currentCentOffset = result.centOffset
                            onRelease(result.frequency)
                        }
                    }
            )
            .disabled(!isActive)
            .opacity(isActive ? 1.0 : 0.4)
        }
        .accessibilityLabel(String(localized: "Pitch adjustment slider"))
        .accessibilityAdjustableAction { direction in
            guard isActive else { return }
            let step = centRange / 10.0
            switch direction {
            case .increment:
                currentCentOffset = min(centRange, currentCentOffset + step)
            case .decrement:
                currentCentOffset = max(-centRange, currentCentOffset - step)
            @unknown default:
                break
            }
            let freq = Self.frequency(centOffset: currentCentOffset, referenceFrequency: referenceFrequency)
            onFrequencyChange(freq)
        }
        .accessibilityAction(named: String(localized: "Submit pitch")) {
            guard isActive else { return }
            let freq = Self.frequency(centOffset: currentCentOffset, referenceFrequency: referenceFrequency)
            onRelease(freq)
        }
        .onChange(of: isActive) { oldValue, newValue in
            if !oldValue && newValue {
                // Reset thumb to center when becoming active (new challenge)
                currentCentOffset = 0
            }
        }
    }

    // MARK: - Static Calculation Methods (testable)

    /// Maps a vertical drag position to a cent offset.
    ///
    /// Top of track = +centRange (sharper), center = 0, bottom = -centRange (flatter).
    /// Clamps to [-centRange, +centRange].
    static func centOffset(dragY: CGFloat, trackHeight: CGFloat, centRange: Double) -> Double {
        guard trackHeight > 0 else { return 0 }
        let normalized = dragY / trackHeight       // 0 (top) to 1 (bottom)
        let clamped = min(1.0, max(0.0, normalized))
        // Invert: top (0) = +centRange, bottom (1) = -centRange
        return centRange * (1.0 - 2.0 * clamped)
    }

    /// Computes frequency in Hz from a cent offset and reference frequency.
    static func frequency(centOffset: Double, referenceFrequency: Double) -> Double {
        referenceFrequency * pow(2.0, centOffset / 1200.0)
    }

    /// Computes the Y position of the thumb for a given cent offset.
    ///
    /// Inverse of `centOffset(dragY:trackHeight:centRange:)`.
    static func thumbPosition(centOffset: Double, trackHeight: CGFloat, centRange: Double) -> CGFloat {
        guard centRange > 0 else { return trackHeight / 2 }
        // centOffset = centRange * (1 - 2 * normalized)
        // normalized = (1 - centOffset / centRange) / 2
        let normalized = (1.0 - centOffset / centRange) / 2.0
        return trackHeight * CGFloat(normalized)
    }

    /// Processes a drag gesture position and returns the resulting cent offset and frequency,
    /// or nil if the slider is inactive.
    static func dragResult(
        isActive: Bool,
        dragY: CGFloat,
        trackHeight: CGFloat,
        centRange: Double,
        referenceFrequency: Double
    ) -> (centOffset: Double, frequency: Double)? {
        guard isActive else { return nil }
        let cents = centOffset(dragY: dragY, trackHeight: trackHeight, centRange: centRange)
        let freq = frequency(centOffset: cents, referenceFrequency: referenceFrequency)
        return (cents, freq)
    }
}
