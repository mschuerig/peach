protocol TrainingSession: AnyObject {
    func start(intervals: Set<DirectedInterval>)
    func stop()
    var isIdle: Bool { get }
}
