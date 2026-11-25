import Foundation

/// What is on the table at the restaurant (WINELIST-R06), as the recipes of the catalog group their dishes by what
/// they are built on (`Recipe.mainIngredient`): the wines of the list are paired with those recipes.
public enum MenuDish: String, CaseIterable, Identifiable, Sendable {
    case fish, shellfish, poultry, pork, redMeat, game, vegetables, cheese, dessert

    public var id: Self { self }

    /// The recipes' `mainIngredient` values this dish stands for.
    public var mainIngredients: Set<String> {
        switch self {
        case .fish: ["fish"]
        case .shellfish: ["shellfish"]
        case .poultry: ["poultry", "egg"]
        case .pork: ["pork"]
        case .redMeat: ["red meat"]
        case .game: ["game"]
        case .vegetables: ["vegetable"]
        case .cheese: ["cheese"]
        case .dessert: ["chocolate", "fruit"]
        }
    }

    /// The courses its recipes count from: a cheese is any cheese recipe, a dessert only a dessert, the rest the
    /// starters and mains.
    public var courses: Set<String> {
        switch self {
        case .cheese: ["cheese", "starter", "main", "snack"]
        case .dessert: ["dessert"]
        default: ["starter", "main"]
        }
    }
}
