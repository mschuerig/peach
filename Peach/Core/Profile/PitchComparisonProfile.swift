protocol PitchComparisonProfile: AnyObject {
    func updateComparison(note: MIDINote, centOffset: Cents, isCorrect: Bool)
    var comparisonMean: Cents? { get }
    var comparisonStdDev: Cents? { get }
}
