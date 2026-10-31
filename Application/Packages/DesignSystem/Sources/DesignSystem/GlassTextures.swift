import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Textures for the ground glass, rendered once: the page photo under a heavy blur, and a fine grain.
enum GlassTextures {
    static let photoName = "Background"
    /// Blur of the glass in points, measured on the photo as it fills a 402 pt-wide screen.
    static let blurPoints: CGFloat = 9
    /// A lighter blur for the centre of cards, which is a touch clearer than the edge.
    static let centerBlurPoints: CGFloat = 7

    /// The photo blurred far beyond what a system material does, so the vineyard reads as soft patches of colour.
    static let blurredPhoto = blurred(by: blurPoints)
    static let lightlyBlurredPhoto = blurred(by: centerBlurPoints)

    private static func blurred(by points: CGFloat) -> UIImage? {
        guard let source = UIImage(named: photoName, in: .module, with: nil), let input = CIImage(image: source) else { return nil }
        let blur = CIFilter.gaussianBlur()
        // Clamp first so the edges blur into the photo's own colours instead of into transparency.
        blur.inputImage = input.clampedToExtent()
        blur.radius = Float(points * source.size.width * source.scale / 402)
        guard let output = blur.outputImage?.cropped(to: input.extent),
              let cg = CIContext().createCGImage(output, from: input.extent) else { return nil }
        return UIImage(cgImage: cg, scale: source.scale, orientation: source.imageOrientation)
    }

    /// Fine grain, one speck per device pixel, tiled over the glass like sandblasted glass.
    /// Specks are white or black with mostly faint alpha, so the grain marks the glass without greying it.
    static let grain: CGImage? = {
        let side = 384
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        var generator = SystemRandomNumberGenerator()
        for i in 0..<(side * side) {
            let r = Double.random(in: 0...1, using: &generator)
            let alpha = UInt8(pow(r, 6) * 0.45 * 255)
            let tone: UInt8 = Bool.random(using: &generator) ? alpha : 0 // premultiplied white or black
            pixels[i * 4] = tone
            pixels[i * 4 + 1] = tone
            pixels[i * 4 + 2] = tone
            pixels[i * 4 + 3] = alpha
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
