import Foundation
@testable import Peach

/// Mock NextNoteStrategy for deterministic testing of TrainingSession
///
/// Returns predetermined comparisons in sequence, and captures received
/// profile and settings for assertion in tests.
@MainActor
final class MockNextNoteStrategy: NextNoteStrategy {
    // MARK: - Test State Tracking

    /// Predetermined comparisons to return (cycles through the list)
    var comparisons: [Comparison]

    /// Current index in comparisons array
    var currentIndex = 0

    /// Number of times nextComparison() was called
    var callCount = 0

    /// Last profile received by nextComparison()
    var lastReceivedProfile: PerceptualProfile?

    /// Last settings received by nextComparison()
    var lastReceivedSettings: TrainingSettings?

    /// Last completed comparison received
    var lastReceivedLastComparison: CompletedComparison?

    // MARK: - Initialization

    /// Creates a mock strategy with predetermined comparisons
    ///
    /// - Parameter comparisons: Comparisons to return in sequence (defaults to a single 100-cent comparison at middle C)
    init(comparisons: [Comparison] = [
        Comparison(note1: 60, note2: 60, centDifference: 100.0, isSecondNoteHigher: true)
    ]) {
        self.comparisons = comparisons
    }

    // MARK: - NextNoteStrategy Protocol

    func nextComparison(
        profile: PerceptualProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Comparison {
        callCount += 1
        lastReceivedProfile = profile
        lastReceivedSettings = settings
        lastReceivedLastComparison = lastComparison

        let comparison = comparisons[currentIndex % comparisons.count]
        currentIndex += 1
        return comparison
    }

    // MARK: - Test Helpers

    func reset() {
        currentIndex = 0
        callCount = 0
        lastReceivedProfile = nil
        lastReceivedSettings = nil
        lastReceivedLastComparison = nil
    }
}
