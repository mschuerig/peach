import Testing
@testable import Peach

@Suite("Resettable Protocol Tests")
struct ResettableTests {

    @Test("Resettable protocol can be used as a type-erased collection element")
    func resettableCanBeStoredInArray() async {
        let mock = MockResettable()
        let resettables: [Resettable] = [mock]
        resettables.forEach { $0.reset() }
        #expect(mock.resetCallCount == 1)
    }

    @Test("Multiple resettables are all reset when iterating")
    func multipleResettablesAllReset() async {
        let mock1 = MockResettable()
        let mock2 = MockResettable()
        let resettables: [Resettable] = [mock1, mock2]
        resettables.forEach { $0.reset() }
        #expect(mock1.resetCallCount == 1)
        #expect(mock2.resetCallCount == 1)
    }

    @Test("TrendAnalyzer conforms to Resettable")
    func trendAnalyzerConformsToResettable() async {
        let analyzer = TrendAnalyzer()
        let resettable: Resettable = analyzer
        resettable.reset()
        #expect(analyzer.trend == nil)
    }

    @Test("ThresholdTimeline conforms to Resettable")
    func thresholdTimelineConformsToResettable() async {
        let timeline = ThresholdTimeline()
        let resettable: Resettable = timeline
        resettable.reset()
        #expect(timeline.dataPoints.isEmpty)
    }

    @Test("ComparisonSession.resetTrainingData calls reset on all resettables")
    func resetTrainingDataCallsAllResettables() async {
        let mock1 = MockResettable()
        let mock2 = MockResettable()
        let session = ComparisonSession(
            notePlayer: MockNotePlayer(),
            strategy: MockNextComparisonStrategy(),
            profile: PerceptualProfile(),
            userSettings: MockUserSettings(),
            resettables: [mock1, mock2]
        )

        session.resetTrainingData()

        #expect(mock1.resetCallCount == 1)
        #expect(mock2.resetCallCount == 1)
    }
}
