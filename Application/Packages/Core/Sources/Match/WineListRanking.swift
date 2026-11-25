import Core
import Foundation

/// The wines of a list ranked for tonight (WINELIST-R07). The palates at the table are crossed into one map
/// (`TableMatch.crossed`); each wine is scored by its distance to it (`Similarity`), and, with dishes chosen, by
/// its distance to the recipes of those dishes made for its type. A wine of a type none of a dish's recipes are made
/// for keeps a share of that dish's score. The wines within the budget come first, best first.
public enum WineListRanking {
    /// The weight of the dishes against the palates, when there are dishes.
    static let dishWeight = 0.45
    /// What a wine of a type a dish's recipes are not made for keeps of that dish's score.
    static let wrongTypeShare = 0.7
    /// The recipes of a dish a wine is measured against: its closest few, so one odd recipe does not decide.
    static let closestRecipes = 3

    public static func rank(_ wines: [WineListWine], palates: [PalateMap], dishes: Set<MenuDish>, recipes: [Recipe],
                            budget: Double?) -> [WineListPick] {
        let palate = palates.isEmpty ? nil : TableMatch.crossed(palates)
        let pools = dishes.map { dish in
            recipes.filter { dish.mainIngredients.contains($0.mainIngredient) && dish.courses.contains($0.course) }
        }.filter { !$0.isEmpty }
        let picks = wines.map { listed -> WineListPick in
            let profile = listed.wine.profile
            let palateScore = palate.map { Similarity.between($0, profile) } ?? 0.5
            let dishScores = pools.map { fit(listed.wine, recipes: $0) }
            let dishScore = dishScores.isEmpty ? nil : dishScores.reduce(0, +) / Double(dishScores.count)
            let total = dishScore.map { (1 - dishWeight) * palateScore + dishWeight * $0 } ?? palateScore
            let fits = budget.map { limit in listed.entry.price.map { $0 <= limit } ?? true } ?? true
            return WineListPick(wine: listed, percent: percent(total), palatePercent: percent(palateScore),
                                dishPercent: dishScore.map(percent), fitsBudget: fits)
        }
        return picks.sorted { lhs, rhs in
            if lhs.fitsBudget != rhs.fitsBudget { return lhs.fitsBudget }
            if lhs.percent != rhs.percent { return lhs.percent > rhs.percent }
            if lhs.wine.isKnown != rhs.wine.isKnown { return lhs.wine.isKnown }
            return (lhs.wine.entry.price ?? 0) < (rhs.wine.entry.price ?? 0)
        }
    }

    /// How close the wine is to the closest recipes of one dish, among those made for its type when there are.
    static func fit(_ wine: Wine, recipes: [Recipe]) -> Double {
        let forType = recipes.filter { recipe in
            recipe.wineTypes.contains { $0.caseInsensitiveCompare(wine.type) == .orderedSame }
        }
        let pool = forType.isEmpty ? recipes : forType
        let closest = pool.map { Similarity.between($0.profile, wine.profile) }.sorted(by: >).prefix(closestRecipes)
        guard !closest.isEmpty else { return 0 }
        let score = closest.reduce(0, +) / Double(closest.count)
        return forType.isEmpty ? score * wrongTypeShare : score
    }

    static func percent(_ score: Double) -> Int { Int((min(max(score, 0), 1) * 100).rounded()) }
}
