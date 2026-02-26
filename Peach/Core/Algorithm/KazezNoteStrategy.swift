import Foundation
import OSLog

/// Default training strategy using Kazez et al. (2001) difficulty formulas
///
/// The primary NextComparisonStrategy for production training. Maintains a single
/// continuous difficulty chain with random note selection, converging to the
/// user's threshold in ~10 correct answers via sqrt(P)-scaled formulas.
///
/// # Kazez Formulas
///
/// After correct answer: `N = P × [1 - (0.05 × √P)]`
/// After incorrect answer: `N = P × [1 + (0.09 × √P)]`
///
/// Where P = previous interval in cents, N = new interval in cents.
///
/// # Design
///
/// - **Global difficulty**: Single difficulty chain — no jumps when note changes
/// - **Random note selection**: Uniform random within settings noteRange (frequency roving)
/// - **Cold start**: Uses `profile.overallMean` if available, else `settings.maxCentDifference`
/// - **Stateless**: P comes from lastComparison.centDifference; no internal state
///
/// Rationale: pitch discrimination is one unified skill with roughly uniform thresholds
/// across the frequency range. Per-note difficulty tracking solves a problem that doesn't
/// exist. See `docs/brainstorming/brainstorming-session-2026-02-24.md`.
///
/// # Reference
///
/// Kazez, D., Kazez, B., Zembar, M.J., & Andrews, D. (2001).
/// *A Computer Program for Testing (and Improving?) Pitch Perception.*
/// College Music Society, 2001 National Conference.
final class KazezNoteStrategy: NextComparisonStrategy {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.peach.app", category: "KazezNoteStrategy")

    // MARK: - Initialization

    init() {
        logger.info("KazezNoteStrategy initialized")
    }

    // MARK: - NextComparisonStrategy Protocol

    func nextComparison(
        profile: PitchDiscriminationProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Comparison {
        let centDifference: Double

        let difficultyRange = settings.minCentDifference...settings.maxCentDifference

        if let last = lastComparison {
            let p = last.comparison.centDifference
            centDifference = last.isCorrect
                ? kazezNarrow(p: p).clamped(to: difficultyRange)
                : kazezWiden(p: p).clamped(to: difficultyRange)
        } else if let profileMean = profile.overallMean {
            centDifference = profileMean.clamped(to: difficultyRange)
        } else {
            centDifference = settings.maxCentDifference
        }

        let note = Int.random(in: settings.noteRangeMin...settings.noteRangeMax)

        logger.info("note=\(note), centDiff=\(centDifference, format: .fixed(precision: 1))")

        return Comparison(
            note1: note,
            note2: note,
            centDifference: centDifference,
            isSecondNoteHigher: Bool.random()
        )
    }

    // MARK: - Kazez Formulas

    /// After correct answer: N = P × [1 - (0.05 × √P)]
    private func kazezNarrow(p: Double) -> Double {
        p * (1.0 - 0.05 * p.squareRoot())
    }

    /// After incorrect answer: N = P × [1 + (0.09 × √P)]
    private func kazezWiden(p: Double) -> Double {
        p * (1.0 + 0.09 * p.squareRoot())
    }
}
