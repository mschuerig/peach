protocol TrainingSession: AnyObject {
    func start(intervals: Set<Interval>)
    func stop()
    var isIdle: Bool { get }
}
