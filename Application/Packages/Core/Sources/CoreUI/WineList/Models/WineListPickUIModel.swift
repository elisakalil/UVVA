import Foundation

/// A wine to order, as "Order this" shows it (WINELIST-R07): the first one large, the others below it.
struct WineListPickUIModel: Identifiable, Equatable {
    var id: String
    /// "Close second", "Same feel, less money"; the first one has none.
    var role: String?
    /// The grape and the place, "Alvarinho · Vinho Verde"; what the wine is, before its name.
    var title: String
    /// The wine as the list prints it.
    var name: String
    /// "42 € · 1st in Brancos".
    var meta: String
    var match: Int
    var price: String?
    /// Why it is the one, in a sentence or two.
    var why: String
    var isOverBudget: Bool
    /// The catalog does not have it: its map is estimated from what the list says.
    var isEstimated: Bool
}
