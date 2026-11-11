import Core
import Foundation
import Testing
@testable import Cellar

struct CellarPresentationBuilderTests {
    private func builder(_ entries: [CellarEntry], filters: [CellarFacet: String] = [:],
                         open: CellarFacet? = nil, query: String = "") -> CellarPresentationBuilder {
        CellarPresentationBuilder(entries: entries, filters: filters, openFacet: open, query: query)
    }

    // MARK: CELLAR-R01a · Tag

    @Test func CELLAR_R01a_tag_followsStatusAndVerdict() {
        #expect(CellarTag(Entries.entry("a", verdict: .yes)) == .yes)
        #expect(CellarTag(Entries.entry("b", verdict: .maybe)) == .maybe)
        #expect(CellarTag(Entries.entry("c", verdict: .no)) == .no)
        #expect(CellarTag(Entries.entry("d")) == .notYet)
    }

    // MARK: CELLAR-R02 · Ordem

    @Test func CELLAR_R02_items_keepTheNewestFirstOrder() {
        let items = builder([Entries.entry("new", at: 2), Entries.entry("old", at: 1)]).items
        #expect(items.map(\.id) == ["new", "old"])
    }

    // MARK: CELLAR-R05 · Vazio

    @Test func CELLAR_R05_emptyCellar_showsTheEmptyState() {
        #expect(builder([]).state == .empty)
    }

    // MARK: CELLAR-R09 · Want to try

    @Test func CELLAR_R09_wantToTry_showsNotYet() {
        let item = builder([Entries.entry("baga")]).items.first
        #expect(item?.tag == "Not yet")
    }

    // MARK: CELLAR-R10 · Filtros

    private var mixed: [CellarEntry] {
        [Entries.entry("vale-meao", type: "Red", region: "Douro", grapes: ["Touriga Nacional"], verdict: .yes),
         Entries.entry("redoma-branco", type: "White", region: "Douro", grapes: ["Rabigato"], verdict: .maybe),
         Entries.entry("quinta-roques", type: "Red", region: "Dão", verdict: .no),
         Entries.entry("crasto", type: "Red", region: "Douro")]
    }

    @Test func CELLAR_R10_typeAndRegion_combine() {
        let ids = builder(mixed, filters: [.type: "Red", .region: "Douro"]).items.map(\.id)
        #expect(ids == ["vale-meao", "crasto"])
    }

    @Test func CELLAR_R10_notYetAndRegion_combine() {
        let ids = builder(mixed, filters: [.tag: "Not yet", .region: "Douro"]).items.map(\.id)
        #expect(ids == ["crasto"])
    }

    @Test func CELLAR_R10_regionOptions_onlyTheRegionsInTheCellar() {
        let options = builder(mixed, open: .region).filterSheet?.options.map(\.value)
        #expect(options == ["Dão", "Douro"])
        #expect(options?.contains("Alentejo") == false)
    }

    @Test func CELLAR_R10_tagOptions_alwaysShowTheFour() {
        let sheet = builder([Entries.entry("a", verdict: .yes)], open: .tag).filterSheet
        #expect(sheet?.options.map(\.value) == ["Yes", "Maybe", "No", "Not yet"])
        #expect(sheet?.options.map(\.isDimmed) == [false, true, true, true])
    }

    @Test func CELLAR_R10_counts_followTheOtherFilters() {
        let sheet = builder(mixed, filters: [.region: "Douro"], open: .type).filterSheet
        #expect(sheet?.options.map(\.value) == ["Red", "White"])
        #expect(sheet?.options.map(\.count) == ["2", "1"])
        #expect(sheet?.showText == "Show 3 bottles")
    }

    @Test func CELLAR_R10_grape_matchesAnyGrapeOfABlend() {
        let blend = Entries.entry("ponto-forte", grapes: ["Syrah", "Viognier"], verdict: .yes)
        #expect(builder([blend], filters: [.grape: "Viognier"]).items.count == 1)
    }

    @Test func CELLAR_R10_vintage_filtersAndListsNewestFirst() {
        let wines = [Entries.entry("a", vintage: 2016), Entries.entry("b", vintage: 2020), Entries.entry("c")]
        #expect(builder(wines, open: .vintage).filterSheet?.options.map(\.value) == ["2020", "2016"])
        #expect(builder(wines, filters: [.vintage: "2016"]).items.map(\.id) == ["a"])
    }

    @Test func filters_hidingEverything_showNoMatches() {
        #expect(builder(mixed, filters: [.type: "White", .region: "Dão"]).state == .noMatches)
    }

    // MARK: CELLAR-R11 · Pesquisa

    @Test func CELLAR_R11_search_findsTheGrape_ignoringCase() {
        let wine = Entries.entry("ponto-forte", name: "Ponto Forte", grapes: ["Syrah"], verdict: .yes)
        let results = builder([wine, Entries.entry("other")], query: "syrah").searchResults
        #expect(results.map(\.id) == ["ponto-forte"])
    }

    @Test func CELLAR_R11_search_ignoresAccents() {
        let wine = Entries.entry("roques", region: "Dão", verdict: .yes)
        #expect(builder([wine], query: "dao").searchResults.map(\.id) == ["roques"])
    }

    @Test func CELLAR_R11_search_looksInTheProducer() {
        let wine = Entries.entry("ponto-forte", producer: "Ravasqueira")
        #expect(builder([wine], query: "ravas").searchResults.count == 1)
    }

    @Test func CELLAR_R11_search_ignoresTheFilters() {
        let results = builder(mixed, filters: [.type: "White"], query: "douro").searchResults
        #expect(results.count == 3)
    }

    // MARK: CELLAR-R12 · Sem resultados

    @Test func CELLAR_R12_noResults_isEmpty() {
        let search = builder(mixed, query: "Rioja")
        #expect(search.isSearching)
        #expect(search.searchResults.isEmpty)
    }

    @Test func blankQuery_isNotASearch() {
        #expect(!builder(mixed, query: "   ").isSearching)
    }
}
