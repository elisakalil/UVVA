import DesignSystem
import SwiftUI

/// The world under the counts of Progress, drawn like the maps of By region: whole coastlines filled in white, without
/// the poles, the regions of finished courses as solid dots with a ring, the places of tasted wines as small open
/// rings. While the Regions or Bottles sheet is open only its pins stay.
///
/// A pinch zooms in where the fingers are and a drag then moves the map; a double tap zooms in, or back out. The pins
/// keep their size, so the ones crowded together come apart, and close in their names show beside them.
struct ProgressWorldMap: View {
    var model: ProgressMapUIModel
    /// The kind the open sheet keeps; nil shows both.
    var focus: ProgressMapPin.Kind?

    @State private var zoom = MapZoom()
    /// The zoom a pinch or a drag started from.
    @State private var pinchStart: MapZoom?
    @State private var dragStart: MapZoom?

    private let atlas = WorldAtlas.shared
    private let ink = UVVAColor.creamFill

    /// Past this the names show beside the pins.
    static let labelScale: CGFloat = 2.5
    static let doubleTapScale: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Color.clear
                .aspectRatio(WorldProjection.aspectRatio(box: atlas.box), contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        map(in: geometry.size)
                    }
                }
                .clipped()
                .accessibilityElement()
                .accessibilityLabel(Text(accessibilityText))
                .accessibilityHint(Text("Pinch to zoom", bundle: .module))
            legend
                .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.35), value: focus)
        .animation(.easeInOut(duration: 0.35), value: model)
    }

    private func map(in size: CGSize) -> some View {
        let projection = WorldProjection(box: atlas.box, size: size)
        let zoom = zoom
        return ZStack {
            land(projection, zoom: zoom)
            bottles(projection, zoom: zoom)
                .opacity(isShown(.bottle) ? 1 : 0)
            regions(projection, zoom: zoom)
                .opacity(isShown(.region) ? 1 : 0)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .simultaneousGesture(pinch(in: size))
        // Only a zoomed map takes a drag, ahead of the page's scroll: at full size the drag scrolls the page.
        .highPriorityGesture(drag(in: size), including: zoom.scale > 1 ? .all : .subviews)
        .onTapGesture(count: 2, coordinateSpace: .local) { location in
            withAnimation(.smooth(duration: 0.45)) {
                self.zoom = zoom.scale > 1 ? MapZoom()
                    : zoom.zoomed(to: Self.doubleTapScale, at: location, in: size)
            }
        }
        .accessibilityZoomAction { action in
            let middle = CGPoint(x: size.width / 2, y: size.height / 2)
            let scale = action.direction == .zoomIn ? zoom.scale * 2 : zoom.scale / 2
            withAnimation(.smooth(duration: 0.35)) { self.zoom = zoom.zoomed(to: scale, at: middle, in: size) }
        }
    }

    private func isShown(_ kind: ProgressMapPin.Kind) -> Bool { focus == nil || focus == kind }

    // MARK: Gestures

    private func pinch(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? zoom
                if pinchStart == nil { pinchStart = zoom }
                zoom = start.zoomed(to: start.scale * value.magnification, at: value.startLocation, in: size)
            }
            .onEnded { _ in pinchStart = nil }
    }

    private func drag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                // Two fingers pinching also drag; the pinch alone moves the map then.
                guard pinchStart == nil else { return }
                let start = dragStart ?? zoom
                if dragStart == nil { dragStart = zoom }
                zoom = start.moved(by: value.translation, in: size)
            }
            .onEnded { _ in dragStart = nil }
    }

    // MARK: Land

    /// The coastlines and a faint white fill, every shape whole inside the frame.
    private func land(_ projection: WorldProjection, zoom: MapZoom) -> some View {
        Canvas { context, _ in
            let path = Path(projection.path(atlas.land)).applying(zoom.transform)
            context.fill(path, with: .color(ink.opacity(0.1)), style: FillStyle(eoFill: true))
            context.stroke(path, with: .color(ink.opacity(0.45)), lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }

    // MARK: Pins

    /// A finished region: a solid dot inside a thin ring, the dot of the open region in By region.
    private func regions(_ projection: WorldProjection, zoom: MapZoom) -> some View {
        Canvas { context, _ in
            for pin in model.pins(.region) {
                let p = zoom.apply(projection.point(lon: pin.lon, lat: pin.lat))
                context.stroke(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)),
                               with: .color(ink.opacity(0.5)), lineWidth: 0.6)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)),
                             with: .color(ink))
                label(pin.name, at: p, gap: 9, zoom: zoom, in: &context)
            }
        }
        .accessibilityHidden(true)
    }

    /// A place of tasted wines: an open ring, a little wider when several wines come from there.
    private func bottles(_ projection: WorldProjection, zoom: MapZoom) -> some View {
        Canvas { context, _ in
            for pin in model.pins(.bottle) {
                let p = zoom.apply(projection.point(lon: pin.lon, lat: pin.lat))
                let radius = Self.bottleRadius(count: pin.count)
                let ring = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                context.fill(ring, with: .color(UVVAColor.night.opacity(0.35)))
                context.stroke(ring, with: .color(ink.opacity(0.9)), lineWidth: 1)
                label(pin.count > 1 ? "\(pin.name) · \(pin.count)" : pin.name, at: p, gap: radius + 5, zoom: zoom,
                      in: &context)
            }
        }
        .accessibilityHidden(true)
    }

    /// The pin's name to its right, fading in as the map closes in.
    private func label(_ name: String, at point: CGPoint, gap: CGFloat, zoom: MapZoom,
                       in context: inout GraphicsContext) {
        let opacity = min(max((zoom.scale - Self.labelScale + 0.5) / 0.5, 0), 1)
        guard opacity > 0 else { return }
        var faded = context
        faded.opacity = opacity
        faded.draw(Text(name).font(UVVAFont.sans(10)).tracking(0.4).foregroundStyle(ink.opacity(0.9)),
                   at: CGPoint(x: point.x + gap, y: point.y), anchor: .leading)
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
            Spacer(minLength: 0)
            zoomHint
        }
    }

    /// "Pinch to zoom" at full size; zoomed in, a way back to the whole world.
    @ViewBuilder
    private var zoomHint: some View {
        if zoom.scale > 1 {
            Button {
                withAnimation(.smooth(duration: 0.45)) { zoom = MapZoom() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left").font(.system(size: 9, weight: .medium))
                    Text(String(localized: "Whole world", bundle: .module).uppercased()).font(UVVAFont.sans(9)).tracking(2.2)
                }
                .lineLimit(1)
                .fixedSize()
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(0.82)
        } else {
            Text(String(localized: "Pinch to zoom", bundle: .module).uppercased())
                .font(UVVAFont.sans(9)).tracking(2.2).opacity(0.5)
                .lineLimit(1)
                .fixedSize()
                .accessibilityHidden(true)
        }
    }

    private func legendItem(_ label: String, kind: ProgressMapPin.Kind, @ViewBuilder symbol: () -> some View) -> some View {
        HStack(spacing: 8) {
            symbol()
            Text(label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2)
        }
        .opacity(isShown(kind) ? 0.82 : 0.3)
        .accessibilityHidden(true)
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

/// How far in the world map is and which part of it shows: points of the map at full size are scaled by `scale`, then
/// moved by `offset`. The map always covers its frame.
struct MapZoom: Equatable {
    /// Past this the coastlines (1:110m) grow coarse.
    static let maxScale: CGFloat = 6

    var scale: CGFloat = 1
    var offset: CGSize = .zero

    var transform: CGAffineTransform {
        CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: offset.width, ty: offset.height)
    }

    func apply(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale + offset.width, y: point.y * scale + offset.height)
    }

    /// At `scale`, with the point under `anchor` kept where it is.
    func zoomed(to scale: CGFloat, at anchor: CGPoint, in size: CGSize) -> MapZoom {
        let scale = min(max(scale, 1), Self.maxScale)
        let ratio = scale / self.scale
        return MapZoom(scale: scale,
                       offset: CGSize(width: anchor.x - (anchor.x - offset.width) * ratio,
                                      height: anchor.y - (anchor.y - offset.height) * ratio))
            .clamped(to: size)
    }

    func moved(by translation: CGSize, in size: CGSize) -> MapZoom {
        MapZoom(scale: scale, offset: CGSize(width: offset.width + translation.width,
                                             height: offset.height + translation.height))
            .clamped(to: size)
    }

    /// No edge of the map comes inside the frame.
    func clamped(to size: CGSize) -> MapZoom {
        MapZoom(scale: scale,
                offset: CGSize(width: min(0, max(size.width * (1 - scale), offset.width)),
                               height: min(0, max(size.height * (1 - scale), offset.height))))
    }
}
