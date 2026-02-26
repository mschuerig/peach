import Foundation
import Testing
@testable import Peach

@Suite("VerticalPitchSlider")
struct VerticalPitchSliderTests {

    // MARK: - centOffset Tests

    @Test("center drag position yields zero cent offset")
    func centerDragYieldsZeroCentOffset() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 200, trackHeight: 400, centRange: 100)
        #expect(offset == 0)
    }

    @Test("top of track yields positive cent offset (sharper)")
    func topOfTrackYieldsPositiveCentOffset() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 0, trackHeight: 400, centRange: 100)
        #expect(offset == 100)
    }

    @Test("bottom of track yields negative cent offset (flatter)")
    func bottomOfTrackYieldsNegativeCentOffset() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 400, trackHeight: 400, centRange: 100)
        #expect(offset == -100)
    }

    @Test("quarter from top yields +50 cent offset")
    func quarterFromTopYieldsHalfPositiveCentOffset() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 100, trackHeight: 400, centRange: 100)
        #expect(offset == 50)
    }

    @Test("drag beyond top clamps to positive centRange")
    func dragBeyondTopClampsToPositiveCentRange() async {
        let offset = VerticalPitchSlider.centOffset(dragY: -50, trackHeight: 400, centRange: 100)
        #expect(offset == 100)
    }

    @Test("drag beyond bottom clamps to negative centRange")
    func dragBeyondBottomClampsToNegativeCentRange() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 450, trackHeight: 400, centRange: 100)
        #expect(offset == -100)
    }

    @Test("custom centRange of 50 scales correctly")
    func customCentRangeScalesCorrectly() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 0, trackHeight: 400, centRange: 50)
        #expect(offset == 50)
    }

    @Test("zero track height returns zero offset")
    func zeroTrackHeightReturnsZero() async {
        let offset = VerticalPitchSlider.centOffset(dragY: 100, trackHeight: 0, centRange: 100)
        #expect(offset == 0)
    }

    // MARK: - frequency Tests

    @Test("zero cent offset returns reference frequency unchanged")
    func zeroCentOffsetReturnsReferenceFrequency() async {
        let freq = VerticalPitchSlider.frequency(centOffset: 0, referenceFrequency: 440.0)
        #expect(abs(freq - 440.0) < 0.001)
    }

    @Test("+100 cents returns one semitone above reference")
    func positiveCentsReturnsHigherFrequency() async {
        let freq = VerticalPitchSlider.frequency(centOffset: 100, referenceFrequency: 440.0)
        let expected = 440.0 * pow(2.0, 100.0 / 1200.0)
        #expect(abs(freq - expected) < 0.001)
    }

    @Test("-100 cents returns one semitone below reference")
    func negativeCentsReturnsLowerFrequency() async {
        let freq = VerticalPitchSlider.frequency(centOffset: -100, referenceFrequency: 440.0)
        let expected = 440.0 * pow(2.0, -100.0 / 1200.0)
        #expect(abs(freq - expected) < 0.001)
    }

    @Test("+50 cents returns quarter-tone above reference")
    func fiftyPositiveCentsReturnsQuarterToneAbove() async {
        let freq = VerticalPitchSlider.frequency(centOffset: 50, referenceFrequency: 440.0)
        let expected = 440.0 * pow(2.0, 50.0 / 1200.0)
        #expect(abs(freq - expected) < 0.001)
    }

    @Test("different reference frequency computes correctly")
    func differentReferenceFrequencyComputesCorrectly() async {
        let freq = VerticalPitchSlider.frequency(centOffset: 0, referenceFrequency: 261.63)
        #expect(abs(freq - 261.63) < 0.001)
    }

    // MARK: - thumbPosition Tests

    @Test("zero cent offset places thumb at center")
    func zeroCentOffsetPlacesThumbAtCenter() async {
        let pos = VerticalPitchSlider.thumbPosition(centOffset: 0, trackHeight: 400, centRange: 100)
        #expect(abs(pos - 200) < 0.001)
    }

    @Test("+100 cent offset places thumb at top")
    func maxPositiveCentOffsetPlacesThumbAtTop() async {
        let pos = VerticalPitchSlider.thumbPosition(centOffset: 100, trackHeight: 400, centRange: 100)
        #expect(pos < 0.001)
    }

    @Test("-100 cent offset places thumb at bottom")
    func maxNegativeCentOffsetPlacesThumbAtBottom() async {
        let pos = VerticalPitchSlider.thumbPosition(centOffset: -100, trackHeight: 400, centRange: 100)
        #expect(abs(pos - 400) < 0.001)
    }

    @Test("+50 cent offset places thumb at quarter from top")
    func halfPositiveCentOffsetPlacesThumbAtQuarterFromTop() async {
        let pos = VerticalPitchSlider.thumbPosition(centOffset: 50, trackHeight: 400, centRange: 100)
        #expect(abs(pos - 100) < 0.001)
    }

    // MARK: - Round-trip consistency

    @Test("centOffset and thumbPosition are inverse operations")
    func centOffsetAndThumbPositionAreInverse() async {
        let trackHeight: CGFloat = 600
        let centRange: Double = 100
        let originalY: CGFloat = 150

        let cents = VerticalPitchSlider.centOffset(dragY: originalY, trackHeight: trackHeight, centRange: centRange)
        let recoveredY = VerticalPitchSlider.thumbPosition(centOffset: cents, trackHeight: trackHeight, centRange: centRange)

        #expect(abs(recoveredY - originalY) < 0.001)
    }
}
