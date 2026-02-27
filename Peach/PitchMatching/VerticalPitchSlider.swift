import SwiftUI

struct VerticalPitchSlider: View {

    /// Whether the slider responds to touch (active during `playingTunable`)
    var isActive: Bool

    /// Called continuously during drag with the current normalized value in -1.0...1.0
    var onNormalizedValueChange: (Double) -> Void

    /// Called when the user releases the slider with the final normalized value
    var onCommit: (Double) -> Void

    // MARK: - Internal State

    @State private var currentNormalizedValue: Double = 0

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
                            normalizedValue: currentNormalizedValue,
                            trackHeight: trackHeight
                        )
                    )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isActive else { return }
                        let normalized = Self.normalizedValue(dragY: value.location.y, trackHeight: trackHeight)
                        currentNormalizedValue = normalized
                        onNormalizedValueChange(normalized)
                    }
                    .onEnded { value in
                        guard isActive else { return }
                        let normalized = Self.normalizedValue(dragY: value.location.y, trackHeight: trackHeight)
                        currentNormalizedValue = normalized
                        onCommit(normalized)
                    }
            )
            .disabled(!isActive)
            .opacity(isActive ? 1.0 : 0.4)
        }
        .accessibilityLabel(String(localized: "Pitch adjustment slider"))
        .accessibilityAdjustableAction { direction in
            guard isActive else { return }
            let step = 0.1
            switch direction {
            case .increment:
                currentNormalizedValue = min(1.0, currentNormalizedValue + step)
            case .decrement:
                currentNormalizedValue = max(-1.0, currentNormalizedValue - step)
            @unknown default:
                break
            }
            onNormalizedValueChange(currentNormalizedValue)
        }
        .accessibilityAction(named: String(localized: "Submit pitch")) {
            guard isActive else { return }
            onCommit(currentNormalizedValue)
        }
        .onChange(of: isActive) { oldValue, newValue in
            if !oldValue && newValue {
                // Reset thumb to center when becoming active (new challenge)
                currentNormalizedValue = 0
            }
        }
    }

    // MARK: - Static Calculation Methods (testable)

    /// Maps a vertical drag position to a normalized value in -1.0...1.0.
    ///
    /// Top of track = +1.0 (sharper), center = 0, bottom = -1.0 (flatter).
    static func normalizedValue(dragY: CGFloat, trackHeight: CGFloat) -> Double {
        guard trackHeight > 0 else { return 0 }
        let fraction = dragY / trackHeight       // 0 (top) to 1 (bottom)
        let clamped = min(1.0, max(0.0, fraction))
        // Invert: top (0) = +1.0, bottom (1) = -1.0
        return 1.0 - 2.0 * clamped
    }

    /// Computes the Y position of the thumb for a given normalized value.
    ///
    /// Inverse of `normalizedValue(dragY:trackHeight:)`.
    static func thumbPosition(normalizedValue: Double, trackHeight: CGFloat) -> CGFloat {
        // normalizedValue = 1 - 2 * fraction  =>  fraction = (1 - normalizedValue) / 2
        let fraction = (1.0 - normalizedValue) / 2.0
        return trackHeight * CGFloat(fraction)
    }
}
