import Foundation

/// Where the tag sits on a cover, and how big: the covers vary it, like a magazine page (CELLAR-R06).
/// The match and the name always take the lower left corner; the tag moves within the space above them.
struct CellarCoverStyle: Equatable, Sendable {
    enum Placement: Sendable { case topLeading, top, topTrailing, center, trailing, bottomTrailing }

    var placement: Placement
    var size: Double

    /// The order the covers take in the design, repeated down the grid.
    static let sequence: [CellarCoverStyle] = [
        CellarCoverStyle(placement: .topLeading, size: 40),
        CellarCoverStyle(placement: .topTrailing, size: 20),
        CellarCoverStyle(placement: .trailing, size: 30),
        CellarCoverStyle(placement: .center, size: 18),
        CellarCoverStyle(placement: .top, size: 28),
        CellarCoverStyle(placement: .bottomTrailing, size: 24)
    ]

    static func at(_ index: Int) -> CellarCoverStyle { sequence[index % sequence.count] }
}
