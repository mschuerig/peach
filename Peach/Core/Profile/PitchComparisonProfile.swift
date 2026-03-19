protocol PitchComparisonProfile: AnyObject {
    func comparisonMean(for interval: DirectedInterval) -> Cents?
}
