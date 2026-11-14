import DesignSystem
import SwiftUI

/// The world under the counts of Progress, drawn like the maps of By region: the plain shape of the coasts filled in
/// white, without the poles, the regions of finished courses as solid dots with a ring, the places of tasted wines as
/// small open rings. While the Regions or Bottles sheet is open only its pins stay.
///
/// A pinch zooms in where the fingers are and a drag then moves the map; a double tap zooms in, or back out. The pins
/// keep their size, so the ones crowded together come apart, and close in their names show beside them.
///
/// While a finger moves, the coastline already drawn is only scaled and moved, a cheap transform; it is drawn again,
/// sharp, when the gesture ends, or sooner when the drawing has been stretched too far.
struct ProgressWorldMap: View {
    var model: ProgressMapUIModel
    /// The kind the open sheet keeps; nil shows both.
    var focus: ProgressMapPin.Kind?

    /// What shows.
    @State private var zoom = MapZoom()
    /// What the coastline was last drawn at.
    @State private var drawnZoom = MapZoom()
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
    }

    private func map(in size: CGSize) -> some View {
        let projection = WorldProjection(box: atlas.box, size: size)
        return Color.clear
            .frame(width: size.width, height: size.height)
            .background(alignment: .topLeading) { coastline(in: size) }
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    pins(.bottle, projection: projection)
                    pins(.region, projection: projection)
                }
                .frame(width: size.width, height: size.height)
                .allowsHitTesting(false)
            }
            // In the empty South Pacific, where it covers no land.
            .overlay(alignment: .bottomLeading) { wholeWorldButton.padding(.leading, 10).padding(.bottom, 4) }
            .contentShape(Rectangle())
            .simultaneousGesture(pinch(in: size))
            // Only a zoomed map takes a drag, ahead of the page's scroll: at full size the drag scrolls the page.
            .highPriorityGesture(drag(in: size), including: zoom.scale > 1 ? .all : .subviews)
            .onTapGesture(count: 2, coordinateSpace: .local) { location in
                move(to: zoom.scale > 1 ? MapZoom() : zoom.zoomed(to: Self.doubleTapScale, at: location, in: size))
            }
            .accessibilityZoomAction { action in
                let middle = CGPoint(x: size.width / 2, y: size.height / 2)
                let scale = action.direction == .zoomIn ? zoom.scale * 2 : zoom.scale / 2
                move(to: zoom.zoomed(to: scale, at: middle, in: size))
            }
    }

    private func isShown(_ kind: ProgressMapPin.Kind) -> Bool { focus == nil || focus == kind }

    // MARK: Zooming

    /// An animated jump (double tap, Whole world), with the coastline drawn sharp where it ends.
    private func move(to target: MapZoom) {
        // Zooming out, the coastline is drawn for the end first: scaled up, it still covers the start.
        if target.scale < zoom.scale { drawnZoom = target }
        withAnimation(.smooth(duration: 0.45)) {
            zoom = target
        } completion: {
            drawnZoom = zoom
        }
    }

    private func pinch(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? zoom
                if pinchStart == nil { pinchStart = zoom }
                zoom = start.zoomed(to: start.scale * value.magnification, at: value.startLocation, in: size)
                redrawIfStretched(in: size)
            }
            .onEnded { _ in
                pinchStart = nil
                drawnZoom = zoom
            }
    }

    private func drag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                // Two fingers pinching also drag; the pinch alone moves the map then.
                guard pinchStart == nil else { return }
                let start = dragStart ?? zoom
                if dragStart == nil { dragStart = zoom }
                zoom = start.moved(by: value.translation, in: size)
                redrawIfStretched(in: size)
            }
            .onEnded { _ in
                dragStart = nil
                drawnZoom = zoom
            }
    }

    /// The drawing scaled past what still looks sharp, or moved past the land drawn around the frame, is drawn again.
    private func redrawIfStretched(in size: CGSize) {
        let ratio = zoom.scale / drawnZoom.scale
        let shift = coastlineShift(ratio: ratio)
        let covers = -ratio * size.width + shift.width <= 0 && 2 * ratio * size.width + shift.width >= size.width
            && -ratio * size.height + shift.height <= 0 && 2 * ratio * size.height + shift.height >= size.height
        if !covers || ratio < 0.75 || ratio > 1.5 { drawnZoom = zoom }
    }

    /// Where the coastline drawn at `drawnZoom` moves to show `zoom`, once scaled by `ratio`.
    private func coastlineShift(ratio: CGFloat) -> CGSize {
        CGSize(width: zoom.offset.width - ratio * drawnZoom.offset.width,
               height: zoom.offset.height - ratio * drawnZoom.offset.height)
    }

    // MARK: Land

    /// The coastline drawn at `drawnZoom` with a frame of land around it on every side, scaled and moved to `zoom`.
    private func coastline(in size: CGSize) -> some View {
        let ratio = zoom.scale / drawnZoom.scale
        let shift = coastlineShift(ratio: ratio)
        return WorldCoastline(size: size, zoom: drawnZoom)
            .equatable()
            .frame(width: size.width * 3, height: size.height * 3)
            .scaleEffect(ratio, anchor: UnitPoint(x: 1.0 / 3, y: 1.0 / 3))
            .offset(x: -size.width + shift.width, y: -size.height + shift.height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: Pins

    private func pins(_ kind: ProgressMapPin.Kind, projection: WorldProjection) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.pins(kind)) { pin in
                pinView(pin)
                    .position(zoom.apply(projection.point(lon: pin.lon, lat: pin.lat)))
            }
        }
        .opacity(isShown(kind) ? 1 : 0)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func pinView(_ pin: ProgressMapPin) -> some View {
        switch pin.kind {
        case .region:
            // A finished region: a solid dot inside a thin ring, the dot of the open region in By region.
            ZStack {
                Circle().stroke(ink.opacity(0.5), lineWidth: 0.6)
                Circle().fill(ink).frame(width: 5, height: 5)
            }
            .frame(width: 12, height: 12)
            .overlay(alignment: .leading) { label(pin.name).offset(x: 15) }
        case .bottle:
            // A place of tasted wines: an open ring, a little wider when several wines come from there.
            let diameter = Self.bottleRadius(count: pin.count) * 2
            Circle()
                .fill(UVVAColor.night.opacity(0.35))
                .overlay(Circle().stroke(ink.opacity(0.9), lineWidth: 1))
                .frame(width: diameter, height: diameter)
                .overlay(alignment: .leading) {
                    label(pin.count > 1 ? "\(pin.name) · \(pin.count)" : pin.name).offset(x: diameter + 5)
                }
        }
    }

    /// The pin's name to its right, fading in as the map closes in.
    private func label(_ name: String) -> some View {
        Text(name)
            .font(UVVAFont.sans(10)).tracking(0.4)
            .foregroundStyle(ink.opacity(0.9))
            .lineLimit(1)
            .fixedSize()
            .opacity(min(max((zoom.scale - Self.labelScale + 0.5) / 0.5, 0), 1))
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
            Spacer(minLength: 8)
            Text(String(localized: "Pinch to zoom", bundle: .module).uppercased())
                .font(UVVAFont.sans(8)).tracking(1.6)
                .lineLimit(1)
                .fixedSize()
                .opacity(zoom.scale > 1 ? 0 : 0.5)
                .accessibilityHidden(true)
        }
    }

    /// Zoomed in, a way back to the whole world.
    @ViewBuilder
    private var wholeWorldButton: some View {
        if zoom.scale > 1 {
            Button { move(to: MapZoom()) } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 30, height: 30)
                    .background(UVVAColor.night.opacity(0.35), in: Circle())
                    .overlay(Circle().strokeBorder(ink.opacity(0.3), lineWidth: 0.6))
                    .frame(width: 44, height: 44, alignment: .bottomLeading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Whole world", bundle: .module))
            .transition(.opacity)
        }
    }

    private func legendItem(_ label: String, kind: ProgressMapPin.Kind, @ViewBuilder symbol: () -> some View) -> some View {
        HStack(spacing: 8) {
            symbol()
            Text(label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2)
                .lineLimit(1)
                .fixedSize()
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

/// The land at one zoom, with a frame of land drawn around the map on every side, so the drawing still fills the map
/// when a pinch scales it down a little or a drag moves it. Drawn only when its size or zoom changes.
private struct WorldCoastline: View, Equatable {
    var size: CGSize
    var zoom: MapZoom

    /// The land projected once, onto a map 1 point wide.
    private static let unitPath: CGPath = {
        let atlas = WorldAtlas.shared
        let aspect = WorldProjection.aspectRatio(box: atlas.box)
        return WorldProjection(box: atlas.box, size: CGSize(width: 1, height: 1 / aspect)).path(atlas.land)
    }()

    var body: some View {
        Canvas { context, _ in
            let place = CGAffineTransform(scaleX: size.width, y: size.width)
                .concatenating(zoom.transform)
                .concatenating(CGAffineTransform(translationX: size.width, y: size.height))
            let path = Path(Self.unitPath).applying(place)
            let ink = UVVAColor.creamFill
            context.fill(path, with: .color(ink.opacity(0.1)), style: FillStyle(eoFill: true))
            context.stroke(path, with: .color(ink.opacity(0.5)), lineWidth: 0.6)
        }
    }
}

/// How far in the world map is and which part of it shows: points of the map at full size are scaled by `scale`, then
/// moved by `offset`. The map always covers its frame.
struct MapZoom: Equatable {
    /// Past this the plain coastline grows too coarse.
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
