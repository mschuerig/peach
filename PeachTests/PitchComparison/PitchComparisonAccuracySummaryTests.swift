import Testing
@testable import Peach

@Suite("Comparison Training Mode Tests")
struct ComparisonTrainingModeTests {

    @Test("trainingMode returns unisonComparison for prime intervals")
    func trainingModeUnison() async {
        let mode = PitchComparisonScreen.trainingMode(for: [.prime])
        #expect(mode == .unisonPitchComparison)
    }

    @Test("trainingMode returns intervalComparison for non-prime intervals")
    func trainingModeInterval() async {
        let mode = PitchComparisonScreen.trainingMode(for: [.up(.perfectFifth)])
        #expect(mode == .intervalPitchComparison)
    }
}
