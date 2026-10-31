import Foundation

/// The dish of the day's pairing, ready to show (HOME-R09).
public struct Dish: Equatable, Sendable {
    public var title: String
    public var why: String
    /// "600 g watermelon, rind removed, in 3 cm chunks"
    public var ingredients: [String]
    public var steps: [String]
    /// "Serves 4 · 15 min"
    public var serves: String?

    public init(title: String, why: String, ingredients: [String] = [], steps: [String] = [], serves: String? = nil) {
        self.title = title
        self.why = why
        self.ingredients = ingredients
        self.steps = steps
        self.serves = serves
    }
}
