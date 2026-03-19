import Foundation
import Testing
@testable import Peach

@Suite("RhythmDirection")
struct RhythmDirectionTests {

    // MARK: - Codable

    @Test("Round-trip encode and decode preserves early case")
    func codableEarly() async throws {
        let original = RhythmDirection.early
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RhythmDirection.self, from: data)
        #expect(decoded == original)
    }

    @Test("Round-trip encode and decode preserves late case")
    func codableLate() async throws {
        let original = RhythmDirection.late
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RhythmDirection.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Hashable

    @Test("Set deduplicates equal values")
    func hashable() async {
        let set: Set<RhythmDirection> = [.early, .early, .late, .late]
        #expect(set.count == 2)
    }
}
