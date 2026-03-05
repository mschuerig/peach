import Testing
@testable import Peach

@Suite("Pitch Matching Training Mode Tests")
struct PitchMatchingTrainingModeTests {

    @Test("trainingMode returns unisonMatching for prime intervals")
    func trainingModeUnison() async {
        let mode = PitchMatchingScreen.trainingMode(for: [.prime])
        #expect(mode == .unisonMatching)
    }

    @Test("trainingMode returns intervalMatching for non-prime intervals")
    func trainingModeInterval() async {
        let mode = PitchMatchingScreen.trainingMode(for: [.up(.perfectFifth)])
        #expect(mode == .intervalMatching)
    }
}
