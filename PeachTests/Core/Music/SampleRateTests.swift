import Testing
@testable import Peach

@Suite("SampleRate Tests")
struct SampleRateTests {

    // MARK: - Valid Construction

    @Test("Stores positive value")
    func positiveValue() async {
        let rate = SampleRate(44100.0)
        #expect(rate.rawValue == 44100.0)
    }

    @Test("Stores small positive value")
    func smallPositiveValue() async {
        let rate = SampleRate(8000.0)
        #expect(rate.rawValue == 8000.0)
    }

    // MARK: - Static Factories

    @Test("standard44100 is 44100 Hz")
    func standard44100() async {
        #expect(SampleRate.standard44100.rawValue == 44100.0)
    }

    @Test("standard48000 is 48000 Hz")
    func standard48000() async {
        #expect(SampleRate.standard48000.rawValue == 48000.0)
    }

    // MARK: - ExpressibleByFloatLiteral

    @Test("Float literal creates SampleRate")
    func floatLiteral() async {
        let rate: SampleRate = 44100.0
        #expect(rate.rawValue == 44100.0)
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal creates SampleRate")
    func integerLiteral() async {
        let rate: SampleRate = 44100
        #expect(rate.rawValue == 44100.0)
    }

    // MARK: - Comparable

    @Test("Lower sample rate is less than higher")
    func comparable() async {
        #expect(SampleRate(22050.0) < SampleRate(44100.0))
        #expect(SampleRate(44100.0) == SampleRate(44100.0))
        #expect(SampleRate(96000.0) > SampleRate(44100.0))
    }

    // MARK: - Hashable

    @Test("Equal sample rates have same hash")
    func hashable() async {
        let set: Set<SampleRate> = [SampleRate(44100.0), SampleRate(44100.0), SampleRate(48000.0)]
        #expect(set.count == 2)
    }
}
