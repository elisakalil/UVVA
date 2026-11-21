import Foundation

/// A wine of the friend's wine cards, "Picks for [name]" (FRI-R11) and "Open this together" (FRI-R12), as a
/// row of the Home's "Wines for your palate": the wine and its producer, and under it only the reading and how
/// strong the wine is on it ("High acidity").
struct WineCardRowUIModel: Identifiable, Equatable {
    var id: String
    /// "Alvarinho, Soalheiro".
    var title: String
    /// The reading the wine is chosen for.
    var axisName: String
    var axisText: String
}
