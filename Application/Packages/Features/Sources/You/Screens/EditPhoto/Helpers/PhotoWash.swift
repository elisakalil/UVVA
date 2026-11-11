import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Washes the profile photo in the blues of the sky behind the app (YOU-R14a).
///
/// Vision reads the photo and cuts out the objects in front (people, pets, things). The background takes the palest
/// blue, like the haze over the hills; each object takes a deeper one, the largest the deepest. A photo where Vision
/// finds nothing, or a device where it cannot run, is washed in one pale blue.
enum PhotoWash {
    /// The sky of the background photo: from the haze near the hills (0) to the deep top of the sky (1).
    static func tone(depth: Double) -> PhotoWashTone {
        let t = min(max(depth, 0), 1)
        return PhotoWashTone(shadow: mix(0x4A5F63, 0x1C2C31, t), light: mix(0xE4E8E3, 0x93B1B8, t))
    }

    /// The depth of each layer: the background, then the objects from the largest to the smallest.
    static func depths(objects count: Int) -> [Double] {
        guard count > 0 else { return [0.15] }
        let objects = (0..<count).map { index in count == 1 ? 1 : 1 - 0.5 * Double(index) / Double(count - 1) }
        return [0.15] + objects
    }

    /// The photo washed, as JPEG, or `nil` when it cannot be read.
    static func wash(_ data: Data) -> Data? {
        guard let source = CIImage(data: data, options: [.applyOrientationProperty: true]) else { return nil }
        let result = wash(source, masks: objectMasks(of: source))
        let context = CIContext()
        guard let cgImage = context.createCGImage(result, from: source.extent) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
    }

    /// The background in the palest blue, then each object, from its mask, in a deeper one.
    static func wash(_ source: CIImage, masks: [CIImage]) -> CIImage {
        let base = prepared(source)
        let layers = depths(objects: masks.count)
        var result = tinted(base, tone(depth: layers[0]))
        for (mask, depth) in zip(masks, layers.dropFirst()) {
            let blend = CIFilter.blendWithMask()
            blend.inputImage = tinted(base, tone(depth: depth))
            blend.backgroundImage = result
            blend.maskImage = mask
            result = blend.outputImage?.cropped(to: source.extent) ?? result
        }
        return result
    }

    /// A little more contrast, so the wash keeps the shapes of the photo.
    private static func prepared(_ image: CIImage) -> CIImage {
        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.saturation = 0
        controls.contrast = 1.08
        return controls.outputImage ?? image
    }

    private static func tinted(_ image: CIImage, _ tone: PhotoWashTone) -> CIImage {
        let falseColor = CIFilter.falseColor()
        falseColor.inputImage = image
        falseColor.color0 = tone.shadow
        falseColor.color1 = tone.light
        return falseColor.outputImage ?? image
    }

    /// One mask per object Vision finds, the largest first; none when Vision cannot run.
    private static func objectMasks(of image: CIImage) -> [CIImage] {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: image)
        guard (try? handler.perform([request])) != nil, let observation = request.results?.first else { return [] }
        return observation.allInstances.compactMap { instance -> (CIImage, Double)? in
            guard let buffer = try? observation.generateScaledMaskForImage(forInstances: IndexSet(integer: instance),
                                                                          from: handler) else { return nil }
            return (CIImage(cvPixelBuffer: buffer), coverage(of: buffer))
        }
        .sorted { $0.1 > $1.1 }
        .map(\.0)
    }

    /// How much of the photo the mask covers, from 0 to 1.
    private static func coverage(of buffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_OneComponent32Float,
              let base = CVPixelBufferGetBaseAddress(buffer) else { return 0 }
        let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        var total = 0.0
        for y in stride(from: 0, to: height, by: 4) {
            let row = base.advanced(by: y * rowBytes).assumingMemoryBound(to: Float.self)
            for x in stride(from: 0, to: width, by: 4) { total += Double(row[x]) }
        }
        let samples = Double(((height + 3) / 4) * ((width + 3) / 4))
        return samples > 0 ? total / samples : 0
    }

    private static func mix(_ from: Int, _ to: Int, _ t: Double) -> CIColor {
        func channel(_ hex: Int, _ shift: Int) -> Double { Double((hex >> shift) & 0xFF) / 255 }
        func blend(_ shift: Int) -> CGFloat { CGFloat(channel(from, shift) + (channel(to, shift) - channel(from, shift)) * t) }
        return CIColor(red: blend(16), green: blend(8), blue: blend(0))
    }
}
