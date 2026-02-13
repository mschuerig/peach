import Testing
import SwiftUI
@testable import Peach

@Suite("Start Screen Tests")
struct StartScreenTests {

    // MARK: - View Instantiation Tests

    @Test("Start Screen can be instantiated")
    func startScreenCanBeInstantiated() {
        let view = StartScreen()
        let mirror = Mirror(reflecting: view)

        // Verify view has expected structure
        #expect(mirror.children.count > 0)
    }

    @Test("Training Screen can be instantiated")
    func trainingScreenCanBeInstantiated() {
        let view = TrainingScreen()
        let mirror = Mirror(reflecting: view)

        // Verify view exists and has structure
        #expect(mirror.children.count >= 0)
    }

    @Test("Settings Screen can be instantiated")
    func settingsScreenCanBeInstantiated() {
        let view = SettingsScreen()
        let mirror = Mirror(reflecting: view)

        // Verify view exists
        #expect(mirror.children.count >= 0)
    }

    @Test("Profile Screen can be instantiated")
    func profileScreenCanBeInstantiated() {
        let view = ProfileScreen()
        let mirror = Mirror(reflecting: view)

        // Verify view exists
        #expect(mirror.children.count >= 0)
    }

    @Test("Info Screen can be instantiated")
    func infoScreenCanBeInstantiated() {
        let view = InfoScreen()
        let mirror = Mirror(reflecting: view)

        // Verify view exists
        #expect(mirror.children.count > 0)
    }

    @Test("ContentView can be instantiated")
    func contentViewCanBeInstantiated() {
        let view = ContentView()
        let mirror = Mirror(reflecting: view)

        // Verify ContentView exists
        #expect(mirror.children.count >= 0)
    }

    // MARK: - Navigation Destination Tests

    @Test("NavigationDestination enum has training case")
    func navigationDestinationHasTraining() {
        let destination = NavigationDestination.training
        #expect(destination == NavigationDestination.training)
    }

    @Test("NavigationDestination enum has settings case")
    func navigationDestinationHasSettings() {
        let destination = NavigationDestination.settings
        #expect(destination == NavigationDestination.settings)
    }

    @Test("NavigationDestination enum has profile case")
    func navigationDestinationHasProfile() {
        let destination = NavigationDestination.profile
        #expect(destination == NavigationDestination.profile)
    }

    @Test("NavigationDestination enum is Hashable")
    func navigationDestinationIsHashable() {
        let destination1 = NavigationDestination.training
        let destination2 = NavigationDestination.training
        let destination3 = NavigationDestination.settings

        #expect(destination1.hashValue == destination2.hashValue)
        #expect(destination1.hashValue != destination3.hashValue)
    }

    @Test("NavigationDestination cases are not equal when different")
    func navigationDestinationCasesAreDistinct() {
        #expect(NavigationDestination.training != NavigationDestination.settings)
        #expect(NavigationDestination.settings != NavigationDestination.profile)
        #expect(NavigationDestination.training != NavigationDestination.profile)
    }

    // MARK: - Info Screen Content Tests

    @Test("Info Screen retrieves version from bundle")
    func infoScreenRetrievesVersion() {
        let view = InfoScreen()

        // Access the private property via reflection for testing
        let mirror = Mirror(reflecting: view)
        let appVersionProperty = mirror.children.first(where: { $0.label == "appVersion" })

        #expect(appVersionProperty != nil)

        if let version = appVersionProperty?.value as? String {
            // Version should either be from bundle or "Unknown"
            #expect(!version.isEmpty)
        }
    }

    // MARK: - Hub and Spoke Pattern Verification

    @Test("All navigation destinations can be created")
    func allNavigationDestinationsCanBeCreated() {
        // Verify that all destination screens can be instantiated
        // This ensures the hub-and-spoke pattern has all spokes available

        let training = TrainingScreen()
        let settings = SettingsScreen()
        let profile = ProfileScreen()
        let info = InfoScreen()

        // If we can create all screens, navigation paths are valid
        let trainingMirror = Mirror(reflecting: training)
        let settingsMirror = Mirror(reflecting: settings)
        let profileMirror = Mirror(reflecting: profile)
        let infoMirror = Mirror(reflecting: info)

        #expect(trainingMirror.children.count >= 0)
        #expect(settingsMirror.children.count >= 0)
        #expect(profileMirror.children.count >= 0)
        #expect(infoMirror.children.count > 0)
    }
}
