import DesignSystem
import SwiftUI
import UIKit

/// The world at the foot of Progress, drawn like the maps of By region: the plain shape of the coasts filled in
/// white, without the poles, the regions of finished courses as solid dots with a ring, and the places of tasted wines
/// as wine painted on the land: a wash of burgundy fading out from each place, faint for one bottle, deeper and wider
/// as the bottles from there add up, washes that meet deepening too. While the Regions or Bottles sheet is open only
/// its pins stay. A tap on a place opens the sheet of its wines.
///
/// The map opens as far out as it goes, the whole world in its frame, and Reset brings it back there. A pinch zooms in
/// where the fingers are; zoomed in, a drag moves the map any way and it glides on when the finger lets go. Each
/// double tap zooms in a step, and at the deepest goes back home. The pins keep their size, and close in their names
/// show beside them. Zoomed in, a drag up or down past the map's edge scrolls the page.
///
/// While a finger moves, the coastline already drawn is only scaled and moved, a cheap transform; it is drawn again,
/// sharp, when the gesture ends, or sooner when the drawing has been stretched too far.
struct ProgressWorldMap: View {
    var model: ProgressMapUIModel
    /// The kind the open sheet keeps; nil shows both.
    var focus: ProgressMapPin.Kind?
    /// A place of tasted wines was tapped: the sheet with its wines.
    var onSelectPlace: (ProgressMapPin) -> Void = { _ in }
    /// In the page, a still preview: one tap opens it full screen, where it moves (nil keeps it moving in place).
    var onExpand: (() -> Void)?
    /// Full screen: the map takes the whole frame it is given and fills it, the legend over its foot.
    var fillsScreen = false

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

    /// Width over height of the map's frame: the world's own, so at its farthest the whole world fills the frame.
    static let frameAspect = CGFloat(WorldProjection.aspectRatio(box: WorldAtlas.shared.box))
    /// Past this the names show beside the pins.
    static let labelScale: CGFloat = 2.5
    static let doubleTapStep: CGFloat = 2

    var body: some View {
        Group {
            if fillsScreen {
                mapFrame
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        legend
                            .padding(.horizontal, 26)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial.opacity(0.6), in: Capsule())
                            .environment(\.colorScheme, .dark)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    mapFrame.aspectRatio(Self.frameAspect, contentMode: .fit)
                    legend
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: focus)
    }

    private var mapFrame: some View {
        Color.clear
            .overlay {
                GeometryReader { geometry in
                    map(in: geometry.size)
                }
            }
            .clipped()
            .accessibilityElement()
            .accessibilityLabel(Text(accessibilityText))
            .accessibilityHint(onExpand == nil
                ? Text("Pinch to zoom, tap a place to see its wines", bundle: .module)
                : Text("Opens the map full screen", bundle: .module))
            .accessibilityAddTraits(onExpand == nil ? [] : .isButton)
            .accessibilityAction { onExpand?() }
    }

    /// The world at full size: as tall as the frame.
    private func content(for frame: CGSize) -> CGSize {
        CGSize(width: frame.height * WorldProjection.aspectRatio(box: atlas.box), height: frame.height)
    }

