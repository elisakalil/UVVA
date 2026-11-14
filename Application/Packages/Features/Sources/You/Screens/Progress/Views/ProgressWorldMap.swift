import DesignSystem
import SwiftUI
import UIKit

/// The world under the counts of Progress, drawn like the maps of By region: the plain shape of the coasts filled in
/// white, without the poles, the regions of finished courses as solid dots with a ring, the places of tasted wines as
/// small white dots. While the Regions or Bottles sheet is open only its pins stay.
///
/// The map fills the height of its frame, so the world runs past its sides: a sideways drag moves along it, and it
/// glides on when the finger lets go. A pinch zooms in where the fingers are; zoomed in, a drag moves the map any way.
/// A double tap zooms in, or back home. The pins keep their size, and close in their names show beside them.
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
    /// The frame the map was placed home in, and where home is in it.
    @State private var placedFrame: CGSize?
    @State private var home = MapZoom()
    /// The zoom a pinch started from, and where its fingers were.
    @State private var pinchStart: (zoom: MapZoom, location: CGPoint)?
    /// How far the drag had gone at its last step: the map moves by each step, so a pinch in the middle of a drag
    /// does not make it jump.
    @State private var lastDrag: CGSize?

    private let atlas = WorldAtlas.shared
    private let ink = UVVAColor.creamFill

    /// Width over height of the map's frame: taller than the world, which runs past the sides.
    static let frameAspect: CGFloat = 1.6
    /// Past this the names show beside the pins.
    static let labelScale: CGFloat = 2.5
    static let doubleTapScale: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Color.clear
                .aspectRatio(Self.frameAspect, contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        map(in: geometry.size)
                    }
                }
                .clipped()
                .accessibilityElement()
                .accessibilityLabel(Text(accessibilityText))
                .accessibilityHint(Text("Drag to move along the map, pinch to zoom", bundle: .module))
            legend
        }
        .animation(.easeInOut(duration: 0.35), value: focus)
    }

    /// The world at full size: as tall as the frame.
    private func content(for frame: CGSize) -> CGSize {
        CGSize(width: frame.height * WorldProjection.aspectRatio(box: atlas.box), height: frame.height)
    }

    private func map(in frame: CGSize) -> some View {
        let content = content(for: frame)
        let projection = WorldProjection(box: atlas.box, size: content)
        let home = MapZoom.home(frame: frame, content: content)
        return Color.clear
            .frame(width: frame.width, height: frame.height)
            .background(alignment: .topLeading) { coastline(frame: frame, content: content) }
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    pins(.bottle, projection: projection)
                    pins(.region, projection: projection)
                }
                .frame(width: frame.width, height: frame.height)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(MapPan(takesVerticalDrags: content.height * zoom.scale > frame.height + 0.5,
                            changed: { dragChanged($0, frame: frame, content: content) },
                            ended: { dragEnded($0, velocity: $1, frame: frame, content: content) }))
            .gesture(MapPinch(changed: { pinchChanged(scale: $0, location: $1, frame: frame, content: content) },
                              ended: pinchEnded))
            .onTapGesture(count: 2, coordinateSpace: .local) { location in
                move(to: zoom.scale > 1 ? home
                     : zoom.zoomed(to: Self.doubleTapScale, at: location, frame: frame, content: content))
            }
            .accessibilityZoomAction { action in
                let middle = CGPoint(x: frame.width / 2, y: frame.height / 2)
                let scale = action.direction == .zoomIn ? zoom.scale * 2 : zoom.scale / 2
                move(to: zoom.zoomed(to: scale, at: middle, frame: frame, content: content))
            }
            .onAppear { place(home, in: frame) }
            .onChange(of: Self.settled(frame)) { _, _ in
                place(MapZoom.home(frame: frame, content: self.content(for: frame)), in: frame)
            }
    }

    private func isShown(_ kind: ProgressMapPin.Kind) -> Bool { focus == nil || focus == kind }

    /// A size to half a point: layout hands the frame back a hair different now and then (310 and 310.00000000000006),
    /// which must not count as a new size and send the map home in the middle of a drag.
    static func settled(_ size: CGSize) -> CGSize {
        CGSize(width: (size.width * 2).rounded() / 2, height: (size.height * 2).rounded() / 2)
    }

    /// The world at full height, with its middle in the middle of the frame, when the map gets a new size.
    private func place(_ home: MapZoom, in frame: CGSize) {
        guard placedFrame != Self.settled(frame) else { return }
        placedFrame = Self.settled(frame)
        self.home = home
        zoom = home
        drawnZoom = home
    }

    // MARK: Moving

    /// An animated move (double tap, home, the glide after a drag), with the coastline drawn sharp where it ends.
    private func move(to target: MapZoom, duration: Double = 0.45) {
        // Zooming out, the coastline is drawn for the end first: scaled up, it still covers the start.
        if target.scale < zoom.scale { drawnZoom = target }
        withAnimation(.smooth(duration: duration)) {
            zoom = target
        } completion: {
            drawnZoom = zoom
        }
    }

    private func dragChanged(_ translation: CGSize, frame: CGSize, content: CGSize) {
        let step = CGSize(width: translation.width - (lastDrag?.width ?? 0),
                          height: translation.height - (lastDrag?.height ?? 0))
        lastDrag = translation
        // While two fingers pinch, the pinch moves the map.
        guard pinchStart == nil else { return }
        zoom = zoom.moved(by: step, frame: frame, content: content)
        redrawIfStretched(frame: frame)
    }

    /// The map glides on in the direction it was thrown, slowing to a stop, at most half a frame further.
    private func dragEnded(_ translation: CGSize, velocity: CGSize, frame: CGSize, content: CGSize) {
        lastDrag = nil
        guard pinchStart == nil else { return }
        drawnZoom = zoom
        // Only on along the way the finger went: a speed read the other way at the lift is left out.
        func glide(_ speed: CGFloat, along moved: CGFloat, limit: CGFloat) -> CGFloat {
            guard speed * moved > 0 else { return 0 }
            return max(-limit, min(limit, speed * 0.15))
        }
        let glide = CGSize(width: glide(velocity.width, along: translation.width, limit: frame.width / 2),
                           height: glide(velocity.height, along: translation.height, limit: frame.height / 2))
        let end = zoom.moved(by: glide, frame: frame, content: content)
        if end != zoom { move(to: end, duration: 0.6) }
    }

    /// Zooms in where the fingers started, and follows them as they move together.
    private func pinchChanged(scale: CGFloat, location: CGPoint, frame: CGSize, content: CGSize) {
        let start = pinchStart ?? (zoom, location)
        if pinchStart == nil { pinchStart = start }
        zoom = start.zoom
            .zoomed(to: start.zoom.scale * scale, at: start.location, frame: frame, content: content)
            .moved(by: CGSize(width: location.x - start.location.x, height: location.y - start.location.y),
                   frame: frame, content: content)
        redrawIfStretched(frame: frame)
    }

    private func pinchEnded() {
        pinchStart = nil
        drawnZoom = zoom
    }

    /// The drawing scaled past what still looks sharp, or moved past the land drawn around the frame, is drawn again.
    private func redrawIfStretched(frame: CGSize) {
        let ratio = zoom.scale / drawnZoom.scale
        let shift = coastlineShift(ratio: ratio)
        let covers = -ratio * frame.width + shift.width <= 0 && 2 * ratio * frame.width + shift.width >= frame.width
            && -ratio * frame.height + shift.height <= 0 && 2 * ratio * frame.height + shift.height >= frame.height
        if !covers || ratio < 0.75 || ratio > 1.5 { drawnZoom = zoom }
    }

    /// Where the coastline drawn at `drawnZoom` moves to show `zoom`, once scaled by `ratio`.
    private func coastlineShift(ratio: CGFloat) -> CGSize {
        CGSize(width: zoom.offset.width - ratio * drawnZoom.offset.width,
               height: zoom.offset.height - ratio * drawnZoom.offset.height)
    }

    // MARK: Land

    /// The coastline drawn at `drawnZoom` with a frame of land around it on every side, scaled and moved to `zoom`.
    private func coastline(frame: CGSize, content: CGSize) -> some View {
        let ratio = zoom.scale / drawnZoom.scale
        let shift = coastlineShift(ratio: ratio)
        return WorldCoastline(frame: frame, contentWidth: content.width, zoom: drawnZoom)
            .equatable()
            .frame(width: frame.width * 3, height: frame.height * 3)
            .scaleEffect(ratio, anchor: UnitPoint(x: 1.0 / 3, y: 1.0 / 3))
            .offset(x: -frame.width + shift.width, y: -frame.height + shift.height)
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
            // A place of tasted wines: a small white dot, a little wider when several wines come from there.
            let diameter = Self.bottleDiameter(count: pin.count)
            Circle()
                .fill(ink)
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

    static func bottleDiameter(count: Int) -> CGFloat { min(5 + CGFloat(count - 1), 8) }

    // MARK: Legend

    private var legend: some View {
        HStack(spacing: 22) {
            legendItem(String(localized: "Bottles", bundle: .module), kind: .bottle) {
                Circle().fill(ink).frame(width: 5, height: 5)
                    .frame(width: 12, height: 12)
            }
            Spacer(minLength: 8)
            homeControl
        }
        // The legend keeps its height whether the hint or the button shows.
        .frame(minHeight: 44)
    }

    /// At home, how to move the map; away from it, the way back, beside the legend and over no land.
    @ViewBuilder
    private var homeControl: some View {
        if zoom != home {
            Button { move(to: home) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward").font(.system(size: 9, weight: .medium))
                    Text(String(localized: "Reset", bundle: .module).uppercased()).font(UVVAFont.sans(8)).tracking(1.6)
                }
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(0.82)
            .accessibilityLabel(Text("Reset the map", bundle: .module))
        } else {
            Text(String(localized: "Drag · pinch", bundle: .module).uppercased())
                .font(UVVAFont.sans(8)).tracking(1.6)
                .lineLimit(1)
                .fixedSize()
                .opacity(0.5)
                .accessibilityHidden(true)
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

/// A one-finger drag on the map, from UIKit so it settles at once with the page's scroll: it takes sideways drags
/// and leaves the rest to the page, unless the map is zoomed in enough to move up and down too. The scroll waits for
/// it to decline.
private struct MapPan: UIGestureRecognizerRepresentable {
    var takesVerticalDrags: Bool
    var changed: (CGSize) -> Void
    /// The whole translation and the speed, in points a second, when the finger lets go.
    var ended: (CGSize, CGSize) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.takesVerticalDrags = takesVerticalDrags
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view)
        let moved = CGSize(width: translation.x, height: translation.y)
        switch recognizer.state {
        case .began, .changed:
            changed(moved)
        case .ended:
            let velocity = recognizer.velocity(in: recognizer.view)
            ended(moved, CGSize(width: velocity.x, height: velocity.y))
        case .cancelled, .failed:
            ended(moved, .zero)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var takesVerticalDrags = false

        /// Sideways or not is read from how far the finger has gone: at the start of a slow drag its speed is
        /// next to nothing either way.
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            if takesVerticalDrags { return true }
            let moved = pan.translation(in: pan.view)
            let direction = moved == .zero ? pan.velocity(in: pan.view) : moved
            return abs(direction.x) > abs(direction.y)
        }

        /// The map's pinch runs with it.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            other is UIPinchGestureRecognizer
        }

        /// The page's scroll starts only once this drag has declined.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            other is UIPanGestureRecognizer && other.view is UIScrollView
        }
    }
}

