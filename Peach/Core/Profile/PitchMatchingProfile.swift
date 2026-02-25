protocol PitchMatchingProfile: AnyObject {
    func updateMatching(note: Int, centError: Double)
    var matchingMean: Double? { get }
    var matchingStdDev: Double? { get }
    var matchingSampleCount: Int { get }
    func resetMatching()
}