    private func map(in frame: CGSize) -> some View {
        let content = content(for: frame)
        let projection = WorldProjection(box: atlas.box, size: content)
        let home = MapZoom.home(frame: frame, content: content, fills: fillsScreen)
        if let onExpand {
            // The preview: the world as it is, still, and a tap opens it full screen.
            return AnyView(Color.clear
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
                .onTapGesture(perform: onExpand)
                .onAppear { place(home, in: frame) }
                .onChange(of: Self.settled(frame)) { _, _ in
                    place(MapZoom.home(frame: frame, content: self.content(for: frame)), in: frame)
                })
        }
        return AnyView(Color.clear
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
                            canMoveDown: zoom.offset.height < -0.5,
                            canMoveUp: zoom.offset.height > frame.height - content.height * zoom.scale + 0.5,
                            changed: { dragChanged($0, frame: frame, content: content) },
                            ended: { dragEnded($0, velocity: $1, frame: frame, content: content) }))
            .gesture(MapPinch(changed: { pinchChanged(scale: $0, location: $1, frame: frame, content: content) },
                              ended: pinchEnded))
            .onTapGesture(count: 2, coordinateSpace: .local) { location in
                // Each double tap goes a step closer where it lands; at the deepest, back home.
                move(to: zoom.scale >= MapZoom.maxScale - 0.01 ? home
                     : zoom.zoomed(to: zoom.scale * Self.doubleTapStep, at: location, frame: frame, content: content))
            }
            .onTapGesture(count: 1, coordinateSpace: .local) { location in
                if let place = place(at: location, projection: projection) { onSelectPlace(place) }
            }
            .accessibilityZoomAction { action in
                let middle = CGPoint(x: frame.width / 2, y: frame.height / 2)
                let scale = action.direction == .zoomIn ? zoom.scale * 2 : zoom.scale / 2
                move(to: zoom.zoomed(to: scale, at: middle, frame: frame, content: content))
            }
            .onAppear { place(home, in: frame) }
            .onChange(of: Self.settled(frame)) { _, _ in
                place(MapZoom.home(frame: frame, content: self.content(for: frame), fills: fillsScreen), in: frame)
            })
    }

    private func isShown(_ kind: ProgressMapPin.Kind) -> Bool { focus == nil || focus == kind }

    /// The place of tasted wines nearest a tap, if the tap fell on its paint: within its core, and never less than a
    /// fingertip.
    private func place(at location: CGPoint, projection: WorldProjection) -> ProgressMapPin? {
        guard isShown(.bottle) else { return nil }
        let reach = pow(zoom.scale, 0.6)
        return model.pins(.bottle)
            .map { pin -> (pin: ProgressMapPin, distance: CGFloat, limit: CGFloat) in
                let at = zoom.apply(projection.point(lon: pin.lon, lat: pin.lat))
                let limit = max(22, Self.paintRadius(Self.heat(pin.count)) * reach * 0.6)
                return (pin, hypot(at.x - location.x, at.y - location.y), limit)
            }
            .filter { $0.distance <= $0.limit }
            .min { $0.distance < $1.distance }?
            .pin
    }

    /// A size to half a point: layout hands the frame back a hair different now and then (310 and 310.00000000000006),
    /// which must not count as a new size and send the map home in the middle of a drag.
    static func settled(_ size: CGSize) -> CGSize {
        CGSize(width: (size.width * 2).rounded() / 2, height: (size.height * 2).rounded() / 2)
    }

    /// The whole world in the frame, as far out as it goes, when the map gets a new size.
    private func place(_ home: MapZoom, in frame: CGSize) {
        guard placedFrame != Self.settled(frame) else { return }
        placedFrame = Self.settled(frame)
        self.home = home
        zoom = home
        drawnZoom = home
    }

    // MARK: Moving

    /// An animated move (double tap, home, the glide after a drag), with the coastline drawn sharp where it ends.
    private func move(to target: MapZoom, animation: Animation = .smooth(duration: 0.45)) {
        // Zooming out, the coastline is drawn for the end first: scaled up, it still covers the start.
        if target.scale < zoom.scale { drawnZoom = target }
        withAnimation(animation) {
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

    /// The map glides on in the direction it was thrown, slowing to a stop as a scroll view does, at most a frame
    /// further.
    private func dragEnded(_ translation: CGSize, velocity: CGSize, frame: CGSize, content: CGSize) {
        lastDrag = nil
        guard pinchStart == nil else { return }
        drawnZoom = zoom
        // Only on along the way the finger went: a speed read the other way at the lift is left out.
        func glide(_ speed: CGFloat, along moved: CGFloat, limit: CGFloat) -> CGFloat {
            guard speed * moved > 0 else { return 0 }
            return max(-limit, min(limit, speed * 0.3))
        }
        let glide = CGSize(width: glide(velocity.width, along: translation.width, limit: frame.width),
                           height: glide(velocity.height, along: translation.height, limit: frame.height))
        let end = zoom.moved(by: glide, frame: frame, content: content)
        if end != zoom { move(to: end, animation: .timingCurve(0.15, 0.85, 0.3, 1, duration: 0.9)) }
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
        return ZStack {
            WorldCoastline(frame: frame, contentWidth: content.width, zoom: drawnZoom)
                .equatable()
            WorldHeat(frame: frame, contentWidth: content.width, zoom: drawnZoom, places: model.pins(.bottle))
                .equatable()
                .opacity(isShown(.bottle) ? 1 : 0)
        }
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
            // The place is painted on the land (`WorldHeat`); here only its name, beside it.
            Color.clear
                .frame(width: 1, height: 1)
                .overlay(alignment: .leading) {
                    label(pin.count > 1 ? "\(pin.name) · \(pin.count)" : pin.name)
                        .offset(x: 6)
                }
        }
    }

    // MARK: Heat

    /// From this many bottles a place is at its hottest.
    static let hottest = 8

    /// 0 for one bottle, 1 from `hottest`, rising fast at first: the second bottle from a place shows.
    static func heat(_ count: Int) -> Double {
        guard count > 1 else { return 0 }
        return min(log2(Double(count)) / log2(Double(hottest)), 1)
    }

    /// One tone, the wine of the lessons: faint for one bottle, deep from `hottest`.
    static let heatTone = UVVAColor.burgundy

    /// How strong the wine is at the place itself.
    static func heatOpacity(_ heat: Double) -> Double { 0.68 + 0.32 * heat }

    /// How far a place's paint reaches on the land, at home: wider as it heats up, from about a country to about
    /// a region of countries.
    static func paintRadius(_ heat: Double) -> CGFloat { 22 + 24 * heat }

    /// The pin's name to its right, fading in as the map closes in.
    private func label(_ name: String) -> some View {
        Text(name)
            .font(UVVAFont.sans(10)).tracking(0.4)
            .foregroundStyle(ink.opacity(0.9))
            .lineLimit(1)
            .fixedSize()
            .opacity(min(max((zoom.scale - Self.labelScale + 0.5) / 0.5, 0), 1))
    }

    // MARK: Legend

    private var legend: some View {
        HStack(spacing: 22) {
            legendItem(String(localized: "Bottles", bundle: .module), kind: .bottle) {
                heatScale
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
        if let onExpand {
            // The preview's way in: the map full screen.
            Button(action: onExpand) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 9, weight: .medium))
                    Text(String(localized: "Open", bundle: .module).uppercased()).font(UVVAFont.sans(8)).tracking(1.6)
                }
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(0.82)
            .accessibilityHidden(true)
        } else if zoom != home {
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
            Text(String(localized: "Pinch · tap", bundle: .module).uppercased())
                .font(UVVAFont.sans(8)).tracking(1.6)
                .lineLimit(1)
                .fixedSize()
                .opacity(0.5)
                .accessibilityHidden(true)
        }
    }

    /// "1 ━━ 8+": the wine from one bottle to the deepest, after "Bottles".
    private var heatScale: some View {
        HStack(spacing: 6) {
            Text(verbatim: "1")
            Capsule()
                .fill(LinearGradient(colors: [Self.heatTone.opacity(Self.heatOpacity(0)),
                                              Self.heatTone.opacity(Self.heatOpacity(1))],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 38, height: 4)
            Text(verbatim: "\(Self.hottest)+")
        }
        .font(UVVAFont.sans(9)).monospacedDigit()
    }

    private func legendItem(_ label: String, kind: ProgressMapPin.Kind, @ViewBuilder symbol: () -> some View) -> some View {
        HStack(spacing: 10) {
            Text(label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2)
                .lineLimit(1)
                .fixedSize()
            symbol()
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
    /// Room left to drag the map down (its top is above the frame) and up (its bottom is below it): at an edge, a
    /// drag further that way goes to the page, so the page never gets stuck under a zoomed map.
    var canMoveDown: Bool
    var canMoveUp: Bool
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
        context.coordinator.canMoveDown = canMoveDown
        context.coordinator.canMoveUp = canMoveUp
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
        var canMoveDown = false
        var canMoveUp = false

        /// Sideways or not is read from how far the finger has gone: at the start of a slow drag its speed is
        /// next to nothing either way. A drag mostly up or down is the map's only while the map can still go that way.
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let moved = pan.translation(in: pan.view)
            let direction = moved == .zero ? pan.velocity(in: pan.view) : moved
            if abs(direction.x) > abs(direction.y) { return true }
            guard takesVerticalDrags else { return false }
            return direction.y > 0 ? canMoveDown : canMoveUp
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
            // Where the fingers are on the map itself: the recognizer's own view is not the map's frame, and read
            // there the zoom went to some other part of the world.
            changed(recognizer.scale, context.converter.localLocation)
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

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            let place = WorldLand.placement(frame: frame, contentWidth: contentWidth, zoom: zoom)
            let path = Path(WorldLand.unitPath).applying(place)
            let ink = UVVAColor.creamFill
            context.fill(path, with: .color(ink.opacity(0.1)), style: FillStyle(eoFill: true))
            context.stroke(path, with: .color(ink.opacity(0.5)), lineWidth: 0.6)
        }
    }
}

