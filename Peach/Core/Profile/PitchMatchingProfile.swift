protocol PitchMatchingProfile: AnyObject {
    var matchingMean: Cents? { get }
    var matchingStdDev: Cents? { get }
    var matchingSampleCount: Int { get }
}
