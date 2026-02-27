@testable import Peach

final class MockResettable: Resettable {
    private(set) var resetCallCount = 0

    func reset() {
        resetCallCount += 1
    }
}
