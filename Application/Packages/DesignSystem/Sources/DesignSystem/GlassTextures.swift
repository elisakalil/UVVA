import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Textures for the ground glass, rendered once: the page photo under a heavy blur, and a fine grain.
/// Rendering them takes a moment; first read while the Home was being built, they held the main thread and froze
/// the Splash, so the app prepares them off it during the Splash (`prepare()`).
public enum GlassTextures {
    static let photoName = "Background"
    /// Blur of the glass in points, measured on the photo as it fills a 402 pt-wide screen.
    static let blurPoints: CGFloat = 9
    /// A lighter blur for the centre of cards, which is a touch clearer than the edge.
    static let centerBlurPoints: CGFloat = 7

    /// The photo blurred far beyond what a system material does, so the vineyard reads as soft patches of colour.
    static let blurredPhoto = blurred(by: blurPoints)
    static let lightlyBlurredPhoto = blurred(by: centerBlurPoints)

    /// One Core Image context for all the glass: each one is slow to create.
    static let context = CIContext()

    /// Renders every texture off the main thread, so the first glass on screen finds them ready.
    public static func prepare() async {
        await Task.detached(priority: .userInitiated) {
            _ = blurredPhoto
            _ = lightlyBlurredPhoto
            _ = grain
        }.value
    }

    private static func blurred(by points: CGFloat) -> UIImage? {
        guard let source = UIImage(named: photoName, in: .module, with: nil), let input = CIImage(image: source) else { return nil }
        let blur = CIFilter.gaussianBlur()
        // Clamp first so the edges blur into the photo's own colours instead of into transparency.
        blur.inputImage = input.clampedToExtent()
        blur.radius = Float(points * source.size.width * source.scale / 402)
        guard let output = blur.outputImage?.cropped(to: input.extent),
              let cg = context.createCGImage(output, from: input.extent) else { return nil }
        return UIImage(cgImage: cg, scale: source.scale, orientation: source.imageOrientation)
    }

    /// Fine grain like sandblasted glass, tiled over the glass at one texel per device pixel: dense, faint and
    /// white only, so it lightens and softens what is behind instead of showing as separate specks.
    /// Each speck's alpha is `random^grainCurve × grainMaxAlpha`, then softened across its neighbours.
    static let grainMaxAlpha = 0.35
    /// Lower means more specks near the strongest; higher leaves most of them close to nothing.
    static let grainCurve = 1.5

    static let grain: CGImage? = {
        let side = 384
        var generator = SystemRandomNumberGenerator()
        let raw = (0..<(side * side)).map { _ in
            pow(Double.random(in: 0...1, using: &generator), grainCurve) * grainMaxAlpha
        }
        // A 3×3 soften that wraps around the tile's edges, so the tiles still meet without a seam.
        let weights: [Double] = [1, 2, 1, 2, 4, 2, 1, 2, 1]
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        for y in 0..<side {
            for x in 0..<side {
                var alpha = 0.0
                for dy in -1...1 {
                    for dx in -1...1 {
                        let index = ((y + dy + side) % side) * side + (x + dx + side) % side
                        alpha += raw[index] * weights[(dy + 1) * 3 + dx + 1]
                    }
                }
                let value = UInt8((alpha / 16 * 255).rounded())
                let i = (y * side + x) * 4
                // Premultiplied white.
                pixels[i] = value
                pixels[i + 1] = value
                pixels[i + 2] = value
                pixels[i + 3] = value
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cg = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { return nil }
        return cg
    }()
}
