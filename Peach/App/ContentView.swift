import SwiftUI
import os

struct ContentView: View {
    /// Active training session (if any) injected from app
    @Environment(\.activeSession) private var activeSession

    /// Scene phase for app lifecycle monitoring (Story 3.4)
    @Environment(\.scenePhase) private var scenePhase

    /// Navigation path for programmatic navigation control
    @State private var navigationPath: [NavigationDestination] = []

    /// Track previous scene phase to detect transitions
    @State private var previousScenePhase: ScenePhase?

    /// Logger for lifecycle events
    private let logger = Logger(subsystem: "com.peach.app", category: "ContentView")

    var body: some View {
        NavigationStack(path: $navigationPath) {
            StartScreen()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            logger.debug("Scene phase changed: \(String(describing: oldPhase)) → \(String(describing: newPhase))")

            // Handle app backgrounding
            if newPhase == .background {
                handleAppBackgrounding()
            }

            // Handle app foregrounding
            if oldPhase == .background && newPhase == .active {
                handleAppForegrounding()
            }

            previousScenePhase = newPhase
        }
    }

    /// Handles app entering background state
    private func handleAppBackgrounding() {
        logger.info("App backgrounded - stopping training if active")
        activeSession?.stop()
    }

    /// Handles app returning to foreground from background
    private func handleAppForegrounding() {
        logger.info("App foregrounded after being backgrounded")

        // Pop navigation to Start Screen (AC#3)
        // This ensures users return to a known, clean state
        if !navigationPath.isEmpty {
            logger.info("Clearing navigation path (was: \(navigationPath)) - returning to Start Screen")
            navigationPath.removeAll()
        } else {
            logger.info("Navigation path already empty - user on Start Screen")
        }
    }
}

#Preview {
    ContentView()
}
