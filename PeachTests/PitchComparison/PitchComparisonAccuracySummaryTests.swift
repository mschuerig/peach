import Testing
@testable import Peach

@Suite("Comparison Training Discipline Tests")
struct ComparisonTrainingDisciplineTests {

    @Test("trainingDiscipline returns unisonComparison for prime intervals")
    func trainingDisciplineUnison() async {
        let mode = PitchComparisonScreen.trainingDiscipline(for: [.prime])
        #expect(mode == .unisonPitchDiscrimination)
    }

    @Test("trainingDiscipline returns intervalComparison for non-prime intervals")
    func trainingDisciplineInterval() async {
        let mode = PitchComparisonScreen.trainingDiscipline(for: [.up(.perfectFifth)])
        #expect(mode == .intervalPitchDiscrimination)
    }
}
