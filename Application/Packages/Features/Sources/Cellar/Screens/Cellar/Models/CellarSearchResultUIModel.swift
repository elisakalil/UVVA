import Foundation

/// A wine found by "Search your cellar" (CELLAR-R11).
struct CellarSearchResultUIModel: Identifiable, Equatable {
    var id: String
    /// "Ponto Forte 2024".
    var title: String
    /// "Alentejo · Syrah & Viognier · 29 Aug".
    var meta: String
    var tag: String
}
