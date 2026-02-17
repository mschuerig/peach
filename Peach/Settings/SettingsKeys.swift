import Foundation

enum SettingsKeys {
    // MARK: - @AppStorage Key Names

    static let naturalVsMechanical = "naturalVsMechanical"
    static let noteRangeMin = "noteRangeMin"
    static let noteRangeMax = "noteRangeMax"
    static let noteDuration = "noteDuration"
    static let referencePitch = "referencePitch"
    static let soundSource = "soundSource"

    // MARK: - Default Values (matching TrainingSettings defaults)

    static let defaultNaturalVsMechanical: Double = 0.5
    static let defaultNoteRangeMin: Int = 36
    static let defaultNoteRangeMax: Int = 84
    static let defaultNoteDuration: Double = 1.0
    static let defaultReferencePitch: Double = 440.0
    static let defaultSoundSource: String = "sine"
}
