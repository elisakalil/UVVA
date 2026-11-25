import Foundation

/// A wine of the list, as printed, and the wine UVVA takes it to be (WINELIST-R05): the catalog's, or one made from
/// what the list says, with its map estimated from the wines most like it.
public struct WineListWine: Identifiable, Equatable, Sendable {
    public var entry: WineListEntry
    public var wine: Wine
    /// The catalog has it; otherwise its map is an estimate.
    public var isKnown: Bool

    public var id: String { "\(entry.section ?? "")|\(entry.position)|\(entry.name)" }

    public init(entry: WineListEntry, wine: Wine, isKnown: Bool) {
        self.entry = entry
        self.wine = wine
        self.isKnown = isKnown
    }
}
