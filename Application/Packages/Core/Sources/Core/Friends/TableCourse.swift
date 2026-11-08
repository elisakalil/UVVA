import Foundation

/// The three courses of a table, in order (FRI-R15). The raw value is the recipe's `course`.
public enum TableCourse: String, CaseIterable, Sendable {
    case starter, main, dessert
}
