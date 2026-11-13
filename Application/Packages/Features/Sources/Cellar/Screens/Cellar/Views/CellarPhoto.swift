import DesignSystem
import ImageIO
import SwiftUI
import UIKit

/// The front label of a wine, filling its frame. A wine never photographed shows the Home's vineyard instead.
///
/// The label is decoded away from the main thread, at the size it is drawn, and kept for the next time it is drawn:
/// decoded in `body`, every label of the Cellar was a full photo decoded on the main thread each time the list was
/// drawn again, which froze the app when a new note made the Cellar read its entries again.
struct CellarPhoto: View {
    var data: Data?

    @Environment(\.displayScale) private var displayScale
    /// The longer side of the frame, in points.
    @State private var side: CGFloat = 0
    /// Bumped when a label has been decoded, so `body` reads it from the cache.
    @State private var decoded = 0

    var body: some View {
        image
            // Filled past its frame, the photo would take taps meant for what sits around it.
            .allowsHitTesting(false)
            .onGeometryChange(for: CGFloat.self) { max($0.size.width, $0.size.height) } action: { side = $0 }
            .task(id: request) {
                guard let request, CellarPhotoCache.image(for: request) == nil else { return }
                let image = await Task.detached(priority: .userInitiated) {
                    CellarPhotoCache.decode(request.data, maxPixel: request.maxPixel)
                }.value
                guard !Task.isCancelled, let image else { return }
                CellarPhotoCache.store(image, for: request)
                withAnimation(.easeOut(duration: 0.2)) { decoded += 1 }
            }
    }

    @ViewBuilder private var image: some View {
        if data == nil {
            UVVAPhoto.background
                .resizable()
                .scaledToFill()
        } else if let request, let image = CellarPhotoCache.image(for: request) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .transition(.opacity)
        } else {
            // The ground of the cover shows until the label is ready.
            Color.clear
        }
    }

    private var request: CellarPhotoRequest? {
        guard let data, side > 0 else { return nil }
        return CellarPhotoRequest(data: data, maxPixel: CellarPhotoCache.maxPixel(side: side, scale: displayScale))
    }
}

/// A label to decode, at most `maxPixel` on its longer side.
struct CellarPhotoRequest: Hashable, Sendable {
    var data: Data
    var maxPixel: Int

    /// Labels are compared by a sample of their bytes, not all of them: equal labels are the same `Data`, and
    /// different photos differ well before a few dozen samples run out.
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.key == rhs.key }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }

    var key: String {
        let samples = 48
        let fingerprint = data.withUnsafeBytes { bytes -> UInt64 in
            guard bytes.count > 0 else { return 0 }
            var hash: UInt64 = 0xCBF2_9CE4_8422_2325
            for index in 0..<samples {
                hash = (hash ^ UInt64(bytes[index * (bytes.count - 1) / (samples - 1)])) &* 0x100_0000_01B3
            }
            return hash
        }
        return "\(data.count)-\(fingerprint)-\(maxPixel)"
    }
}

/// The labels already decoded, by label and size.
@MainActor
enum CellarPhotoCache {
    private static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()

    static func image(for request: CellarPhotoRequest) -> UIImage? {
        images.object(forKey: request.key as NSString)
    }

    static func store(_ image: UIImage, for request: CellarPhotoRequest) {
        let pixels = image.size.width * image.size.height * image.scale * image.scale
        images.setObject(image, forKey: request.key as NSString, cost: Int(pixels) * 4)
    }

    /// Filled into its frame, a label is cut on one side: half as large again as the frame covers the usual 3:4 label.
    /// Rounded up so a frame that moves by a point reuses what is there.
    static func maxPixel(side: CGFloat, scale: CGFloat) -> Int {
        let step: CGFloat = 128
        return Int(min(1800, ((side * scale * 1.5) / step).rounded(.up) * step))
    }

    /// A thumbnail straight from the JPEG, never the full photo in memory.
    nonisolated static func decode(_ data: Data, maxPixel: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
