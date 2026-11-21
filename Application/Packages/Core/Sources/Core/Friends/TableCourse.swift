import Foundation

/// The courses of a table, in the order they are served (FRI-R15). The raw value is the recipe's `course`.
/// A table has Starter, Main and Dessert unless the user chose otherwise (FRI-R13a); Cheese only when chosen.
public enum TableCourse: String, CaseIterable, Sendable {
    case starter, main, cheese, dessert

    /// The courses of a table nobody chose for: Starter, Main and Dessert.
    public static let standard: [TableCourse] = [.starter, .main, .dessert]
}
