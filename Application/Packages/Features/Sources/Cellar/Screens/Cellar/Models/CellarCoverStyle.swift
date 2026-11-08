import Foundation

/// Where the tag sits on a cover, and how big: the covers vary it, like a magazine page (CELLAR-R06).
struct CellarCoverStyle: Equatable, Sendable {
    enum Corner: Sendable { case topLeading, topTrailing, trailing, bottomLeading, bottomTrailing }

    var corner: Corner
    var size: Double

    /// The order the covers take in the design, repeated down the grid.
    static let sequence: [CellarCoverStyle] = [
        CellarCoverStyle(corner: .bottomLeading, size: 40),
        CellarCoverStyle(corner: .topTrailing, size: 20),
        CellarCoverStyle(corner: .trailing, size: 30),
        CellarCoverStyle(corner: .bottomLeading, size: 16),
        CellarCoverStyle(corner: .topLeading, size: 28),
        CellarCoverStyle(corner: .bottomTrailing, size: 24)
    ]

    static func at(_ index: Int) -> CellarCoverStyle { sequence[index % sequence.count] }
}
