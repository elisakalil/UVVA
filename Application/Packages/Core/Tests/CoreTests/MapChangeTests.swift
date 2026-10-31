import Foundation
import Testing
@testable import Core

struct MapChangeTests {
    @Test func mapChange_roundTripsThroughJSON_withAxesAsKeys() throws {
        let change = MapChange(date: Date(timeIntervalSince1970: 0), cause: .rating(wineKey: "w", verdict: .yes),
                               values: [.acidity: 6.4])
        let data = try JSONEncoder().encode(change)
        #expect(String(decoding: data, as: UTF8.self).contains("\"acidity\":6.4"))
        #expect(try JSONDecoder().decode(MapChange.self, from: data) == change)
    }
}
