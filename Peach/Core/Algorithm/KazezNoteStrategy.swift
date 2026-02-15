import Foundation
import OSLog

/// Evaluation strategy using Kazez et al. (2001) difficulty formulas
///
/// A simplified, stateless NextNoteStrategy for validating difficulty
/// convergence behavior. Uses sqrt(P)-scaled formulas that converge
/// to the user's threshold in ~10 correct answers (vs. ~60 with fixed factors).
///
/// # Kazez Formulas
///
/// After correct answer: `N = P × [1 - (0.05 × √P)]`
/// After incorrect answer: `N = P × [1 + (0.09 × √P)]`
///
/// Where P = previous interval in cents, N = new interval in cents.
///
/// # Simplifications (evaluation only)
///
/// - **Global difficulty**: Single difficulty derived from lastComparison, not per-note
/// - **Random note selection**: Uniform random within C3–C5 (MIDI 48–72)
/// - **Stateless**: P comes from lastComparison.centDifference; no internal state
/// - **PerceptualProfile ignored**: Passed by protocol but unused for difficulty
///
/// # Reference
///
/// Kazez, D., Kazez, B., Zembar, M.J., & Andrews, D. (2001).
/// *A Computer Program for Testing (and Improving?) Pitch Perception.*
/// College Music Society, 2001 National Conference.
@MainActor
final class KazezNoteStrategy: NextNoteStrategy {

    // MARK: - Constants

    /// Note range: C3 to C5
    private static let noteRangeMin = 48
    private static let noteRangeMax = 72

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.peach.app", category: "KazezNoteStrategy")

    // MARK: - Initialization

    init() {
        logger.info("KazezNoteStrategy initialized (evaluation mode)")
    }

    // MARK: - NextNoteStrategy Protocol

    func nextComparison(
        profile: PerceptualProfile,
        settings: TrainingSettings,
        lastComparison: CompletedComparison?
    ) -> Comparison {
        let centDifference: Double

        if let last = lastComparison {
            let p = last.comparison.centDifference
            centDifference = last.isCorrect
                ? kazezNarrow(p: p, min: settings.minCentDifference)
                : kazezWiden(p: p, max: settings.maxCentDifference)
        } else {
            centDifference = settings.maxCentDifference
        }

        let note = Int.random(in: Self.noteRangeMin...Self.noteRangeMax)

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
    private func kazezNarrow(p: Double, min: Double) -> Double {
        let n = p * (1.0 - 0.05 * p.squareRoot())
        return max(n, min)
    }

    /// After incorrect answer: N = P × [1 + (0.09 × √P)]
    private func kazezWiden(p: Double, max: Double) -> Double {
        let n = p * (1.0 + 0.09 * p.squareRoot())
        return min(n, max)
    }
}
