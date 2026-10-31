import Core
import Testing
@testable import Match

struct PairingTests {
    private func map(_ values: [PalateAxis: Double], rest: Double = 5) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, values[$0] ?? rest) }))
    }

    private func recipe(_ id: String, course: String = "main", types: [String] = ["Red"], acidity: Double) -> Recipe {
        Recipe(id: id, title: id, why: "", course: course, wineTypes: types, profile: map([.acidity: acidity]))
    }


    @Test func crossed_isTheAverageOfTheTwoMaps() {
        let crossed = Pairing.crossed(map([.acidity: 8]), map([.acidity: 2]))
        #expect(crossed[.acidity] == 5)
    }

    @Test func recipe_isTheClosestToTheCrossedMap() {
        let user = map([.acidity: 8])
        let red = Wine(id: "w", name: "W", type: "Red", origin: "", profile: map([.acidity: 4]))
        let picked = Pairing.recipe(for: red, user: user,
                                    among: [recipe("far", acidity: 1), recipe("near", acidity: 6), recipe("mid", acidity: 3)])
        #expect(picked?.id == "near")
    }

    @Test func recipe_onlyFromTheWinesType() {
        let red = Wine(id: "w", name: "W", type: "Red", origin: "", profile: map([:]))
        let picked = Pairing.recipe(for: red, user: map([:]),
                                    among: [recipe("white", types: ["White"], acidity: 5), recipe("red", acidity: 1)])
        #expect(picked?.id == "red")
    }

    @Test func recipe_prefersAMealOverADessert() {
        let red = Wine(id: "w", name: "W", type: "Red", origin: "", profile: map([:]))
        let picked = Pairing.recipe(for: red, user: map([:]),
                                    among: [recipe("cake", course: "dessert", acidity: 5), recipe("stew", acidity: 1)])
        #expect(picked?.id == "stew")
    }

    @Test func recipe_noneForTheType_isNil() {
        let sparkling = Wine(id: "w", name: "W", type: "Sparkling", origin: "", profile: map([:]))
        #expect(Pairing.recipe(for: sparkling, user: map([:]), among: [recipe("red", acidity: 5)]) == nil)
    }

    @Test func ingredientLines() {
        #expect(Pairing.line(RecipeIngredient(name: "watermelon", quantity: 600, unit: "g", note: "rind removed", role: "base"))
                == "600 g watermelon, rind removed")
        #expect(Pairing.line(RecipeIngredient(name: "red onion", quantity: 0.5, unit: "whole", note: nil, role: "garnish"))
                == "½ red onion")
        #expect(Pairing.line(RecipeIngredient(name: "salt", quantity: 1.5, unit: "tsp", note: nil, role: "seasoning"))
                == "1½ tsp salt")
    }
}