/// A two-finger pinch on the map, from UIKit like its drag, so the two run together.
private struct MapPinch: UIGestureRecognizerRepresentable {
    /// The scale since the fingers came down, and where they are now.
    var changed: (CGFloat, CGPoint) -> Void
    var ended: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
        let pinch = UIPinchGestureRecognizer()
        pinch.delegate = context.coordinator
        return pinch
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed:
            // With a finger lifted the middle of the fingers jumps; the pinch waits for both.
            guard recognizer.numberOfTouches == 2 else { return }
            changed(recognizer.scale, recognizer.location(in: recognizer.view))
        case .ended, .cancelled, .failed:
            ended()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            other is UIPanGestureRecognizer && !(other.view is UIScrollView)
        }
    }
}

/// The land at one zoom, with a frame of land drawn around the map on every side, so the drawing still fills the map
/// when a pinch scales it down a little or a drag moves it. Drawn only when its size or zoom changes.
private struct WorldCoastline: View, Equatable {
    var frame: CGSize
    /// The world's width at full size.
    var contentWidth: CGFloat
    var zoom: MapZoom

    /// The land projected once, onto a map 1 point wide.
    private static let unitPath: CGPath = {
        let atlas = WorldAtlas.shared
        let aspect = WorldProjection.aspectRatio(box: atlas.box)
        return WorldProjection(box: atlas.box, size: CGSize(width: 1, height: 1 / aspect)).path(atlas.land)
    }()

