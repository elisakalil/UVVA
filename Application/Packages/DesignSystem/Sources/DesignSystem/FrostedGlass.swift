import SwiftUI
import UIKit

/// Ground glass, the base material of the app: the photo behind softly diffused and close to its own tone,
/// a faint haze at the top, a fine grain, a soft glow inside the edge and a thin bright rim.
/// On iOS 26 a clear Liquid Glass layer on top adds the lensing and specular shine at the edges.
public struct FrostedGlass: View {
    var radius: CGFloat
    /// Denser glass for chrome that floats over other cards (the tab bar).
    var dense: Bool

    public init(radius: CGFloat = UVVARadius.card, dense: Bool = false) {
        self.radius = radius
        self.dense = dense
    }

    /// Width of the denser band along the edge; inside it the glass is a touch clearer.
    static let frostedEdge: CGFloat = 15
    /// How softly the edge band fades into the centre.
    static let edgeFade: CGFloat = 5
    /// The white haze steps down in three zones: the outer 10 pt, the band from 10 to 15 pt, and the centre.
    static let outerHazeWidth: CGFloat = 10
    static let outerHaze = 0.05
    static let bandHaze = 0.045
    static let centerHaze = 0.04
    /// How softly each haze zone meets the next.
    static let hazeFade: CGFloat = 3
    /// Strength of the grain layer.
    static let grainOpacity = 0.65

    @Environment(\.backdropFrame) private var backdropFrame
    /// The grain is drawn at the screen's own scale, so one speck is one device pixel.
    @Environment(\.displayScale) private var displayScale

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            diffusedPhoto
            // Cards are a touch clearer in the centre: less blur and less haze than along the edge.
            // The tab bar is too thin for that and stays even.
            if dense {
                Color.white.opacity(Self.outerHaze)
                UVVAColor.night.opacity(0.18)
            } else {
                clearerCenter
                haze
            }
            // The grain stays the same over the whole pane.
            if let grain = GlassTextures.grain {
                Image(decorative: grain, scale: displayScale)
                    .resizable(resizingMode: .tile)
                    .interpolation(.none)
                    .opacity(Self.grainOpacity)
            }
            // Light gathers at the edges of thick frosted glass.
            shape
                .stroke(.white.opacity(0.05), lineWidth: 12)
                .blur(radius: 7)
        }
        .compositingGroup()
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                LinearGradient(stops: [
                    .init(color: .white.opacity(0.4), location: 0),
                    .init(color: .white.opacity(0.09), location: 0.35),
                    .init(color: .white.opacity(0.04), location: 0.65),
                    .init(color: .white.opacity(0.2), location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1.2
            )
        )
        .overlay { liquidShine(shape) }
        // Kept faint: a darker shadow spreads into the gaps between cards and dulls the photo there.
        .shadow(color: Color(hex: 0x0A0E08).opacity(0.05), radius: 20, y: 10)
        // Decoration only: the full-screen photo copy and the Liquid Glass layer must never take a touch,
        // or they swallow the scroll.
        .allowsHitTesting(false)
    }

    /// The blurred photo, cut to the part that sits behind this glass.
    @ViewBuilder private var diffusedPhoto: some View {
        if let backdropFrame, let photo = GlassTextures.blurredPhoto {
            photoBehind(photo, in: backdropFrame)
        } else {
            Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .light).opacity(0.7)
        }
    }

    /// The lightly blurred photo, cut to the part behind this glass and faded out towards the denser edge.
    @ViewBuilder private var clearerCenter: some View {
        if let backdropFrame, let photo = GlassTextures.lightlyBlurredPhoto {
            photoBehind(photo, in: backdropFrame)
                .mask { inset(by: Self.frostedEdge, fade: Self.edgeFade) }
        }
    }

    /// The white haze in three zones: the centre's haze over the whole pane, then a little more
    /// outside 15 pt from the edge and a little more again outside 10 pt.
    private var haze: some View {
        ZStack {
            Color.white.opacity(Self.centerHaze)
            Color.white.opacity(Self.bandHaze - Self.centerHaze)
                .mask { outside(Self.frostedEdge) }
            Color.white.opacity(Self.outerHaze - Self.bandHaze)
                .mask { outside(Self.outerHazeWidth) }
        }
    }

    /// The pane shrunk by `inset` on every side, its edge softened by `fade`.
    private func inset(by inset: CGFloat, fade: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: max(0, radius - inset), style: .continuous)
            .padding(inset)
            .blur(radius: fade)
    }

    /// The band between the pane's edge and `inset` points in from it.
    private func outside(_ inset: CGFloat) -> some View {
        ZStack {
            Color.black
            self.inset(by: inset, fade: Self.hazeFade).blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    /// The page photo laid out exactly as the background lays it out, shifted so this glass shows the part behind it.
    private func photoBehind(_ photo: UIImage, in backdropFrame: CGRect) -> some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            ZStack {
                UVVAColor.moss
                Image(uiImage: photo).resizable().scaledToFill()
            }
            .frame(width: backdropFrame.width, height: backdropFrame.height)
            .clipped()
            .offset(x: backdropFrame.minX - frame.minX, y: backdropFrame.minY - frame.minY)
        }
    }

    @ViewBuilder private func liquidShine(_ shape: RoundedRectangle) -> some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.clear, in: shape)
                // Any stronger and its lensing draws a thin dark line just inside the rim.
                .opacity(0.25)
                .allowsHitTesting(false)
        }
    }
}
