import Foundation

struct SoundSourceID: Hashable, Sendable {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue.isEmpty ? "sf2:8:80" : rawValue
    }
}

// MARK: - SF2 Parsing

extension SoundSourceID {
    nonisolated var sf2Components: (bank: Int, program: Int)? {
        let tag = rawValue
        guard tag.hasPrefix("sf2:") else { return nil }
        let parts = tag.dropFirst(4).split(separator: ":")
        guard parts.count == 2,
              let bank = Int(parts[0]),
              let program = Int(parts[1]) else { return nil }
        return (bank: bank, program: program)
    }
}

// MARK: - ExpressibleByStringLiteral

extension SoundSourceID: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
}