    var body: some View {
        Canvas { context, _ in
            let place = CGAffineTransform(scaleX: contentWidth, y: contentWidth)
                .concatenating(zoom.transform)
                .concatenating(CGAffineTransform(translationX: frame.width, y: frame.height))
            let path = Path(Self.unitPath).applying(place)
            let ink = UVVAColor.creamFill
            context.fill(path, with: .color(ink.opacity(0.1)), style: FillStyle(eoFill: true))
            context.stroke(path, with: .color(ink.opacity(0.5)), lineWidth: 0.6)
        }
    }
}

/// How far in the world map is and which part of it shows: points of the world at full size (`content`) are scaled by
/// `scale`, then moved by `offset`, into the map's `frame`. Along a side where the world is longer than the frame no
/// edge of it comes inside; along one where it is shorter, it stays in the middle.
struct MapZoom: Equatable {
    /// Past this the plain coastline grows too coarse.
    static let maxScale: CGFloat = 6

    var scale: CGFloat = 1
    var offset: CGSize = .zero

    /// The world at full size, its middle in the middle of the frame.
    static func home(frame: CGSize, content: CGSize) -> MapZoom {
        MapZoom(scale: 1, offset: CGSize(width: (frame.width - content.width) / 2,
                                         height: (frame.height - content.height) / 2))
            .clamped(frame: frame, content: content)
    }

