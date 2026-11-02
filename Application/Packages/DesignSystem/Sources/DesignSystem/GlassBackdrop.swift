import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// One pane of glass inside `glassPanes()`, for the backdrop to show the photo through.
struct GlassPane {
    var bounds: Anchor<CGRect>
    var radius: CGFloat
    /// Cards are a touch clearer in the centre; the thin chrome is not.
    var clearCenter: Bool
}

struct GlassPanes: PreferenceKey {
    static let defaultValue: [GlassPane] = []

    static func reduce(value: inout [GlassPane], nextValue: () -> [GlassPane]) {
        value.append(contentsOf: nextValue())
    }
}

/// The panes in the scroll content's own space: they only change when the content is laid out again, not as it scrolls.
struct GlassPaneFrame: Equatable {
    var rect: CGRect
    var radius: CGFloat
    var clearCenter: Bool
}

struct GlassPaneFrames: PreferenceKey {
    static let defaultValue: [GlassPaneFrame] = []

    static func reduce(value: inout [GlassPaneFrame], nextValue: () -> [GlassPaneFrame]) {
        value.append(contentsOf: nextValue())
    }
}

extension EnvironmentValues {
    /// Set by `glassPanes()`: the panes inside leave the photo to `glassBackdrop()` instead of drawing their own copy.
    @Entry var sharesGlassBackdrop = false
}

extension View {
    /// On the content of a scroll view full of glass: its `FrostedGlass` panes stop drawing the photo themselves and
    /// report where they are, for `glassBackdrop()` on the scroll view to draw it.
    public func glassPanes() -> some View {
        environment(\.sharesGlassBackdrop, true)
            .backgroundPreferenceValue(GlassPanes.self) { panes in
                GeometryReader { proxy in
                    Color.clear.preference(key: GlassPaneFrames.self, value: panes.map {
                        GlassPaneFrame(rect: proxy[$0.bounds], radius: $0.radius, clearCenter: $0.clearCenter)
                    })
                }
            }
    }

    /// On a scroll view whose content has `glassPanes()`: draws the blurred page photo once, still on screen, behind
    /// the scroll view, and shows it only through the panes' shapes, which follow the scroll.
    ///
    /// Each pane used to draw its own window-sized copy and shift it against the scroll with `visualEffect`. Any
    /// geometry-driven effect inside the scroll content made SwiftUI redraw the whole content on every frame, and
    /// the Home stuttered. Here nothing inside the content changes as it scrolls: only this small mask moves.
    public func glassBackdrop() -> some View {
        modifier(GlassBackdropModifier())
    }
}

/// The scroll position, read only by the moving mask, so a scroll redraws nothing else.
@Observable
private final class ScrollOffset {
    var y: CGFloat = 0
}

private struct GlassBackdropModifier: ViewModifier {
    @Environment(\.backdropFrame) private var backdropFrame
    @State private var offset = ScrollOffset()
    @State private var scrollFrame: CGRect = .zero

    func body(content: Content) -> some View {
        if let backdropFrame, let photo = GlassTextures.blurredPhoto {
            content
                // How far the content has moved from its resting place. The scroll view's measured frame already
                // starts below the top inset, so the inset is added back.
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in
                    offset.y = y
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { scrollFrame = $0 }
                .backgroundPreferenceValue(GlassPaneFrames.self) { panes in
                    GlassBackdropLayer(photo: photo, light: GlassTextures.lightlyBlurredPhoto, panes: panes,
                                       backdropFrame: backdropFrame, scrollFrame: scrollFrame, offset: offset)
                }
        } else {
            content
        }
    }
}

