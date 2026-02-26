@testable import Peach
import Testing

@Suite("Comparable.clamped(to:)")
struct ComparableClampedTests {

    @Test("returns value when within range")
    func withinRange() async {
        #expect(5.clamped(to: 0...10) == 5)
        #expect(0.5.clamped(to: 0.0...1.0) == 0.5)
    }

    @Test("clamps to lower bound when below range")
    func belowRange() async {
        #expect((-5).clamped(to: 0...10) == 0)
        #expect((-0.1).clamped(to: 0.0...1.0) == 0.0)
    }

    @Test("clamps to upper bound when above range")
    func aboveRange() async {
        #expect(15.clamped(to: 0...10) == 10)
        #expect(1.5.clamped(to: 0.0...1.0) == 1.0)
    }

    @Test("returns bound when value equals bound")
    func atBounds() async {
        #expect(0.clamped(to: 0...10) == 0)
        #expect(10.clamped(to: 0...10) == 10)
    }

    @Test("works with negative ranges")
    func negativeRange() async {
        #expect(0.0.clamped(to: -90.0...12.0) == 0.0)
        #expect((-100.0).clamped(to: -90.0...12.0) == -90.0)
        #expect(20.0.clamped(to: -90.0...12.0) == 12.0)
    }

    @Test("works with Float type")
    func floatType() async {
        let value: Float = -100.0
        #expect(value.clamped(to: -90.0...12.0) == -90.0)
    }
}
