import Core
import Foundation
import SwiftData

/// A recipe, in the Content store. The parts only read on the recipe screen are kept as JSON.
@Model
public final class RecipeEntity {
    #Unique<RecipeEntity>([\.id])
    #Index<RecipeEntity>([\.course])

    public var id: String
    public var title: String
    public var why: String
    public var course: String
    public var mainIngredient: String
    public var cuisine: String
    public var season: [String]
    public var diet: [String]
    public var allergens: [String]
    public var wineTypes: [String]
    public var floral: Double
    public var body: Double
    public var tannin: Double
    public var spice: Double
    public var oak: Double
    public var sweetness: Double
    public var acidity: Double
    public var fruit: Double
    public var servings: Int
    public var prepMinutes: Int
    public var cookMinutes: Int
    public var difficulty: String
    public var steps: [String]
    var twistData: Data
    var flavorData: Data
    var ingredientsData: Data

    init(id: String) {
        self.id = id
        self.title = ""
        self.why = ""
        self.course = ""
        self.mainIngredient = ""
        self.cuisine = ""
        self.season = []
        self.diet = []
        self.allergens = []
        self.wineTypes = []
        self.floral = 0
        self.body = 0
        self.tannin = 0
        self.spice = 0
        self.oak = 0
        self.sweetness = 0
        self.acidity = 0
        self.fruit = 0
        self.servings = 0
        self.prepMinutes = 0
        self.cookMinutes = 0
        self.difficulty = ""
        self.steps = []
        self.twistData = Data()
        self.flavorData = Data()
        self.ingredientsData = Data()
    }

    public var palateMap: PalateMap {
        PalateMap([.floral: floral, .body: body, .tannin: tannin, .spice: spice,
                   .oak: oak, .sweetness: sweetness, .acidity: acidity, .fruit: fruit])
    }

    public var twist: RecipeTwist? { try? JSONDecoder().decode(RecipeTwist.self, from: twistData) }
    public var flavor: RecipeFlavor? { try? JSONDecoder().decode(RecipeFlavor.self, from: flavorData) }
    public var ingredients: [RecipeIngredient] {
        (try? JSONDecoder().decode([RecipeIngredient].self, from: ingredientsData)) ?? []
    }
}