private struct GlassBackdropLayer: View {
    var photo: UIImage
    var light: UIImage?
    var panes: [GlassPaneFrame]
    var backdropFrame: CGRect
    /// Where the scroll view sits on screen; the visible content starts at its top.
    var scrollFrame: CGRect
    var offset: ScrollOffset
    /// Where this layer sits on screen. Backgrounds reach under the safe area, so it is measured, not assumed.
    @State private var frame: CGRect = .zero
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let contentOrigin = CGPoint(x: scrollFrame.minX - frame.minX, y: scrollFrame.minY - frame.minY)
        ZStack(alignment: .topLeading) {
            Following(offset: offset, origin: contentOrigin) { shadows }
            still(photo).mask(alignment: .topLeading) { Following(offset: offset, origin: contentOrigin) { shapes } }
            if let light {
                still(light).mask(alignment: .topLeading) { Following(offset: offset, origin: contentOrigin) { centers } }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
        .allowsHitTesting(false)
    }

    /// The page photo laid out exactly as the background lays it out, with the glass's grain over it. The grain is
    /// drawn here, still on screen, instead of on each pane: tiled over a pane it was redrawn as the pane moved.
    private func still(_ image: UIImage) -> some View {
        ZStack {
            UVVAColor.moss
            Image(uiImage: image).resizable().scaledToFill()
            if let grain = GlassTextures.grain {
                Image(decorative: grain, scale: displayScale)
                    .resizable(resizingMode: .tile)
                    .interpolation(.none)
                    .opacity(FrostedGlass.grainOpacity)
                    .blendMode(.softLight)
            }
        }
        .frame(width: backdropFrame.width, height: backdropFrame.height)
        .clipped()
        .offset(x: backdropFrame.minX - frame.minX, y: backdropFrame.minY - frame.minY)
    }

    // Every piece that follows the scroll is a small image drawn once per corner radius, its even middle stretched
    // over the pane. Drawn at the pane's size instead, a pane taller than the screen (the day's suggestion, opened)
    // kept only its visible part and was drawn again, blur and shadow included, on every frame of the scroll.

    /// Kept faint: a darker shadow spreads into the gaps between cards and dulls the photo there.
    private var shadows: some View {
        ForEach(panes.indices, id: \.self) { index in
            let pane = panes[index]
            let piece = PanePiece.shadow(radius: pane.radius)
            piece.view(scale: displayScale)
                .frame(width: pane.rect.width + 2 * piece.margin, height: pane.rect.height + 2 * piece.margin)
                .offset(x: pane.rect.minX - piece.margin, y: pane.rect.minY - piece.margin + piece.drop)
        }
    }

    private var shapes: some View {
        ForEach(panes.indices, id: \.self) { index in
            let pane = panes[index]
            PanePiece.shape(radius: pane.radius).view(scale: displayScale)
                .frame(width: pane.rect.width, height: pane.rect.height)
                .offset(x: pane.rect.minX, y: pane.rect.minY)
        }
    }

    /// Each card shrunk to inside its denser edge band, its edge softened, as `FrostedGlass` does on its own.
    private var centers: some View {
        ForEach(panes.indices.filter { panes[$0].clearCenter }, id: \.self) { index in
            let pane = panes[index]
            PanePiece.center(radius: pane.radius).view(scale: displayScale)
                .frame(width: pane.rect.width, height: pane.rect.height)
                .offset(x: pane.rect.minX, y: pane.rect.minY)
        }
    }
}

/// One of the pieces the backdrop draws for a pane, as a small image whose middle point stretches over the pane.
private enum PanePiece: Hashable {
    /// The pane's outline, filled.
    case shape(radius: CGFloat)
    /// The pane's outline shrunk to inside the denser edge band, its edge softened.
    case center(radius: CGFloat)
    /// A faint shadow under the pane, the pane's outline blurred; cast downwards by `drop`.
    case shadow(radius: CGFloat)

    static let shadowBlur: CGFloat = 10

    /// Room the piece takes around the pane on every side.
    var margin: CGFloat {
        if case .shadow = self { 44 } else { 0 }
    }

    /// How far the shadow is cast down.
    var drop: CGFloat {
        if case .shadow = self { 10 } else { 0 }
    }

    /// The fixed border of the image, the rest being its one stretched middle point.
    var insets: EdgeInsets {
        switch self {
        case let .shape(radius):
            return EdgeInsets(top: radius, leading: radius, bottom: radius, trailing: radius)
        case let .center(radius):
            let corner = max(0, radius - FrostedGlass.frostedEdge) + FrostedGlass.frostedEdge
            return EdgeInsets(top: corner, leading: corner, bottom: corner, trailing: corner)
        case let .shadow(radius):
            let side = margin + radius
            return EdgeInsets(top: side, leading: side, bottom: side, trailing: side)
        }
    }

