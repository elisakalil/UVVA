import Core
import Foundation

/// User × wine × recipe (MATCH.md): the user's map and the wine's are crossed into one, the average of the two,
/// and the recipe closest to it is the dish. Only recipes made for that type of wine count, and a starter or a
/// main comes before a dessert, a snack or a cheese board.
public enum Pairing {
    static let mealCourses: Set<String> = ["main", "starter"]

    public static func crossed(_ a: PalateMap, _ b: PalateMap) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, (a[$0] + b[$0]) / 2) }))
    }

    public static func recipe(for wine: Wine, user: PalateMap, among recipes: [Recipe]) -> Recipe? {
        let forType = recipes.filter { recipe in recipe.wineTypes.contains { $0.caseInsensitiveCompare(wine.type) == .orderedSame } }
        let meals = forType.filter { mealCourses.contains($0.course) }
        let pool = meals.isEmpty ? forType : meals
        let target = crossed(user, wine.profile)
        return pool.max { Similarity.between($0.profile, target) < Similarity.between($1.profile, target) }
    }

    /// The recipe as the Home shows it (HOME-R09).
    public static func dish(from recipe: Recipe) -> Dish {
        Dish(title: recipe.title, why: recipe.why,
             ingredients: recipe.ingredients.map(Self.line),
             steps: recipe.steps,
             serves: recipe.minutes > 0 ? "Serves \(recipe.servings) · \(recipe.minutes) min" : "Serves \(recipe.servings)")
    }

    /// "600 g watermelon, rind removed", "½ red onion", "1 pinch flaky salt".
    static func line(_ ingredient: RecipeIngredient) -> String {
        var parts: [String] = []
        if let quantity = ingredient.quantity { parts.append(amount(quantity)) }
        if let unit = ingredient.unit, unit != "whole" { parts.append(unit) }
        parts.append(ingredient.name)
        let line = parts.joined(separator: " ")
        guard let note = ingredient.note, !note.isEmpty else { return line }
        return line + ", " + note
    }

    static func amount(_ value: Double) -> String {
        let fractions: [Double: String] = [0.25: "¼", 0.5: "½", 0.75: "¾"]
        let whole = value.rounded(.down)
        if let fraction = fractions[value - whole] { return whole == 0 ? fraction : "\(Int(whole))\(fraction)" }
        return value == whole ? String(Int(value)) : String(format: "%.1f", value)
    }
}
