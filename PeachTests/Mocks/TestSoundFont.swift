import Foundation
@testable import Peach

enum TestSoundFont {
    static let url: URL = {
        guard let url = Bundle.main.url(forResource: "Samples", withExtension: "sf2") else {
            preconditionFailure("Samples.sf2 not found in app bundle — ensure it is in Copy Bundle Resources")
        }
        return url
    }()

    static func makeLibrary(defaultPreset: String = "sf2:0:0") -> SoundFontLibrary {
        SoundFontLibrary(sf2URL: url, defaultPreset: defaultPreset)
    }
}
