import Foundation

/// A recipe of the catalog (UVVARecipes.json).
public struct Recipe: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var why: String
    /// starter, main, dessert, snack or cheese.
    public var course: String
    /// The wine types it goes with ("Red", "White"…).
    public var wineTypes: [String]
    public var profile: PalateMap
    public var ingredients: [RecipeIngredient]
    public var steps: [String]
    public var servings: Int
    public var minutes: Int
    /// "fish", "red meat", "vegetable"…: what the dish is built on.
    public var mainIngredient: String
    /// "vegetarian", "vegan", "glutenFree".
    public var diet: [String]
    /// The seasons it belongs to ("spring", "summer", "autumn", "winter"); all four for a dish of any time.
    public var season: [String]

    public init(id: String, title: String, why: String, course: String, wineTypes: [String], profile: PalateMap,
                ingredients: [RecipeIngredient] = [], steps: [String] = [], servings: Int = 4, minutes: Int = 0,
                mainIngredient: String = "", diet: [String] = [], season: [String] = []) {
        self.id = id
        self.title = title
        self.why = why
        self.course = course
        self.wineTypes = wineTypes
        self.profile = profile
        self.ingredients = ingredients
        self.steps = steps
        self.servings = servings
        self.minutes = minutes
        self.mainIngredient = mainIngredient
        self.diet = diet
        self.season = season
    }
}
