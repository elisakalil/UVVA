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

struct CatalogStoreCoursesTests {
    let store: CatalogStore

    init() async throws {
        let container = try AppStore.makeInMemoryContainer()
        var fixture = ContentFixture()
        var region = ContentFixture.module("region-pt-douro", lessons: 2)
        region["kind"] = "region"
        region["country"] = "Portugal"
        region["countryCode"] = "PT"
        region["grapes"] = ["Touriga Nacional"]
        fixture.modules = [ContentFixture.module("path-01", lessons: 3), region]
        _ = try await ContentImporter(modelContainer: container)
            .importIfNeeded(from: ContentSource(directory: try fixture.write()), currentVersion: nil)
        store = CatalogStore(modelContainer: container)
    }

    @Test func courses_ofATab_withTheirLessonsInOrder() async throws {
        let paths = try await store.courses(.path)
        #expect(paths.map(\.id) == ["path-01"])
        #expect(paths.first?.lessons.map(\.order) == [1, 2, 3])
        #expect(paths.first?.xp == 45)
        let region = try #require(try await store.course(id: "region-pt-douro"))
        #expect(region.kind == .region)
        #expect(region.countries == ["Portugal"])
        #expect(region.grapes == ["Touriga Nacional"])
    }

    @Test func lesson_decodesItsSteps() async throws {
        let lesson = try #require(try await store.lesson(id: "path-01-l02"))
        #expect(lesson.summary.title == "Lesson 2")
        #expect(lesson.steps == [.concept(title: "Grapes", body: "Fermented juice.", highlight: "Grapes"),
                                 .multipleChoice(prompt: "Which?", options: ["A", "B"], answer: 1, explanation: "B.")])
    }
}
