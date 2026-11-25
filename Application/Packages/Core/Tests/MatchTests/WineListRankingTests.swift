import Core
import Testing
@testable import Match

struct WineListRankingTests {
    private func map(_ values: [PalateAxis: Double], rest: Double = 4) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, values[$0] ?? rest) }))
    }

    private func listed(_ name: String, type: String, price: Double?, _ values: [PalateAxis: Double]) -> WineListWine {
        WineListWine(entry: WineListEntry(name: name, price: price, sectionType: type),
                     wine: Wine(id: name, name: name, type: type, origin: "", profile: map(values)), isKnown: true)
    }

    private let crisp = [PalateAxis.acidity: 8.0, .fruit: 6, .body: 3, .tannin: 0.5]
    private let big = [PalateAxis.body: 8.0, .tannin: 7.5, .oak: 6, .acidity: 4]

    private var recipes: [Recipe] {
        [Recipe(id: "fish", title: "Grilled bream", why: "", course: "main", wineTypes: ["White"],
                profile: map(crisp), mainIngredient: "fish"),
         Recipe(id: "steak", title: "Steak", why: "", course: "main", wineTypes: ["Red"],
                profile: map(big), mainIngredient: "red meat")]
    }

    // MARK: WINELIST-R07 · Ordem

    @Test func WINELIST_R07_closestToThePalate_comesFirst() {
        let picks = WineListRanking.rank([listed("Big", type: "Red", price: 40, big),
                                          listed("Crisp", type: "White", price: 30, crisp)],
                                         palates: [map(crisp)], dishes: [], recipes: recipes, budget: nil)
        #expect(picks.map(\.wine.entry.name) == ["Crisp", "Big"])
        #expect(picks[0].percent > picks[1].percent)
        #expect(picks[0].dishPercent == nil)
    }

    @Test func WINELIST_R07_theDish_movesTheWine() {
        let palate = map([.acidity: 6, .body: 5.5, .tannin: 4])
        let wines = [listed("Big", type: "Red", price: 40, big), listed("Crisp", type: "White", price: 30, crisp)]
        let withFish = WineListRanking.rank(wines, palates: [palate], dishes: [.fish], recipes: recipes, budget: nil)
        let withSteak = WineListRanking.rank(wines, palates: [palate], dishes: [.redMeat], recipes: recipes, budget: nil)
        #expect(withFish.first?.wine.entry.name == "Crisp")
        #expect(withSteak.first?.wine.entry.name == "Big")
    }

    @Test func WINELIST_R07_aWineOfAnotherType_keepsOnlyAShareOfTheDish() {
        let red = Wine(id: "r", name: "R", type: "Red", origin: "", profile: map(crisp))
        let fishRecipes = recipes.filter { $0.mainIngredient == "fish" }
        let white = Wine(id: "w", name: "W", type: "White", origin: "", profile: map(crisp))
        #expect(WineListRanking.fit(red, recipes: fishRecipes) < WineListRanking.fit(white, recipes: fishRecipes))
    }

    @Test func WINELIST_R07_overTheBudget_goesAfter_evenWithABetterMatch() {
        let picks = WineListRanking.rank([listed("Dear", type: "White", price: 90, crisp),
                                          listed("Cheap", type: "Red", price: 25, big)],
                                         palates: [map(crisp)], dishes: [], recipes: recipes, budget: 45)
        #expect(picks.map(\.wine.entry.name) == ["Cheap", "Dear"])
        #expect(picks.map(\.fitsBudget) == [true, false])
    }

    @Test func WINELIST_R07_theTable_isReadAsOneMap() {
        let wines = [listed("Big", type: "Red", price: 40, big), listed("Crisp", type: "White", price: 30, crisp)]
        let alone = WineListRanking.rank(wines, palates: [map(crisp)], dishes: [], recipes: [], budget: nil)
        let together = WineListRanking.rank(wines, palates: [map(crisp), map(big), map(big)], dishes: [], recipes: [],
                                            budget: nil)
        #expect(alone.first?.wine.entry.name == "Crisp")
        #expect(together.first?.wine.entry.name == "Big")
    }

    // MARK: WINELIST-R05 · Reconhecer

    @Test func WINELIST_R05_aCatalogWine_isFoundByItsWords() {
        let soalheiro = Wine(id: "soalheiro-alvarinho", name: "Alvarinho", producer: "Soalheiro", type: "White",
                             origin: "Vinho Verde", grapes: ["Alvarinho"], profile: map(crisp))
        let crasto = Wine(id: "crasto", name: "Touriga Nacional", producer: "Quinta do Crasto", type: "Red",
                          origin: "Douro", grapes: ["Touriga Nacional"], profile: map(big))
        let wines = [soalheiro, crasto]
        let found = WineListIdentifier.wine(
            for: WineListEntry(name: "Soalheiro Alvarinho 2023", price: 42, sectionType: "White"),
            index: LabelCatalogIndex(wines: wines), vocabulary: LabelVocabulary(wines: wines), wines: wines,
            currentYear: 2026)
        #expect(found?.isKnown == true)
        #expect(found?.wine.producer == "Soalheiro")
        #expect(found?.wine.vintage == 2023)
    }

    @Test func WINELIST_R05_anUnknownWine_isEstimatedFromItsGrape() {
        let crasto = Wine(id: "crasto", name: "Touriga Nacional", producer: "Quinta do Crasto", type: "Red",
                          origin: "Douro", grapes: ["Touriga Nacional"], profile: map(big))
        let wines = [crasto]
        let found = WineListIdentifier.wine(
            for: WineListEntry(name: "Casa Ferreirinha Touriga Nacional", sectionType: "Red"),
            index: LabelCatalogIndex(wines: []), vocabulary: LabelVocabulary(wines: wines), wines: wines,
            currentYear: 2026)
        #expect(found?.isKnown == false)
        #expect(found?.wine.profile == map(big))
        #expect(found?.wine.type == "Red")
    }
}
