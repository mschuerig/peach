import Testing
@testable import Peach

@Suite("PitchMatchingScreen")
struct PitchMatchingScreenTests {

    // MARK: - feedbackAnimation

    @Test("feedbackAnimation returns nil when Reduce Motion is enabled")
    func feedbackAnimationReturnsNilForReduceMotion() async {
        #expect(PitchMatchingScreen.feedbackAnimation(reduceMotion: true) == nil)
    }

    @Test("feedbackAnimation returns animation when Reduce Motion is disabled")
    func feedbackAnimationReturnsAnimationNormally() async {
        #expect(PitchMatchingScreen.feedbackAnimation(reduceMotion: false) != nil)
    }
}
