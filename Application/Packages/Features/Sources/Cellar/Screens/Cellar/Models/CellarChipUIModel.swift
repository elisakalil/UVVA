import Foundation

/// A filter above the Cellar: its name, or the value picked in it (CELLAR-R10).
struct CellarChipUIModel: Identifiable, Equatable {
    var facet: CellarFacet
    var label: String
    var isActive: Bool
    var id: String { facet.id }
}
