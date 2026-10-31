import Core
import Foundation

/// One recipe of recipes.json.
struct PackedRecipe: Decodable {
    var id: String
    var title: String
    var why: String
    var course: String
    var mainIngredient: String
    var cuisine: String
    var season: [String]
    var diet: [String]
    var allergens: [String]
    var wineTypes: [String]
    var map: PackedAxes
    var twist: RecipeTwist
    var flavor: RecipeFlavor
    var servings: Int
    var prepMinutes: Int
    var cookMinutes: Int
    var difficulty: String
    var ingredients: [RecipeIngredient]
    var steps: [String]
}
