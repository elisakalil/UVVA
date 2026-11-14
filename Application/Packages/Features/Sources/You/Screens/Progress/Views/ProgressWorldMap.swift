import DesignSystem
import SwiftUI

/// The world under the counts of Progress, drawn like the maps of By region: the coastlines in a white fade, the
/// regions of finished courses as solid dots with a ring, the places of tasted wines as small open rings. While the
/// Regions or Bottles sheet is open only its pins stay.
struct ProgressWorldMap: View {
    var model: ProgressMapUIModel
    /// The kind the open sheet keeps; nil shows both.
    var focus: ProgressMapPin.Kind?

    private let atlas = WorldAtlas.shared
    private let ink = UVVAColor.creamFill

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Color.clear
                .aspectRatio(WorldProjection.aspectRatio(box: atlas.box), contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        map(in: geometry.size)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(Text(accessibilityText))
            legend
        }
        .animation(.easeInOut(duration: 0.35), value: focus)
        .animation(.easeInOut(duration: 0.35), value: model)
    }

    private func map(in size: CGSize) -> some View {
        let projection = WorldProjection(box: atlas.box, size: size)
        return ZStack {
            land(projection, size: size)
            bottles(projection)
                .opacity(isShown(.bottle) ? 1 : 0)
            regions(projection)
                .opacity(isShown(.region) ? 1 : 0)
        }
        .frame(width: size.width, height: size.height)
    }

    private func isShown(_ kind: ProgressMapPin.Kind) -> Bool { focus == nil || focus == kind }

    // MARK: Land

    /// The coastlines and a faint white fill, fading towards the edges so no edge of the world looks cut.
    private func land(_ projection: WorldProjection, size: CGSize) -> some View {
        Canvas { context, _ in
            let path = Path(projection.path(atlas.land))
            context.fill(path, with: .color(ink.opacity(0.09)), style: FillStyle(eoFill: true))
            context.stroke(path, with: .color(ink.opacity(0.42)), lineWidth: 0.5)
        }
        .mask {
            RadialGradient(stops: [.init(color: .white, location: 0),
                                   .init(color: .white.opacity(0.75), location: 0.6),
                                   .init(color: .white.opacity(0.25), location: 1)],
                           center: .center, startRadius: 0, endRadius: max(size.width, size.height) * 0.6)
        }
        // The Arctic runs past the top of the frame: it fades out there instead of ending on a straight line.
        .mask {
            LinearGradient(stops: [.init(color: .white.opacity(0), location: 0), .init(color: .white, location: 0.12)],
                           startPoint: .top, endPoint: .bottom)
        }
        .accessibilityHidden(true)
    }

    // MARK: Pins

    /// A finished region: a solid dot inside a thin ring, the dot of the open region in By region.
    private func regions(_ projection: WorldProjection) -> some View {
        Canvas { context, _ in
            for pin in model.pins(.region) {
                let p = projection.point(lon: pin.lon, lat: pin.lat)
                context.stroke(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)),
                               with: .color(ink.opacity(0.5)), lineWidth: 0.6)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)),
                             with: .color(ink))
            }
        }
        .accessibilityHidden(true)
    }

    /// A place of tasted wines: an open ring, a little wider when several wines come from there.
    private func bottles(_ projection: WorldProjection) -> some View {
        Canvas { context, _ in
            for pin in model.pins(.bottle) {
                let p = projection.point(lon: pin.lon, lat: pin.lat)
                let radius = Self.bottleRadius(count: pin.count)
                let ring = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                context.fill(ring, with: .color(UVVAColor.night.opacity(0.35)))
                context.stroke(ring, with: .color(ink.opacity(0.9)), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }

    static func bottleRadius(count: Int) -> CGFloat { min(2.5 + CGFloat(count - 1) * 0.5, 4.5) }

    // MARK: Legend

    private var legend: some View {
        HStack(spacing: 22) {
            legendItem(String(localized: "Regions", bundle: .module), kind: .region) {
                ZStack {
                    Circle().stroke(ink.opacity(0.5), lineWidth: 0.6).frame(width: 12, height: 12)
                    Circle().fill(ink).frame(width: 5, height: 5)
                }
            }
            legendItem(String(localized: "Bottles", bundle: .module), kind: .bottle) {
                Circle().stroke(ink.opacity(0.9), lineWidth: 1).frame(width: 6, height: 6)
                    .frame(width: 12, height: 12)
            }
        }
        .accessibilityHidden(true)
    }

    private func legendItem(_ label: String, kind: ProgressMapPin.Kind, @ViewBuilder symbol: () -> some View) -> some View {
        HStack(spacing: 8) {
            symbol()
            Text(label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2)
        }
        .opacity(isShown(kind) ? 0.82 : 0.3)
    }

    private var accessibilityText: String {
        let regions = model.pins(.region).count
        let bottles = model.pins(.bottle).reduce(0) { $0 + $1.count }
        switch focus {
        case .region: return String(localized: "World map: \(regions) regions", bundle: .module)
        case .bottle: return String(localized: "World map: \(bottles) tasted wines", bundle: .module)
        case nil: return String(localized: "World map: \(regions) regions and \(bottles) tasted wines", bundle: .module)
        }
    }
}
