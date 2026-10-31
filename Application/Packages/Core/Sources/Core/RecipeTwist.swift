import Foundation

/// The ingredient that pulls a recipe towards one axis, and by how much.
public struct RecipeTwist: Codable, Equatable, Sendable {
    public var ingredient: String
    public var axis: PalateAxis
    public var shift: Double

    public init(ingredient: String, axis: PalateAxis, shift: Double) {
        self.ingredient = ingredient
        self.axis = axis
        self.shift = shift
    }
}
