import Core
import Foundation

/// A catalog wine with the words of its name and producer, ready to be compared with a label.
struct LabelCatalogEntry: Sendable {
    var wine: Wine
    var name: Set<String>
    var producer: Set<String>

    init(_ wine: Wine) {
        self.wine = wine
        name = WineText.significantTokens(wine.name)
        producer = WineText.significantTokens(wine.producer)
    }
}
