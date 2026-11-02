import CoreGraphics
import Foundation

/// Where each region's name goes on the map: on its side of the country, flipped when it would leave the frame,
/// then moved down off the names already placed, with a short line back to its dot (regions-map.js).
enum RegionLabelLayout {
    struct Placement: Equatable {
        var isRight: Bool
        /// The baseline's centre line.
        var y: CGFloat
        var hasLeader: Bool
    }

    private static let padding: CGFloat = 6
    private static let step: CGFloat = 13

    /// The open region is placed first, so its name keeps its place. A name tries its own side, then the other,
    /// level with its dot, then a line further away each time; it never covers a dot or a name already placed.
    static func place(_ pins: [(id: String, name: String, point: CGPoint, isSelected: Bool, lon: Double)],
                      midLon: Double, width: CGFloat) -> [String: Placement] {
        var placed: [CGRect] = []
        var result: [String: Placement] = [:]
        for pin in pins.sorted(by: { $0.isSelected && !$1.isSelected }) {
            let textWidth = Self.width(of: pin.name, isSelected: pin.isSelected)
            let gap = Self.gap(isSelected: pin.isSelected)
            let dots = pins.filter { $0.id != pin.id }.map { other in
                let radius: CGFloat = other.isSelected ? 13 : 4
                return CGRect(x: other.point.x - radius, y: other.point.y - radius, width: radius * 2, height: radius * 2)
            }
            func box(_ isRight: Bool, _ y: CGFloat) -> CGRect {
                CGRect(x: isRight ? pin.point.x + gap : pin.point.x - gap - textWidth, y: y - 6, width: textWidth, height: 12)
            }
            func fits(_ isRight: Bool) -> Bool {
                isRight ? pin.point.x + gap + textWidth <= width - padding : pin.point.x - gap - textWidth >= padding
            }
            let preferred = pin.lon > midLon
            let sides = [preferred, !preferred].filter(fits)
            let offsets: [CGFloat] = [0] + (1...8).flatMap { [CGFloat($0) * step, -CGFloat($0) * step] }
            let candidates = offsets.flatMap { offset -> [(isRight: Bool, y: CGFloat)] in
                sides.map { (isRight: $0, y: pin.point.y + offset) }
            }
            let free = candidates.first { candidate in
                let rect = box(candidate.isRight, candidate.y)
                return !(placed + dots).contains { $0.intersects(rect) }
            }
            let choice = free ?? (isRight: sides.first ?? preferred, y: pin.point.y)
            placed.append(box(choice.isRight, choice.y))
            result[pin.id] = Placement(isRight: choice.isRight, y: choice.y, hasLeader: abs(choice.y - pin.point.y) > 6)
        }
        return result
    }

    /// From the dot to its name; the open region's name clears its ring.
    static func gap(isSelected: Bool) -> CGFloat { isSelected ? 18 : 10 }

    static func fontSize(isSelected: Bool) -> CGFloat { isSelected ? 11 : 10 }

    /// An estimate, as on the canvas: light sans with a little tracking.
    static func width(of name: String, isSelected: Bool) -> CGFloat {
        CGFloat(name.count) * fontSize(isSelected: isSelected) * 0.58
    }
}
