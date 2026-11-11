import SwiftUI
import UIKit

/// Ground glass, the base material of the app: the photo behind softly diffused and close to its own tone,
/// a faint haze at the top, a fine grain, a soft glow inside the edge and a thin bright rim.
/// On iOS 26 a clear Liquid Glass layer on top adds the lensing and specular shine at the edges.
/// Inside `glassPanes()` the photo and its shadow are drawn by the scroll view's `glassBackdrop()`, once for every pane.

public struct FrostedGlass: View {
    var radius: CGFloat
    /// Even glass for thin chrome that floats over other cards (the tab bar).
    var dense: Bool
    /// The photo belongs to the glass and scrolls with it, instead of staying fixed to the screen behind it.
    /// The You tab's panels carry bg1 this way over the hills of bg2.
    var pinsPhoto: Bool
    var cachesRim: Bool

    public init(radius: CGFloat = UVVARadius.card, dense: Bool = false, pinsPhoto: Bool = false,
                cachesRim: Bool = false) {
        self.radius = radius
        self.dense = dense
        self.pinsPhoto = pinsPhoto
        self.cachesRim = cachesRim
    }

    /// Width of the denser band along the edge; inside it the glass is a touch clearer.
    static let frostedEdge: CGFloat = 15
    /// How softly the edge band fades into the centre.
    static let edgeFade: CGFloat = 5
    /// The white haze steps down in three zones: the outer 10 pt, the band from 10 to 15 pt, and the centre.
    static let outerHazeWidth: CGFloat = 10
    static let outerHaze = 0.07
    static let bandHaze = 0.065
    static let centerHaze = 0.06
    /// How softly each haze zone meets the next.
    static let hazeFade: CGFloat = 3
    /// Strength of the grain layer; the grain itself is already faint (see `GlassTextures.grain`).
    static let grainOpacity = 1.0