    /// Small enough to show the whole world in the frame.
    static func minScale(frame: CGSize, content: CGSize) -> CGFloat {
        min(1, frame.width / content.width, frame.height / content.height)
    }

    var transform: CGAffineTransform {
        CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: offset.width, ty: offset.height)
    }

    func apply(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale + offset.width, y: point.y * scale + offset.height)
    }

    /// At `scale`, with the point under `anchor` kept where it is.
    func zoomed(to scale: CGFloat, at anchor: CGPoint, frame: CGSize, content: CGSize) -> MapZoom {
        let scale = min(max(scale, Self.minScale(frame: frame, content: content)), Self.maxScale)
        let ratio = scale / self.scale
        return MapZoom(scale: scale,
                       offset: CGSize(width: anchor.x - (anchor.x - offset.width) * ratio,
                                      height: anchor.y - (anchor.y - offset.height) * ratio))
            .clamped(frame: frame, content: content)
    }

    func moved(by translation: CGSize, frame: CGSize, content: CGSize) -> MapZoom {
        MapZoom(scale: scale, offset: CGSize(width: offset.width + translation.width,
                                             height: offset.height + translation.height))
            .clamped(frame: frame, content: content)
    }

    func clamped(frame: CGSize, content: CGSize) -> MapZoom {
        func axis(_ offset: CGFloat, frame: CGFloat, content: CGFloat) -> CGFloat {
            let length = content * scale
            return length >= frame ? min(0, max(frame - length, offset)) : (frame - length) / 2
        }
        return MapZoom(scale: scale,
                       offset: CGSize(width: axis(offset.width, frame: frame.width, content: content.width),
                                      height: axis(offset.height, frame: frame.height, content: content.height)))
    }
}
