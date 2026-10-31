import Foundation

/// One line of a recipe's ingredient list.
public struct RecipeIngredient: Codable, Equatable, Sendable {
    public var name: String
    public var quantity: Double?
    public var unit: String?
    public var note: String?
    /// base, sauce, garnish, seasoning or twist.
    public var role: String

    public init(name: String, quantity: Double?, unit: String?, note: String?, role: String) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.note = note
        self.role = role
    }
}
