import Foundation

/// The world map under the counts of Progress: the regions of finished courses and the places of tasted wines.
struct ProgressMapUIModel: Equatable {
    var pins: [ProgressMapPin] = []

    func pins(_ kind: ProgressMapPin.Kind) -> [ProgressMapPin] { pins.filter { $0.kind == kind } }
}

struct ProgressMapPin: Equatable, Identifiable {
    enum Kind: Equatable { case region, bottle }

    var id: String
    var kind: Kind
    var lon: Double
    var lat: Double
    /// The region course, or the place of the wines pinned there.
    var name: String
    /// How many tasted wines share the place; 1 for a region.
    var count: Int = 1
}
