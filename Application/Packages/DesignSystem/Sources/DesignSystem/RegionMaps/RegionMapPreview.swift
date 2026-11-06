import SwiftUI

/// Compact version of Learn's country geometry, with the suggested region at its true coordinates.
public struct RegionMapPreview: View {
    var country: String
    var courseID: String

    public init(country: String, courseID: String) {
        self.country = country
        self.courseID = courseID
    }

    public var body: some View {
        GeometryReader { geometry in
            if let shape = RegionAtlas.shared.country(country) {
                let rings = shape.thumbnailLand ?? shape.land
                let points = rings.flatMap { ring in
                    stride(from: 0, to: ring.count - 1, by: 2).map { (lon: ring[$0], lat: ring[$0 + 1]) }
                }
                let box = [points.map(\.lon).min() ?? shape.box[0],
                           points.map(\.lat).min() ?? shape.box[1],
                           points.map(\.lon).max() ?? shape.box[2],
                           points.map(\.lat).max() ?? shape.box[3]]
                let projection = MapProjection(box: box, size: geometry.size, margin: 8)
                Canvas { context, _ in
                    for ring in rings {
                        let path = Path(projection.path(ring))
                        context.fill(path, with: .color(UVVAColor.cream.opacity(0.06)))
                        context.stroke(path, with: .color(UVVAColor.cream.opacity(0.55)), lineWidth: 0.8)
                    }
                    if let coordinate = RegionAtlas.shared.regions[courseID], coordinate.count == 2 {
                        let point = projection.point(lon: coordinate[0], lat: coordinate[1])
                        // Remote islands are outside the mainland frame: keep their marker visible in an inset.
                        let isInset = RegionAtlas.shared.insets.contains(courseID)
                        let center = isInset ? CGPoint(x: 18, y: geometry.size.height - 18) : point
                        context.stroke(Path(ellipseIn: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18)),
                                       with: .color(UVVAColor.cream.opacity(0.45)), lineWidth: 0.6)
                        context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
                                     with: .color(UVVAColor.cream))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}
