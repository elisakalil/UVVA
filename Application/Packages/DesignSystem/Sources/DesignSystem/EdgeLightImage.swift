import Accelerate
import SwiftUI
import Synchronization
import UIKit

/// `EdgeLight` as a small image whose even middle `FrostedGlass` stretches over the pane, drawn once per look.
///
/// Drawn with Core Graphics and vImage rather than `ImageRenderer`, which is not dependable while SwiftUI is
/// updating the view that asks for it: now and then it handed back an image without the haze and the glow, and the
/// cache kept it, so every card of the session looked clearer until the app was opened again.
/// Both also work off the main thread, so the looks on screen after the Splash are drawn during it
/// (`prepare(scale:)`) and a scroll only reads the cache.
enum EdgeLightImage {
    struct Key: Hashable, Sendable {
        var radius: CGFloat
        var dense: Bool
        var innerGlow: Bool
        var strongerHaze: Bool
        var scale: CGFloat
    }

    private static let images = Mutex<[Key: UIImage]>([:])

    /// Width and blur of the light gathered along the rim.
    static let glowWidth: CGFloat = 12
    static let glowBlur: CGFloat = 7

    /// The edge light of a pane just big enough to hold its corners and the even middle: one point wider and
    /// taller than the two corners, so that middle point is what stretches over a bigger pane.
    static func image(radius: CGFloat, dense: Bool, innerGlow: Bool, strongerHaze: Bool, scale: CGFloat) -> UIImage? {
        let key = Key(radius: radius, dense: dense, innerGlow: innerGlow, strongerHaze: strongerHaze, scale: scale)
        if let image = images.withLock({ $0[key] }) { return image }
        guard let image = draw(key) else { return nil }
        images.withLock { $0[key] = image }
        return image
    }

    /// Draws every look the app uses, so none is drawn on the main thread: cards and hero (over the shared
    /// backdrop on the Home and alone elsewhere), the search field, the tab bar, the table menu and the You panels.
    /// About 40 ms in all off the main thread; a look missing here is drawn when first shown, in about 10 ms.
    static func prepare(scale: CGFloat) {
        for radius in [UVVARadius.card, UVVARadius.hero, SearchField.glassRadius] {
            for strongerHaze in [true, false] {
                _ = image(radius: radius, dense: false, innerGlow: false, strongerHaze: strongerHaze, scale: scale)
            }
        }
        _ = image(radius: UVVATabBar.glassRadius, dense: true, innerGlow: false, strongerHaze: false, scale: scale)
        for innerGlow in [true, false] {
            _ = image(radius: 0, dense: false, innerGlow: innerGlow, strongerHaze: false, scale: scale)
        }
    }

    // MARK: - Drawing

    /// The same layers as `EdgeLight.body`, in the same order, cut to the pane's shape.
    private static func draw(_ key: Key) -> UIImage? {
        let side = 2 * (key.radius + FrostedGlass.edgeReach) + 1
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)
        let format = format(scale: key.scale)

