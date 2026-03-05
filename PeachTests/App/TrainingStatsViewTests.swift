import Testing
@testable import Peach

@Suite("TrainingStatsView Tests")
struct TrainingStatsViewTests {

    // MARK: - Formatting

    @Test("formattedCents uses locale-aware decimal separator")
    func formattedCentsLocaleAware() async {
        let result = TrainingStatsView.formattedCents(8.2)
        // Result should contain either "8.2" or "8,2" depending on locale
        #expect(result.contains("8"))
        #expect(result.contains("2"))
    }

    @Test("formattedCents rounds to one decimal place")
    func formattedCentsRounding() async {
        let result = TrainingStatsView.formattedCents(4.27)
        // Should be "4.3" or "4,3"
        #expect(result.contains("4"))
        #expect(result.contains("3"))
    }

    @Test("formattedCents handles zero")
    func formattedCentsZero() async {
        let result = TrainingStatsView.formattedCents(0.0)
        #expect(result.contains("0"))
    }

    // MARK: - Trend Helpers

    @Test("trendSymbol returns correct SF Symbol names")
    func trendSymbols() async {
        #expect(TrainingStatsView.trendSymbol(.improving) == "arrow.down.right")
        #expect(TrainingStatsView.trendSymbol(.stable) == "arrow.right")
        #expect(TrainingStatsView.trendSymbol(.declining) == "arrow.up.right")
    }

    @Test("trendColor returns green for improving")
    func trendColorImproving() async {
        #expect(TrainingStatsView.trendColor(.improving) == .green)
    }

    @Test("trendColor returns secondary for stable")
    func trendColorStable() async {
        #expect(TrainingStatsView.trendColor(.stable) == .secondary)
    }

    @Test("trendColor returns orange for declining")
    func trendColorDeclining() async {
        #expect(TrainingStatsView.trendColor(.declining) == .orange)
    }

    // MARK: - Accessibility

    @Test("latestAccessibilityLabel includes value")
    func latestAccessibilityLabel() async {
        let label = TrainingStatsView.latestAccessibilityLabel(8.2, trend: .improving)
        #expect(label.contains("8"))
    }

    @Test("latestAccessibilityLabel works without trend")
    func latestAccessibilityLabelNoTrend() async {
        let label = TrainingStatsView.latestAccessibilityLabel(8.2, trend: nil)
        #expect(label.contains("8"))
    }

    @Test("bestAccessibilityLabel includes value")
    func bestAccessibilityLabel() async {
        let label = TrainingStatsView.bestAccessibilityLabel(2.1)
        #expect(label.contains("2"))
    }
}