    @Environment(\.backdropFrame) private var backdropFrame
    @Environment(\.sharesGlassBackdrop) private var sharesBackdrop
    @Environment(\.glassRimOpacity) private var rimOpacity
    /// The grain is drawn at the screen's own scale, so one speck is one device pixel.
    @Environment(\.displayScale) private var displayScale

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            diffusedPhoto
            // Cards are a touch clearer in the centre: less blur and less haze than along the edge.
            // The tab bar is too thin for that and stays even.
            if !dense { clearerCenter }
            // Everything above the photo stays still on the glass. Over a shared backdrop the grain comes with
            // the photo; elsewhere the pane draws its own.
            if !usesSharedBackdrop { grainLayer.clipShape(shape) }
            edgeLight
        }
        // Over a shared backdrop the bitmap above is all there is, already cut. Otherwise the photo moves with the
        // scroll and needs cutting live; a rounded cut is redone on every frame, over the whole visible pane.
        .clipShape(usesSharedBackdrop ? AnyShape(Rectangle()) : AnyShape(shape))
        .overlay { rim(shape) }
        .overlay { liquidShine(shape) }
        // Kept faint: a darker shadow spreads into the gaps between cards and dulls the photo there.
        // Cast by a plain shape behind the glass rather than by the glass itself, whose content moves
        // as it scrolls and would have its shadow recomputed on every frame.
        .background {
            if isOpaque {
                shape.fill(UVVAColor.moss).shadow(color: Color(hex: 0x0A0E08).opacity(0.05), radius: 20, y: 10)
            }
        }
        .anchorPreference(key: GlassPanes.self, value: .bounds) { bounds in
            usesSharedBackdrop ? [GlassPane(bounds: bounds, radius: radius, clearCenter: !dense)] : []
        }
        // Decoration only: the full-screen photo copy and the Liquid Glass layer must never take a touch,
        // or they swallow the scroll.
        .allowsHitTesting(false)
    }

    @ViewBuilder private func rim(_ shape: RoundedRectangle) -> some View {
        let opacity = pinsPhoto ? 0.5 : rimOpacity
        let gradient = LinearGradient(stops: [
            .init(color: .white.opacity(0.4 * opacity), location: 0),
            .init(color: .white.opacity(0.09 * opacity), location: 0.35),
            .init(color: .white.opacity(0.04 * opacity), location: 0.65),
            .init(color: .white.opacity(0.2 * opacity), location: 1)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        let lineWidth: CGFloat = 1.2

        if cachesRim {
            let mask = PanePiece.rim(radius: radius, lineWidth: lineWidth)
            GeometryReader { proxy in
                if proxy.size.width > mask.insets.leading + mask.insets.trailing,
                   proxy.size.height > mask.insets.top + mask.insets.bottom {
                    // Keep the gradient in the card's coordinate space as its height changes.
                    gradient.mask { mask.view(scale: displayScale) }
                } else {
                    shape.strokeBorder(gradient, lineWidth: lineWidth)
                }
            }
        } else {
            shape.strokeBorder(gradient, lineWidth: lineWidth)
        }
    }

    /// The grain stays the same over the whole pane.
    @ViewBuilder private var grainLayer: some View {
        if let grain = GlassTextures.grain {
            Image(decorative: grain, scale: displayScale)
                .resizable(resizingMode: .tile)
                .interpolation(.none)
                .opacity(Self.grainOpacity)
                // Lightens the photo in its own tones, like light scattered by the frosting, instead of painting over it.
                .blendMode(.softLight)
        }
    }

    /// How far in from the edge the haze zones and the edge light reach; past it the glass is even.
    static let edgeReach: CGFloat = 24

    /// The haze and the light at the edge, drawn once for this corner radius as a small image whose even middle
    /// is stretched over the pane, so a pane costs the same at any size.
    ///
    /// They used to be flattened into a bitmap of the whole pane. A pane taller than the screen (the day's
    /// suggestion, opened) only keeps the visible part of such a bitmap, so it was drawn again, blurs and masks
    /// included, on every frame of the scroll.
    private var edgeLight: some View {
        GeometryReader { proxy in
            let cap = radius + Self.edgeReach
            if min(proxy.size.width, proxy.size.height) > 2 * cap,
               let image = EdgeLight.image(radius: radius, dense: dense, innerGlow: pinsPhoto, scale: displayScale) {
                Image(uiImage: image)
                    .resizable(capInsets: EdgeInsets(top: cap, leading: cap, bottom: cap, trailing: cap))
            } else {
                // Too small to stretch: small enough to keep whole as one bitmap.
                EdgeLight(radius: radius, dense: dense, innerGlow: pinsPhoto).drawingGroup()
            }
        }
    }

    /// The photo is drawn by the scroll view's `glassBackdrop()`, not by this pane.
    private var usesSharedBackdrop: Bool {
        sharesBackdrop && !pinsPhoto && backdropFrame != nil && GlassTextures.blurredPhoto != nil
    }

    /// The photo fills the glass edge to edge, so a shape behind it can cast the shadow without showing through.
    /// With a shared backdrop, the backdrop casts it.
    private var isOpaque: Bool {
        !usesSharedBackdrop && GlassTextures.blurredPhoto != nil && (pinsPhoto || backdropFrame != nil)
    }

    /// The blurred photo, cut to the part that sits behind this glass.
    @ViewBuilder private var diffusedPhoto: some View {
        if usesSharedBackdrop {
            EmptyView()
        } else if pinsPhoto, let photo = GlassTextures.blurredPhoto {
            photoPinned(photo)
        } else if let backdropFrame, let photo = GlassTextures.blurredPhoto {
            FixedPhoto(photo: photo, backdropFrame: backdropFrame)
        } else {
            Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .light).opacity(0.7)
        }
    }

    /// The lightly blurred photo, cut to the part behind this glass and faded out towards the denser edge.
    @ViewBuilder private var clearerCenter: some View {
        if usesSharedBackdrop {
            EmptyView()
        } else if pinsPhoto, let photo = GlassTextures.lightlyBlurredPhoto {
            photoPinned(photo)
                .mask { PanePiece.center(radius: radius).view(scale: displayScale) }
        } else if let backdropFrame, let photo = GlassTextures.lightlyBlurredPhoto {
            FixedPhoto(photo: photo, backdropFrame: backdropFrame)
                .mask { inset(by: Self.frostedEdge, fade: Self.edgeFade).drawingGroup() }
        }
    }

    /// The pane shrunk by `inset` on every side, its edge softened by `fade`.
    private func inset(by inset: CGFloat, fade: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: max(0, radius - inset), style: .continuous)
            .padding(inset)
            .blur(radius: fade)
    }

    /// The photo filling the glass from its top edge, so it moves with the glass.
    private func photoPinned(_ photo: UIImage) -> some View {
        GeometryReader { proxy in
            ZStack {
                UVVAColor.moss
                Image(uiImage: photo).resizable().scaledToFill()
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()
        }
    }

    /// Shared and photo-pinned panes use the cached edge light while scrolling.
    @ViewBuilder private func liquidShine(_ shape: RoundedRectangle) -> some View {
        if #available(iOS 26.0, *), !usesSharedBackdrop, !pinsPhoto {
            Color.clear
                .glassEffect(.clear, in: shape)
                // Any stronger and its lensing draws a thin dark line just inside the rim.
                .opacity(0.25)
                .allowsHitTesting(false)
        }
    }
}

