import Testing
import Foundation
@testable import Peach

@Suite("SoundFontLibrary Tests")
struct SoundFontLibraryTests {

    // MARK: - Preset Discovery

    @Test("Discovers SF2 from bundle and enumerates presets")
    func discoversPresetsFromBundle() async {
        let library = SoundFontLibrary()
        #expect(!library.availablePresets.isEmpty)
    }

    @Test("Excludes drum kits (bank >= 120)")
    func noDrumKitsInAvailablePresets() async {
        let library = SoundFontLibrary()
        let drumPresets = library.availablePresets.filter { $0.bank >= 120 }
        #expect(drumPresets.isEmpty)
    }

    @Test("Excludes sound effects (program >= 120)")
    func noSoundEffectsInAvailablePresets() async {
        let library = SoundFontLibrary()
        let sfxPresets = library.availablePresets.filter { $0.program >= 120 }
        #expect(sfxPresets.isEmpty)
    }

    @Test("Presets sorted alphabetically by name")
    func presetsSortedAlphabetically() async {
        let library = SoundFontLibrary()
        let names = library.availablePresets.map(\.name)
        let sorted = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        #expect(names == sorted)
    }

    @Test("Contains Grand Piano at bank 0 program 0")
    func containsPiano() async {
        let library = SoundFontLibrary()
        let piano = library.availablePresets.first { $0.program == 0 && $0.bank == 0 }
        #expect(piano != nil)
        #expect(piano?.name == "Grand Piano")
    }

    @Test("Contains Cello at bank 0 program 42")
    func containsCello() async {
        let library = SoundFontLibrary()
        let cello = library.availablePresets.first { $0.program == 42 && $0.bank == 0 }
        #expect(cello != nil)
        #expect(cello?.name == "Cello")
    }

    @Test("Contains bank variants (e.g., bank 8 program 4)")
    func containsBankVariants() async {
        let library = SoundFontLibrary()
        let variant = library.availablePresets.first { $0.bank == 8 && $0.program == 4 }
        #expect(variant != nil)
        #expect(variant?.name == "Chorused Tine EP")
    }

    // MARK: - Tag Resolution

    @Test("preset(forTag: 'sf2:0:42') returns Cello preset")
    func resolvesCelloTag() async {
        let library = SoundFontLibrary()
        let preset = library.preset(forTag: "sf2:0:42")
        #expect(preset != nil)
        #expect(preset?.program == 42)
        #expect(preset?.name == "Cello")
    }

    @Test("preset(forTag: 'sf2:0:0') returns Grand Piano preset")
    func resolvesPianoTag() async {
        let library = SoundFontLibrary()
        let preset = library.preset(forTag: "sf2:0:0")
        #expect(preset != nil)
        #expect(preset?.program == 0)
    }

    @Test("preset(forTag: 'sf2:8:4') resolves bank variant")
    func resolvesBankVariantTag() async {
        let library = SoundFontLibrary()
        let preset = library.preset(forTag: "sf2:8:4")
        #expect(preset != nil)
        #expect(preset?.name == "Chorused Tine EP")
    }

    @Test("preset(forTag: 'sf2:0:999') returns nil for nonexistent program")
    func returnsNilForBadProgram() async {
        let library = SoundFontLibrary()
        let preset = library.preset(forTag: "sf2:0:999")
        #expect(preset == nil)
    }

    @Test("preset(forTag: 'sine') returns nil (not an SF2 tag)")
    func returnsNilForSineTag() async {
        let library = SoundFontLibrary()
        let preset = library.preset(forTag: "sine")
        #expect(preset == nil)
    }

    @Test("preset(forTag: 'sf2:abc') returns nil for invalid format")
    func returnsNilForInvalidTag() async {
        let library = SoundFontLibrary()
        let preset = library.preset(forTag: "sf2:abc")
        #expect(preset == nil)
    }

    // MARK: - No Duplicate Tags

    @Test("All preset tags are unique")
    func allTagsUnique() async {
        let library = SoundFontLibrary()
        let tags = library.availablePresets.map(\.tag)
        let uniqueTags = Set(tags)
        #expect(tags.count == uniqueTags.count)
    }
}
