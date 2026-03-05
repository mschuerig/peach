import Testing
import Foundation
@testable import Peach

@Suite("SettingsKeys")
struct SettingsKeysTests {

    private struct MockSoundSourceProvider: SoundSourceProvider {
        var availableSources: [SoundSourceID]
        func displayName(for source: SoundSourceID) -> String { source.rawValue }
    }

    private func makeDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "SettingsKeysTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }

    @Test("valid source is not changed")
    func validSourceUnchanged() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        defaults.set("sf2:8:80", forKey: SettingsKeys.soundSource)
        let provider = MockSoundSourceProvider(availableSources: [SoundSourceID("sf2:8:80")])

        SettingsKeys.validateSoundSource(against: provider, userDefaults: defaults)

        #expect(defaults.string(forKey: SettingsKeys.soundSource) == "sf2:8:80")
    }

    @Test("invalid source is reset to default")
    func invalidSourceReset() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        defaults.set("sf2:99:99", forKey: SettingsKeys.soundSource)
        let provider = MockSoundSourceProvider(availableSources: [SoundSourceID("sf2:8:80")])

        SettingsKeys.validateSoundSource(against: provider, userDefaults: defaults)

        #expect(defaults.string(forKey: SettingsKeys.soundSource) == SettingsKeys.defaultSoundSource)
    }

    @Test("missing key is set to default")
    func missingKeySetToDefault() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        let provider = MockSoundSourceProvider(availableSources: [SoundSourceID("sf2:8:80")])

        SettingsKeys.validateSoundSource(against: provider, userDefaults: defaults)

        #expect(defaults.string(forKey: SettingsKeys.soundSource) == SettingsKeys.defaultSoundSource)
    }
}
