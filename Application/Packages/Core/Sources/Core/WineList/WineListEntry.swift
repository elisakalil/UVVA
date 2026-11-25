import Foundation

/// A wine as the list prints it (WINELIST-R04): its line, the lines under it, its price and the section it is in.
public struct WineListEntry: Equatable, Sendable {
    /// The wine's line without its price, as printed: what the waiter will recognise.
    public var name: String
    /// The lines that go with it: the grape, the region, the producer.
    public var details: [String]
    /// The price of a bottle, the highest one on the row when it gives a glass too. Nil when the list shows none.
    public var price: Double?
    /// The section's heading as printed, "Tintos", "Whites".
    public var section: String?
    /// The type the section says, "Red", "White", "Rosé", "Sparkling" or "Fortified".
    public var sectionType: String?
    /// Its place in its section, from 1.
    public var position: Int

    public init(name: String, details: [String] = [], price: Double? = nil, section: String? = nil,
                sectionType: String? = nil, position: Int = 1) {
        self.name = name
        self.details = details
        self.price = price
        self.section = section
        self.sectionType = sectionType
        self.position = position
    }
}
