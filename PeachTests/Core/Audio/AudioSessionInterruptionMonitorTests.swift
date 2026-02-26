import Foundation
import Testing
import AVFoundation
import UIKit
@testable import Peach

@Suite("AudioSessionInterruptionMonitor")
struct AudioSessionInterruptionMonitorTests {

    // MARK: - Audio Interruption Tests

    @Test("Interruption began calls onStopRequired")
    func interruptionBeganCallsOnStopRequired() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            onStopRequired: { stopCalled = true }
        )

        nc.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(stopCalled)
        _ = _monitor
    }

    @Test("Interruption ended does not call onStopRequired")
    func interruptionEndedDoesNotCallOnStopRequired() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            onStopRequired: { stopCalled = true }
        )

        nc.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
        )

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(!stopCalled)
        _ = _monitor
    }

    @Test("Nil interruption type does not call onStopRequired")
    func nilInterruptionTypeDoesNotCallOnStopRequired() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            onStopRequired: { stopCalled = true }
        )

        nc.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: nil
        )

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(!stopCalled)
        _ = _monitor
    }

    // MARK: - Route Change Tests

    @Test("Route change oldDeviceUnavailable calls onStopRequired")
    func routeChangeOldDeviceUnavailableCallsOnStopRequired() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            onStopRequired: { stopCalled = true }
        )

        nc.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue]
        )

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(stopCalled)
        _ = _monitor
    }

    @Test("Non-stop route changes do not call onStopRequired")
    func nonStopRouteChangesDoNotCallOnStopRequired() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            onStopRequired: { stopCalled = true }
        )

        nc.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue]
        )

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(!stopCalled)
        _ = _monitor
    }

    @Test("Nil route change reason does not call onStopRequired")
    func nilRouteChangeReasonDoesNotCallOnStopRequired() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            onStopRequired: { stopCalled = true }
        )

        nc.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: nil
        )

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(!stopCalled)
        _ = _monitor
    }

    // MARK: - Background Notification Tests

    @Test("Background notification calls onStopRequired when observeBackgrounding is true")
    func backgroundNotificationCallsOnStopRequiredWhenEnabled() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            observeBackgrounding: true,
            onStopRequired: { stopCalled = true }
        )

        nc.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(stopCalled)
        _ = _monitor
    }

    @Test("Background notification does not call onStopRequired when observeBackgrounding is false")
    func backgroundNotificationDoesNotCallOnStopRequiredWhenDisabled() async throws {
        let nc = NotificationCenter()
        var stopCalled = false
        let _monitor = AudioSessionInterruptionMonitor(
            notificationCenter: nc,
            logger: .init(subsystem: "test", category: "test"),
            observeBackgrounding: false,
            onStopRequired: { stopCalled = true }
        )

        nc.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()
        #expect(!stopCalled)
        _ = _monitor
    }
}
