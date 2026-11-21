import Foundation

/// FRI-R15a: a course of the perfect table and how to make its dish, under the menu in the table sheet.
struct TableRecipeUIModel: Identifiable, Equatable {
    /// The bottle's wine, one per course.
    var id: String
    /// "Starter".
    var courseText: String
    /// "Alvarinho, Soalheiro": the bottle the dish is poured with.
    var wineText: String
    var title: String
    var why: String
    /// "Serves 4 · 15 min".
    var servesText: String
    /// "600 g watermelon, rind removed, in 3 cm chunks".
    var ingredients: [String]
    var steps: [String]
}
