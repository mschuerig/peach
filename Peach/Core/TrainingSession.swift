import SwiftUI

protocol TrainingSession: AnyObject {
    func stop()
    var isIdle: Bool { get }
}

extension EnvironmentValues {
    @Entry var activeSession: (any TrainingSession)? = nil
}
