import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct CatalogStoreTests {
    @Test func winesClosest_bestFirst_withTheirDetails() async throws {
        let container = try AppStore.makeInMemoryContainer()
        var fixture = ContentFixture()
        fixture.wines = [ContentFixture.wine("far", name: "Far", vintage: nil, acidity: 0),
                         ContentFixture.wine("near-2020", name: "Near", vintage: 2020, acidity: 9),
                         ContentFixture.wine("mid", name: "Mid", vintage: nil, acidity: 6)]
        _ = try await ContentImporter(modelContainer: container)
            .importIfNeeded(from: ContentSource(directory: try fixture.write()), currentVersion: nil)
        let user = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, $0 == .acidity ? 9 : 5) }))
        let wines = try await CatalogStore(modelContainer: container).winesClosest(to: user, limit: 2)
        #expect(wines.map(\.id) == ["near-2020", "mid"])
        #expect(wines.first?.vintage == 2020)
        #expect(wines.first?.serving == 14...16)
        #expect(wines.first?.producer == "Producer")
    }
}
