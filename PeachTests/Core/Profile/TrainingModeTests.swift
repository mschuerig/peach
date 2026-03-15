import Testing
@testable import Peach

@Suite("TrainingMode Tests")
struct TrainingModeTests {

    // MARK: - Slug

    @Test("slug returns pitch-comparison for unison pitch comparison")
    func slugUnisonPitchComparison() async {
        #expect(TrainingMode.unisonPitchComparison.slug == "pitch-comparison")
    }

    @Test("slug returns interval-comparison for interval pitch comparison")
    func slugIntervalPitchComparison() async {
        #expect(TrainingMode.intervalPitchComparison.slug == "interval-comparison")
    }

    @Test("slug returns pitch-matching for unison matching")
    func slugUnisonMatching() async {
        #expect(TrainingMode.unisonMatching.slug == "pitch-matching")
    }

    @Test("slug returns interval-matching for interval matching")
    func slugIntervalMatching() async {
        #expect(TrainingMode.intervalMatching.slug == "interval-matching")
    }
}
