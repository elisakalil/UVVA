import Foundation

/// One region on the By region map: a dot at its true place, larger when it is the open region (LEARN-R06).
struct RegionPinUIModel: Identifiable, Equatable {
    var id: String
    var name: String
    var lon: Double
    var lat: Double
    var isSelected: Bool
    /// Far off the mainland (Madeira): drawn in a corner of the map.
    var isInset: Bool
}
