@testable import Peach

final class MockPitchMatchingProfile: PitchMatchingProfile {
    // MARK: - Test State

    var matchingMean: Cents? = nil
    var matchingStdDev: Cents? = nil
    var matchingSampleCount: Int = 0
}