    @ViewBuilder private var drawing: some View {
        switch self {
        case let .shape(radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.black)
        case let .center(radius):
            let inset = FrostedGlass.frostedEdge
            RoundedRectangle(cornerRadius: max(0, radius - inset), style: .continuous)
                .padding(inset)
                .blur(radius: FrostedGlass.edgeFade)
        case let .shadow(radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color(hex: 0x0A0E08).opacity(0.05))
                .padding(margin)
                .blur(radius: Self.shadowBlur)
        }
    }

    @MainActor private static var images: [Key: UIImage] = [:]

    private struct Key: Hashable {
        var piece: PanePiece
        var scale: CGFloat
    }

    /// The piece stretched over whatever frame it is given. Should the image fail, the piece is drawn live at the
    /// pane's size instead: slower in a scroll, but the pane never loses its photo.
    @MainActor @ViewBuilder func view(scale: CGFloat) -> some View {
        if let image = image(scale: scale) {
            Image(uiImage: image).resizable(capInsets: insets)
        } else {
            drawing
        }
    }

    /// The outline the piece is drawn from, in its image.
    private func outline(in size: CGSize) -> (rect: CGRect, radius: CGFloat, color: UIColor, blur: CGFloat) {
        let bounds = CGRect(origin: .zero, size: size)
        switch self {
        case let .shape(radius):
            return (bounds, radius, .black, 0)
        case let .center(radius):
            let inset = FrostedGlass.frostedEdge
            return (bounds.insetBy(dx: inset, dy: inset), max(0, radius - inset), .black, FrostedGlass.edgeFade)
        case let .shadow(radius):
            return (bounds.insetBy(dx: margin, dy: margin), radius,
                    UIColor(red: 0x0A / 255, green: 0x0E / 255, blue: 0x08 / 255, alpha: 0.05), Self.shadowBlur)
        }
    }

    /// Drawn with Core Graphics rather than `ImageRenderer`, which is not dependable while SwiftUI is updating the
    /// view that asks for it.
    @MainActor private func image(scale: CGFloat) -> UIImage? {
        let key = Key(piece: self, scale: scale)
        if let image = Self.images[key] { return image }
        let size = CGSize(width: insets.leading + insets.trailing + 1, height: insets.top + insets.bottom + 1)
        let outline = outline(in: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let sharp = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let path = RoundedRectangle(cornerRadius: outline.radius, style: .continuous).path(in: outline.rect)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.setFillColor(outline.color.cgColor)
            context.cgContext.fillPath()
        }
        var image: UIImage? = sharp
        if outline.blur > 0 {
            image = nil
            if let input = CIImage(image: sharp) {
                let blur = CIFilter.gaussianBlur()
                blur.inputImage = input
                blur.radius = Float(outline.blur * scale)
                if let output = blur.outputImage?.cropped(to: input.extent),
                   let cg = GlassTextures.context.createCGImage(output, from: input.extent) {
                    image = UIImage(cgImage: cg, scale: scale, orientation: .up)
                }
            }
        }
        Self.images[key] = image
        return image
    }
}

/// Moves its content with the scroll. The only view that reads the scroll position.
private struct Following<Content: View>: View {
    var offset: ScrollOffset
    /// Where the scroll view's top left corner sits in the layer.
    var origin: CGPoint
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .topLeading) { content }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: origin.x, y: origin.y - offset.y)
    }
}

/// The page photo laid out exactly as the background lays it out, shifted so it stays still on screen
/// while the view holding it moves.
struct FixedPhoto: View {
    var photo: UIImage
    var backdropFrame: CGRect

    var body: some View {
        Color.clear.overlay(alignment: .topLeading) {
            ZStack {
                UVVAColor.moss
                Image(uiImage: photo).resizable().scaledToFill()
            }
            .frame(width: backdropFrame.width, height: backdropFrame.height)
            .clipped()
            // Shifted at render time: a scroll moves the photo without laying the glass out again.
            .visualEffect { content, proxy in
                let frame = proxy.frame(in: .global)
                return content.offset(x: backdropFrame.minX - frame.minX, y: backdropFrame.minY - frame.minY)
            }
        }
    }
}
