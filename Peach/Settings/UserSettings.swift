import Foundation

protocol UserSettings {
    var noteRangeMin: MIDINote { get }
    var noteRangeMax: MIDINote { get }
    var noteDuration: TimeInterval { get }
    var referencePitch: Double { get }
    var soundSource: String { get }
    var varyLoudness: Double { get }
    var naturalVsMechanical: Double { get }
}
