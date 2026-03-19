import Foundation
@testable import Peach

final class MockPitchComparisonProfile: PitchComparisonProfile {
    // MARK: - Test State

    var stubbedComparisonMean: Cents? = nil

    // MARK: - PitchComparisonProfile Protocol

    func comparisonMean(for interval: DirectedInterval) -> Cents? {
        stubbedComparisonMean
    }
}
