import Foundation

/// The sheet of one filter: its values, "Show n bottles" and "Any …" (CELLAR-R10).
struct CellarFilterSheetUIModel: Identifiable, Equatable {
    var facet: CellarFacet
    var title: String
    var options: [CellarFilterOptionUIModel]
    var showText: String
    var anyText: String
    var id: String { facet.id }
}
