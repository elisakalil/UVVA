import CoreGraphics
import Foundation

/// Mercator fitted to a lon/lat frame inside a size, with a margin; the frame stays centred (d3's fitExtent).
public struct MapProjection {
    private let scale: Double
    private let center: (x: Double, y: Double)
    private let mid: CGPoint

    public init(box: [Double], size: CGSize, margin: Double = 26) {
        let low = Self.mercator(lon: box[0], lat: box[1])
        let high = Self.mercator(lon: box[2], lat: box[3])
        let width = max(Double(size.width) - margin * 2, 1)
        let height = max(Double(size.height) - margin * 2, 1)
        scale = min(width / max(high.x - low.x, .ulpOfOne), height / max(high.y - low.y, .ulpOfOne))
        center = ((low.x + high.x) / 2, (low.y + high.y) / 2)
        mid = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    public func point(lon: Double, lat: Double) -> CGPoint {
        let m = Self.mercator(lon: lon, lat: lat)
        return CGPoint(x: mid.x + (m.x - center.x) * scale, y: mid.y - (m.y - center.y) * scale)
    }

    /// A flat `[lon, lat, ...]` ring as a closed path.
    public func path(_ ring: [Double]) -> CGPath {
        let path = CGMutablePath()
        for index in stride(from: 0, to: ring.count - 1, by: 2) {
            let p = point(lon: ring[index], lat: ring[index + 1])
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    /// Width over height of a map `width` wide that fits the frame, kept between `minHeight` and `maxHeight`.
    public static func aspectRatio(box: [Double], width: Double = 350, margin: Double = 26,
                            minHeight: Double = 240, maxHeight: Double = 430) -> Double {
        let low = mercator(lon: box[0], lat: box[1])
        let high = mercator(lon: box[2], lat: box[3])
        let height = (width - margin * 2) * (high.y - low.y) / max(high.x - low.x, .ulpOfOne) + margin * 2
        return width / min(max(height, minHeight), maxHeight)
    }

    private static func mercator(lon: Double, lat: Double) -> (x: Double, y: Double) {
        let phi = min(max(lat, -85), 85) * .pi / 180
        return (lon * .pi / 180, log(tan(.pi / 4 + phi / 2)))
    }
}
