import Core
import Foundation

/// How the user wants the perfect dinner (FRI-R13a): which courses, what goes on the table, in season or not, and
/// how long it may take. The bottles still come from both maps; these only choose among the dishes.
public struct DinnerPreferences: Equatable, Sendable {
    /// What goes on the table: a diet, which holds for every dish, or what the main dish is built on.
    public enum Food: CaseIterable, Sendable {
        case anything, vegetarian, vegan, pasta, risotto, fish, seafood, poultry, meat, pork
    }

    public enum Time: CaseIterable, Sendable {
        case any, quick
    }

    /// In the order they are served; never empty.
    var courses: [TableCourse] = TableCourse.standard
    var food = Food.anything
    var inSeason = false
    var time = Time.any

    /// A quick dinner: every dish ready in this many minutes or fewer.
    static let quickMinutes = 45

    /// Turns a course on or off, keeping at least one.
    mutating func toggle(_ course: TableCourse) {
        if courses.contains(course) {
            guard courses.count > 1 else { return }
            courses.removeAll { $0 == course }
        } else {
            courses = TableCourse.allCases.filter { courses.contains($0) || $0 == course }
        }
    }

    /// The recipes that fit, course by course. A course that the season or the time would leave without a dish
    /// keeps those of any season, then of any time: what goes on the table is never given up.
    func recipes(from all: [Recipe], on date: Date) -> [Recipe] {
        let season = Self.season(of: date)
        let led = ledCourse
        return courses.flatMap { course -> [Recipe] in
            let ofCourse = all.filter { $0.course == course.rawValue && fitsDiet($0) }
            let dishes = course == led ? ofCourse.filter(isBuiltOnChoice) : ofCourse
            let timed = time == .quick ? dishes.filter { $0.minutes > 0 && $0.minutes <= Self.quickMinutes } : dishes
            let seasonal = inSeason ? timed.filter { $0.season.isEmpty || $0.season.contains(season) } : timed
            if !seasonal.isEmpty { return seasonal }
            if !timed.isEmpty { return timed }
            // Nothing of that course is built on the choice: the course stays, with its other dishes.
            return dishes.isEmpty ? ofCourse : dishes
        }
    }

    /// The course that pasta, fish or the rest decide: the main, or the starter when there is no main. The other
    /// courses keep their own dishes, so a pasta dinner is not pasta three times.
    private var ledCourse: TableCourse? {
        courses.contains(.main) ? .main : courses.contains(.starter) ? .starter : nil
    }

    /// Vegetarian and vegan hold for every dish.
    private func fitsDiet(_ recipe: Recipe) -> Bool {
        switch food {
        case .vegetarian: recipe.diet.contains("vegetarian") || recipe.diet.contains("vegan")
        case .vegan: recipe.diet.contains("vegan")
        default: true
        }
    }

    private func isBuiltOnChoice(_ recipe: Recipe) -> Bool {
        switch food {
        case .anything, .vegetarian, .vegan: true
        case .pasta: Self.isBuilt(recipe, on: Self.pasta)
        case .risotto: Self.isBuilt(recipe, on: Self.rice)
        case .fish: recipe.mainIngredient == "fish"
        case .seafood: recipe.mainIngredient == "shellfish"
        case .poultry: recipe.mainIngredient == "poultry"
        case .meat: ["red meat", "game"].contains(recipe.mainIngredient)
        case .pork: recipe.mainIngredient == "pork"
        }
    }

    /// The recipes have no "pasta" of their own: a dish is pasta when the base of it is (linguine, pappardelle,
    /// rice noodles…), and a risotto when its base is a risotto or paella rice.
    private static func isBuilt(_ recipe: Recipe, on words: [String]) -> Bool {
        recipe.ingredients.contains { ingredient in
            guard ingredient.role == "base" else { return false }
            let name = ingredient.name.lowercased()
            return words.contains { name.contains($0) }
        }
    }

    static let pasta = ["pasta", "spaghetti", "linguine", "tagliatelle", "tajarin", "pappardelle", "fettuccine",
                        "penne", "rigatoni", "orecchiette", "bucatini", "fusilli", "macaroni", "orzo", "lasagne",
                        "lasagna", "ravioli", "agnolotti", "tortellini", "gnocchi", "noodles"]
    static let rice = ["arborio", "carnaroli", "vialone", "paella rice", "bomba"]

    /// "spring", "summer", "autumn" or "winter", in the northern hemisphere, where the recipes were written.
    static func season(of date: Date) -> String {
        switch Calendar(identifier: .gregorian).component(.month, from: date) {
        case 3...5: "spring"
        case 6...8: "summer"
        case 9...11: "autumn"
        default: "winter"
        }
    }
}