/// The land on a map 1 point wide, projected once, and where it goes in the drawing of a coastline or of the heat.
@MainActor
private enum WorldLand {
    static let unitProjection: WorldProjection = {
        let atlas = WorldAtlas.shared
        let aspect = WorldProjection.aspectRatio(box: atlas.box)
        return WorldProjection(box: atlas.box, size: CGSize(width: 1, height: 1 / aspect))
    }()

    static let unitPath: CGPath = unitProjection.path(WorldAtlas.shared.land)

    /// The world at `contentWidth`, shown at `zoom`, inside a drawing with a frame of land around the map.
    static func placement(frame: CGSize, contentWidth: CGFloat, zoom: MapZoom) -> CGAffineTransform {
        CGAffineTransform(scaleX: contentWidth, y: contentWidth)
            .concatenating(zoom.transform)
            .concatenating(CGAffineTransform(translationX: frame.width, y: frame.height))
    }
}

/// The places of tasted wines painted on the land in the wine of the lessons: from each, a wash strong at the place
/// and fading out across the land around it, never over the sea; deeper and wider the more bottles came from there.
/// Washes that meet deepen each other, so a region dense with places darkens as a whole. Drawn, like the coastline, only when its size or zoom changes.
private struct WorldHeat: View, Equatable {
    var frame: CGSize
    var contentWidth: CGFloat
    var zoom: MapZoom
    var places: [ProgressMapPin]

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            let place = WorldLand.placement(frame: frame, contentWidth: contentWidth, zoom: zoom)
            context.clip(to: Path(WorldLand.unitPath).applying(place), style: FillStyle(eoFill: true))
            // Closer in, the paint covers more of the map, though less of the land.
            let reach = pow(zoom.scale, 0.6)
            let tone = ProgressWorldMap.heatTone
            for wine in places {
                let center = WorldLand.unitProjection.point(lon: wine.lon, lat: wine.lat).applying(place)
                let heat = ProgressWorldMap.heat(wine.count)
                let strength = ProgressWorldMap.heatOpacity(heat)
                let radius = ProgressWorldMap.paintRadius(heat) * reach
                let wash = Gradient(stops: [
                    .init(color: tone.opacity(strength), location: 0),
                    .init(color: tone.opacity(strength * 0.8), location: 0.25),
                    .init(color: tone.opacity(strength * 0.45), location: 0.52),
                    .init(color: tone.opacity(strength * 0.15), location: 0.8),
                    .init(color: tone.opacity(0), location: 1)
                ])
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                    width: radius * 2, height: radius * 2)),
                             with: .radialGradient(wash, center: center, startRadius: 0, endRadius: radius))
            }
        }
    }
}

