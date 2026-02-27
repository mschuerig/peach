import Foundation
import Testing
@testable import Peach

@Suite("VerticalPitchSlider")
struct VerticalPitchSliderTests {

    // MARK: - normalizedValue Tests

    @Test("center drag position yields zero normalized value")
    func centerDragYieldsZeroNormalizedValue() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: 200, trackHeight: 400)
        #expect(value == 0)
    }

    @Test("top of track yields +1.0 (sharper)")
    func topOfTrackYieldsPositiveOne() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: 0, trackHeight: 400)
        #expect(value == 1.0)
    }

    @Test("bottom of track yields -1.0 (flatter)")
    func bottomOfTrackYieldsNegativeOne() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: 400, trackHeight: 400)
        #expect(value == -1.0)
    }

    @Test("quarter from top yields +0.5")
    func quarterFromTopYieldsHalf() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: 100, trackHeight: 400)
        #expect(value == 0.5)
    }

    @Test("drag beyond top clamps to +1.0")
    func dragBeyondTopClampsToPositiveOne() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: -50, trackHeight: 400)
        #expect(value == 1.0)
    }

    @Test("drag beyond bottom clamps to -1.0")
    func dragBeyondBottomClampsToNegativeOne() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: 450, trackHeight: 400)
        #expect(value == -1.0)
    }

    @Test("zero track height returns zero")
    func zeroTrackHeightReturnsZero() async {
        let value = VerticalPitchSlider.normalizedValue(dragY: 100, trackHeight: 0)
        #expect(value == 0)
    }

    // MARK: - thumbPosition Tests

    @Test("zero normalized value places thumb at center")
    func zeroNormalizedValuePlacesThumbAtCenter() async {
        let pos = VerticalPitchSlider.thumbPosition(normalizedValue: 0, trackHeight: 400)
        #expect(abs(pos - 200) < 0.001)
    }

    @Test("+1.0 normalized value places thumb at top")
    func positiveOneNormalizedValuePlacesThumbAtTop() async {
        let pos = VerticalPitchSlider.thumbPosition(normalizedValue: 1.0, trackHeight: 400)
        #expect(pos < 0.001)
    }

    @Test("-1.0 normalized value places thumb at bottom")
    func negativeOneNormalizedValuePlacesThumbAtBottom() async {
        let pos = VerticalPitchSlider.thumbPosition(normalizedValue: -1.0, trackHeight: 400)
        #expect(abs(pos - 400) < 0.001)
    }

    @Test("+0.5 normalized value places thumb at quarter from top")
    func halfNormalizedValuePlacesThumbAtQuarterFromTop() async {
        let pos = VerticalPitchSlider.thumbPosition(normalizedValue: 0.5, trackHeight: 400)
        #expect(abs(pos - 100) < 0.001)
    }

    // MARK: - Round-trip consistency

    @Test("normalizedValue and thumbPosition are inverse operations")
    func normalizedValueAndThumbPositionAreInverse() async {
        let trackHeight: CGFloat = 600
        let originalY: CGFloat = 150

        let normalized = VerticalPitchSlider.normalizedValue(dragY: originalY, trackHeight: trackHeight)
        let recoveredY = VerticalPitchSlider.thumbPosition(normalizedValue: normalized, trackHeight: trackHeight)

        #expect(abs(recoveredY - originalY) < 0.001)
    }
}