        var layers: [UIImage] = []
        let base: Double
        if key.dense {
            base = FrostedGlass.outerHaze
        } else {
            let center = key.strongerHaze ? 0.08 : FrostedGlass.centerHaze
            let band = key.strongerHaze ? 0.09 : FrostedGlass.bandHaze
            let outer = key.strongerHaze ? 0.10 : FrostedGlass.outerHaze
            base = center
            // Account for the haze already underneath each band.
            guard let bandLayer = outside(FrostedGlass.frostedEdge, radius: key.radius, bounds: bounds, format: format,
                                          alpha: (band - center) / (key.strongerHaze ? 1 - center : 1)),
                  let outerLayer = outside(FrostedGlass.outerHazeWidth, radius: key.radius, bounds: bounds,
                                           format: format,
                                           alpha: (outer - band) / (key.strongerHaze ? 1 - band : 1))
            else { return nil }
            layers = [bandLayer, outerLayer]
        }
        guard let glow = glow(radius: key.radius, bounds: bounds, format: format,
                              alpha: key.innerGlow ? 0.12 : 0.05)
        else { return nil }

        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            let graphics = context.cgContext
            graphics.addPath(path(radius: key.radius, in: bounds))
            graphics.clip()
            graphics.setFillColor(UIColor.white.withAlphaComponent(base).cgColor)
            graphics.fill(bounds)
            for layer in layers {
                layer.draw(in: bounds)
            }
            glow.image.draw(in: glow.frame)
        }
    }

    /// White at `alpha` over the band between the pane's edge and `inset` points in from it, its inner edge
    /// softened by `FrostedGlass.hazeFade`.
    private static func outside(_ inset: CGFloat, radius: CGFloat, bounds: CGRect,
                                format: UIGraphicsImageRendererFormat, alpha: Double) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let centre = renderer.image { context in
            context.cgContext.addPath(path(radius: max(0, radius - inset), in: bounds.insetBy(dx: inset, dy: inset)))
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.fillPath()
        }
        guard let softCentre = blurred(centre, by: FrostedGlass.hazeFade, scale: format.scale) else { return nil }
        return renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            context.cgContext.fill(bounds)
            softCentre.draw(in: bounds, blendMode: .destinationOut, alpha: 1)
        }
    }

    /// Light gathering at the rim: a wide stroke on the pane's edge, blurred. Half of the stroke lies outside the
    /// pane and still lights the inside as it blurs, so it is drawn on a canvas with room around the pane, and
    /// `frame` places that canvas back over it.
    private static func glow(radius: CGFloat, bounds: CGRect, format: UIGraphicsImageRendererFormat,
                             alpha: Double) -> (image: UIImage, frame: CGRect)? {
        let margin = glowWidth / 2 + 3 * glowBlur
        let canvas = CGRect(origin: .zero, size: bounds.insetBy(dx: -margin, dy: -margin).size)
        let stroke = UIGraphicsImageRenderer(size: canvas.size, format: format).image { context in
            let graphics = context.cgContext
            graphics.addPath(path(radius: radius, in: bounds.offsetBy(dx: margin, dy: margin)))
            graphics.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            graphics.setLineWidth(glowWidth)
            graphics.strokePath()
        }
        guard let image = blurred(stroke, by: glowBlur, scale: format.scale) else { return nil }
        return (image, canvas.offsetBy(dx: -margin, dy: -margin))
    }

    private static func path(radius: CGFloat, in rect: CGRect) -> CGPath {
        RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect).cgPath
    }

    private static func format(scale: CGFloat) -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        return format
    }

    /// A Gaussian blur of `points`, with what lies past the image's edge taken as clear, as SwiftUI's `blur` does.
    /// Three box blurs on the CPU stand in for the Gaussian. Core Image drew the same, but a look took close to
    /// 100 ms on the main thread the first time it was shown.
    private static func blurred(_ image: UIImage, by points: CGFloat, scale: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage,
              let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32,
                                                colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)),
              var source = try? vImage_Buffer(cgImage: cgImage, format: format)
        else { return nil }
        guard var spare = try? vImage_Buffer(width: Int(source.width), height: Int(source.height), bitsPerPixel: 32) else {
            source.free()
            return nil
        }
        defer {
            source.free()
            spare.free()
        }
        // Premultiplied, so every channel blurs the same way; past the edge is clear.
        let clear: [UInt8] = [0, 0, 0, 0]
        for size in boxSizes(sigma: points * scale) {
            let error = vImageBoxConvolve_ARGB8888(&source, &spare, nil, 0, 0, UInt32(size), UInt32(size), clear,
                                                   vImage_Flags(kvImageBackgroundColorFill))
            guard error == kvImageNoError else { return nil }
            swap(&source, &spare)
        }
        guard let output = try? source.createCGImage(format: format) else { return nil }
        return UIImage(cgImage: output, scale: scale, orientation: .up)
    }

    /// Widths of three box blurs whose sum matches a Gaussian of `sigma` pixels (each odd, so it stays centred).
    static func boxSizes(sigma: CGFloat) -> [Int] {
        let passes = 3.0
        let ideal = (12 * sigma * sigma / passes + 1).squareRoot()
        var lower = Int(ideal.rounded(.down))
        if lower.isMultiple(of: 2) { lower -= 1 }
        lower = max(1, lower)
        let upper = lower + 2
        let l = Double(lower)
        let lowerCount = Int(((12 * sigma * sigma - passes * l * l - 4 * passes * l - 3 * passes) / (-4 * l - 4)).rounded())
        return (0..<3).map { $0 < lowerCount ? lower : upper }
    }
}