/// How far in the world map is and which part of it shows: points of the world at full size (`content`) are scaled by
/// `scale`, then moved by `offset`, into the map's `frame`. Along a side where the world is longer than the frame no
/// edge of it comes inside; along one where it is shorter, it stays in the middle.
struct MapZoom: Equatable {
    /// Past this the plain coastline grows too coarse.
    static let maxScale: CGFloat = 7

    var scale: CGFloat = 1
    var offset: CGSize = .zero
    /// Full screen: the map never shrinks below filling the frame, so no empty band shows above or below the world.
    var fills = false

    /// As far out as the map goes, the whole world in the frame (or, filling it, as tall as it), its middle in the
    /// middle of the frame.
    static func home(frame: CGSize, content: CGSize, fills: Bool = false) -> MapZoom {
        let scale = minScale(frame: frame, content: content, fills: fills)
        return MapZoom(scale: scale, offset: CGSize(width: (frame.width - content.width * scale) / 2,
                                                    height: (frame.height - content.height * scale) / 2),
                       fills: fills)
            .clamped(frame: frame, content: content)
    }

    /// Small enough to show the whole world in the frame; filling it, large enough to leave no empty band.
    static func minScale(frame: CGSize, content: CGSize, fills: Bool = false) -> CGFloat {
        fills ? max(frame.width / content.width, frame.height / content.height)
            : min(1, frame.width / content.width, frame.height / content.height)
    }

    var transform: CGAffineTransform {
        CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: offset.width, ty: offset.height)
    }

    func apply(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale + offset.width, y: point.y * scale + offset.height)
    }

    /// At `scale`, with the point under `anchor` kept where it is.
    func zoomed(to scale: CGFloat, at anchor: CGPoint, frame: CGSize, content: CGSize) -> MapZoom {
        let scale = min(max(scale, Self.minScale(frame: frame, content: content, fills: fills)), Self.maxScale)
        let ratio = scale / self.scale
        return MapZoom(scale: scale,
                       offset: CGSize(width: anchor.x - (anchor.x - offset.width) * ratio,
                                      height: anchor.y - (anchor.y - offset.height) * ratio),
                       fills: fills)
            .clamped(frame: frame, content: content)
    }

    func moved(by translation: CGSize, frame: CGSize, content: CGSize) -> MapZoom {
        MapZoom(scale: scale, offset: CGSize(width: offset.width + translation.width,
                                             height: offset.height + translation.height), fills: fills)
            .clamped(frame: frame, content: content)
    }

    func clamped(frame: CGSize, content: CGSize) -> MapZoom {
        func axis(_ offset: CGFloat, frame: CGFloat, content: CGFloat) -> CGFloat {
            let length = content * scale
            return length >= frame ? min(0, max(frame - length, offset)) : (frame - length) / 2
        }
        return MapZoom(scale: scale,
                       offset: CGSize(width: axis(offset.width, frame: frame.width, content: content.width),
                                      height: axis(offset.height, frame: frame.height, content: content.height)),
                       fills: fills)
    }
}