/// The haze and the light at the edge of a pane: a whitish haze stepping down in three zones from the edge in, and
/// light gathered along the rim. Past `FrostedGlass.edgeReach` from the edge it is even.
struct EdgeLight: View {
    var radius: CGFloat
    /// Even haze across the thin chrome (the tab bar).
    var dense: Bool
    var innerGlow: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            if dense {
                // The same whitish haze as the cards, kept even across the thin bar.
                Color.white.opacity(FrostedGlass.outerHaze)
            } else {
                haze
            }
            // Light gathers at the edges of thick frosted glass.
            shape
                .stroke(.white.opacity(innerGlow ? 0.12 : 0.05), lineWidth: 12)
                .blur(radius: 7)
        }
        .clipShape(shape)
    }

    /// The centre's haze over the whole pane, then a little more outside 15 pt from the edge and a little more
    /// again outside 10 pt.
    private var haze: some View {
        ZStack {
            Color.white.opacity(FrostedGlass.centerHaze)
            Color.white.opacity(FrostedGlass.bandHaze - FrostedGlass.centerHaze)
                .mask { outside(FrostedGlass.frostedEdge) }
            Color.white.opacity(FrostedGlass.outerHaze - FrostedGlass.bandHaze)
                .mask { outside(FrostedGlass.outerHazeWidth) }
        }
    }

    /// The band between the pane's edge and `inset` points in from it.
    private func outside(_ inset: CGFloat) -> some View {
        ZStack {
            Color.black
            RoundedRectangle(cornerRadius: max(0, radius - inset), style: .continuous)
                .padding(inset)
                .blur(radius: FrostedGlass.hazeFade)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private struct Key: Hashable {
        var radius: CGFloat
        var dense: Bool
        var innerGlow: Bool
        var scale: CGFloat
    }

    @MainActor private static var images: [Key: UIImage] = [:]

    /// The edge light of a pane just big enough to hold its corners and the even middle: one point wider and
    /// taller than the two corners, so that middle point is what stretches over a bigger pane.
    @MainActor static func image(radius: CGFloat, dense: Bool, innerGlow: Bool, scale: CGFloat) -> UIImage? {
        let key = Key(radius: radius, dense: dense, innerGlow: innerGlow, scale: scale)
        if let image = images[key] { return image }
        let side = 2 * (radius + FrostedGlass.edgeReach) + 1
        let renderer = ImageRenderer(
            content: EdgeLight(radius: radius, dense: dense, innerGlow: innerGlow).frame(width: side, height: side)
        )
        renderer.scale = scale
        renderer.isOpaque = false
        let image = renderer.uiImage
        images[key] = image
        return image
    }
}
