import Testing
@testable import Peach

@Suite("TrainingStatsView Tests")
struct TrainingStatsViewTests {

    // MARK: - Formatting

    @Test("Cents.formatted() uses locale-aware decimal separator")
    func formattedCentsLocaleAware() async {
        let result = Cents(8.2).formatted()
        // Result should be "8.2" or "8,2" depending on locale
        #expect(result == "8.2" || result == "8,2")
    }

    @Test("Cents.formatted() rounds to one decimal place")
    func formattedCentsRounding() async {
        let result = Cents(4.27).formatted()
        // Should be "4.3" or "4,3"
        #expect(result == "4.3" || result == "4,3")
    }

    @Test("Cents.formatted() handles zero")
    func formattedCentsZero() async {
        let result = Cents(0.0).formatted()
        #expect(result == "0.0" || result == "0,0")
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
