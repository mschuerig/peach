import Testing
@testable import Peach

@Suite("Comparable clamped(to:)")
struct ComparableClampedTests {

    @Test("returns value when within range")
    func withinRange() async {
        #expect(5.clamped(to: 1...10) == 5)
        #expect(3.14.clamped(to: 0.0...10.0) == 3.14)
    }

    @Test("clamps to lower bound when below range")
    func belowRange() async {
        #expect((-5).clamped(to: 0...10) == 0)
        #expect((-100.0).clamped(to: -90.0...12.0) == -90.0)
    }

    @Test("clamps to upper bound when above range")
    func aboveRange() async {
        #expect(15.clamped(to: 0...10) == 10)
        #expect(20.0.clamped(to: -90.0...12.0) == 12.0)
    }

    @Test("returns bound when exactly at lower bound")
    func atLowerBound() async {
        #expect(0.clamped(to: 0...10) == 0)
    }

    @Test("returns bound when exactly at upper bound")
    func atUpperBound() async {
        #expect(10.clamped(to: 0...10) == 10)
    }

    @Test("works with single-value range")
    func singleValueRange() async {
        #expect(5.clamped(to: 3...3) == 3)
        #expect(1.clamped(to: 3...3) == 3)
    }
}
