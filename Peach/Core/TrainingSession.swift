protocol TrainingSession: AnyObject {
    func start()
    func stop()
    var isIdle: Bool { get }
}
