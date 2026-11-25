import Foundation

/// A wine of the list, scored for tonight (WINELIST-R07): how close it is to the palates at the table and to the
/// dishes, and whether it fits the budget.
public struct WineListPick: Identifiable, Equatable, Sendable {
    public var wine: WineListWine
    /// The match shown, 0...100.
    public var percent: Int
    /// The palates alone, 0...100.
    public var palatePercent: Int
    /// The dishes alone, 0...100; nil with no dish chosen.
    public var dishPercent: Int?
    public var fitsBudget: Bool

    public var id: String { wine.id }

    public init(wine: WineListWine, percent: Int, palatePercent: Int, dishPercent: Int?, fitsBudget: Bool) {
        self.wine = wine
        self.percent = percent
        self.palatePercent = palatePercent
        self.dishPercent = dishPercent
        self.fitsBudget = fitsBudget
    }
}
