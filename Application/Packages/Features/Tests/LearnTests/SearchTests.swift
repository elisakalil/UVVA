import Core
import Foundation
import Testing
@testable import Learn

@MainActor
struct SearchTests {
    func viewModel() async -> LearnViewModel {
        var douro = Fixture.course("region-pt-douro", kind: .region, countries: ["Portugal"])
        douro.title = "Douro"
        douro.grapes = ["Touriga Nacional"]
        douro.lessons[0].title = "Port, method by method"
        var dao = Fixture.course("region-pt-dao", kind: .region, order: 2, countries: ["Portugal"])
        dao.title = "Dão"
        var touriga = Fixture.course("grape-touriga-nacional", countries: ["Portugal"])
        touriga.title = "Touriga Nacional"
        var tasting = Fixture.course("path-tasting", kind: .path, level: "Essentials")
        tasting.title = "How to taste"
        let courses = [douro, dao, touriga, tasting]
        let lessons = courses.reduce(into: [String: Lesson]()) { $0.merge(Fixture.lessons(of: $1)) { a, _ in a } }
        let model = LearnFactory(catalog: CatalogStub(all: courses, lessons: lessons), learning: LearningSpy(),
                                   profiles: ProfilesStub(), now: { Fixture.day }, pickToast: { _ in 0 }).makeViewModel()
        await model.load()
        return model
    }

    @Test func blankQuery_isNotSearching() async {
        let model = await viewModel()
        model.query = "   "
        #expect(!model.isSearching)
        #expect(model.searchResults.isEmpty)
    }

    @Test func ignoresAccentsAndCase() async {
        let model = await viewModel()
        model.query = "DAO"
        #expect(model.searchResults.first?.results.map(\.title) == ["Dão"])
    }

    /// A grape finds itself first, then the regions that grow it.
    @Test func aGrape_findsTheGrape_andItsRegions() async {
        let model = await viewModel()
        model.query = "touriga"
        #expect(model.searchResults.map(\.id) == ["region", "grape"])
        #expect(model.searchResults[0].results.map(\.title) == ["Douro"])
        #expect(model.searchResults[1].results.map(\.title) == ["Touriga Nacional"])
    }

    @Test func everyWord_mustMatch() async {
        let model = await viewModel()
        model.query = "portugal dao"
        #expect(model.searchResults.flatMap(\.results).map(\.title) == ["Dão"])
    }

    @Test func lessons_byTitle_withTheirCourse() async {
        let model = await viewModel()
        model.query = "method"
        let lessons = model.searchResults.first { $0.id == "lessons" }
        #expect(lessons?.results.map(\.detail) == ["Douro · Lesson 1"])
    }

    @Test func aCourse_opensInItsTab_open_andClearsTheSearch() async {
        let model = await viewModel()
        model.query = "dao"
        await model.openResult(model.searchResults[0].results[0])
        #expect(model.query.isEmpty)
        #expect(model.tab == .region)
        #expect(model.regionGroups[0].rows.filter(\.isOpen).map(\.id) == ["region-pt-dao"])
    }

    /// As if tapped on the map: selected there, and first in the list.
    @Test func aRegion_isSelectedOnTheMap_andLeadsTheList() async {
        let model = await viewModel()
        model.query = "dao"
        await model.openResult(model.searchResults[0].results[0])
        #expect(model.regionMap?.pins.filter(\.isSelected).map(\.id) == ["region-pt-dao"])
        #expect(model.regionGroups[0].rows.map(\.id) == ["region-pt-dao", "region-pt-douro"])
    }

    @Test func aLesson_opensThePlayer() async {
        let model = await viewModel()
        model.query = "method"
        let lesson = model.searchResults.first { $0.id == "lessons" }!.results[0]
        await model.openResult(lesson)
        #expect(model.player?.lesson.summary.id == "region-pt-douro-l01")
    }
}
