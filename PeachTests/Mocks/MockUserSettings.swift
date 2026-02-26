import Foundation
@testable import Peach

final class MockUserSettings: UserSettings {
    var noteRangeMin: MIDINote = MIDINote(SettingsKeys.defaultNoteRangeMin)
    var noteRangeMax: MIDINote = MIDINote(SettingsKeys.defaultNoteRangeMax)
    var noteDuration: TimeInterval = SettingsKeys.defaultNoteDuration
    var referencePitch: Double = SettingsKeys.defaultReferencePitch
    var soundSource: String = SettingsKeys.defaultSoundSource
    var varyLoudness: Double = SettingsKeys.defaultVaryLoudness
    var naturalVsMechanical: Double = SettingsKeys.defaultNaturalVsMechanical
}
