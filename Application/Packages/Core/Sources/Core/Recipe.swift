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

    public init(id: String, title: String, why: String, course: String, wineTypes: [String], profile: PalateMap,
                ingredients: [RecipeIngredient] = [], steps: [String] = [], servings: Int = 4, minutes: Int = 0) {
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
    }
}
