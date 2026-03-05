import Testing
@testable import Peach

@Suite("PitchComparisonProfile")
struct PitchComparisonProfileTests {

    @Test("PerceptualProfile conforms to PitchComparisonProfile")
    func conformsToPitchComparisonProfile() async {
        let profile = PerceptualProfile()
        let _: PitchComparisonProfile = profile
        #expect(profile is PitchComparisonProfile)
    }
}
