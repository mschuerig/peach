import Testing
import SwiftUI
@testable import Peach

/// Tests for SummaryStatisticsView display logic
@Suite("SummaryStatistics Tests")
@MainActor
struct SummaryStatisticsTests {

    // MARK: - Task 1: Mean and StdDev computation

    @Test("Mean uses absolute per-note means to avoid signed cancellation")
    func meanUsesAbsoluteValues() async throws {
        let profile = PerceptualProfile()
        // Note with positive mean
        profile.update(note: 60, centOffset: 40, isCorrect: true)
        // Note with negative mean (would cancel out if signed)
        profile.update(note: 62, centOffset: -30, isCorrect: true)

        let stats = SummaryStatisticsView.computeStats(from: profile, midiRange: 36...84)

        // Should be (abs(40) + abs(-30)) / 2 = 35, NOT (40 + -30) / 2 = 5
        #expect(stats != nil)
        #expect(stats!.mean == 35.0)
    }

    @Test("StdDev computed from absolute per-note means")
    func stdDevFromAbsoluteMeans() async throws {
        let profile = PerceptualProfile()
        // Three notes with different absolute means
        profile.update(note: 60, centOffset: 20, isCorrect: true)
        profile.update(note: 62, centOffset: 40, isCorrect: true)
        profile.update(note: 64, centOffset: 60, isCorrect: true)

        let stats = SummaryStatisticsView.computeStats(from: profile, midiRange: 36...84)

        #expect(stats != nil)
        // abs means: [20, 40, 60], mean of abs = 40
        // Variance = ((20-40)^2 + (40-40)^2 + (60-40)^2) / (3-1) = (400+0+400)/2 = 400
        // stdDev = sqrt(400) = 20
        #expect(stats!.mean == 40.0)
        #expect(stats!.stdDev == 20.0)
    }

    @Test("Cold start returns nil stats when no training data")
    func coldStartReturnsNil() async throws {
        let profile = PerceptualProfile()

        let stats = SummaryStatisticsView.computeStats(from: profile, midiRange: 36...84)

        #expect(stats == nil)
    }

    @Test("Single trained note returns mean but no stdDev")
    func singleNoteNoStdDev() async throws {
        let profile = PerceptualProfile()
        profile.update(note: 60, centOffset: 50, isCorrect: true)

        let stats = SummaryStatisticsView.computeStats(from: profile, midiRange: 36...84)

        #expect(stats != nil)
        #expect(stats!.mean == 50.0)
        #expect(stats!.stdDev == nil)
    }

    // MARK: - Formatting

    @Test("Mean formatted as integer cent value")
    func meanFormatted() async throws {
        #expect(SummaryStatisticsView.formatMean(32.7) == "33 cents")
        #expect(SummaryStatisticsView.formatMean(1.2) == "1 cents")
    }

    @Test("StdDev formatted with plus-minus prefix")
    func stdDevFormatted() async throws {
        #expect(SummaryStatisticsView.formatStdDev(14.3) == "±14 cents")
    }

    @Test("Cold start displays dashes")
    func coldStartDisplaysDashes() async throws {
        #expect(SummaryStatisticsView.formatMean(nil) == "—")
        #expect(SummaryStatisticsView.formatStdDev(nil) == "—")
    }
}
