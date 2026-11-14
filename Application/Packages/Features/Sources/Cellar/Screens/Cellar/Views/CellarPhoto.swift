import DesignSystem
import ImageIO
import SwiftUI
import UIKit

/// A label in the detail. The browsing thumbnail can stay visible while the larger image is prepared.
struct CellarPhoto: View {
    var data: Data
    var preview: UIImage?

    @Environment(\.displayScale) private var displayScale
    @State private var side: CGFloat = 0
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let photo = image ?? preview ?? CellarPhotoCache.preview(for: data) {
                Image(uiImage: photo).resizable().scaledToFill()
                    .id(ObjectIdentifier(photo)).transition(.opacity)
            } else if failed {
                UVVAPhoto.background.resizable().scaledToFill()
            } else {
                GrapeLoop().frame(width: 30, height: 42)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
        .onGeometryChange(for: CGFloat.self) { max($0.size.width, $0.size.height) } action: { side = $0 }
        .task(id: maxPixel) {
            guard maxPixel > 0 else { return }
            let photo = await CellarPhotoCache.load(data, maxPixel: maxPixel)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                image = photo
                failed = photo == nil
            }
        }
    }

    private var maxPixel: Int {
        guard side > 0 else { return 0 }
        return Int(min(1800, (side * displayScale * 1.5 / 128).rounded(.up) * 128))
    }
}

@MainActor
enum CellarPhotoCache {
    // A serial queue bounds ImageIO work across the prefetch, scrolling and the detail.
    private static let decoder = DispatchQueue(label: "app.uvva.cellar.photos", qos: .userInitiated)
    private static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()
    private static var loading: [Key: Task<UIImage?, Never>] = [:]

    static func preview(for data: Data) -> UIImage? {
        let fingerprint = fingerprint(data)
        return [CellarViewMode.grid, .list].lazy.compactMap {
            images.object(forKey: Key(fingerprint: fingerprint, maxPixel: $0.thumbnailPixels).cacheKey)
        }.first
    }

    static func load(_ data: Data, maxPixel: Int) async -> UIImage? {
        let key = Key(fingerprint: fingerprint(data), maxPixel: maxPixel)
        if let image = images.object(forKey: key.cacheKey) { return image }
        if let task = loading[key] { return await task.value }

        let task = Task {
            let image: UIImage? = await withCheckedContinuation { continuation in
                decoder.async { continuation.resume(returning: decode(data, maxPixel: maxPixel)) }
            }
            if let image {
                let pixels = image.size.width * image.size.height * image.scale * image.scale
                images.setObject(image, forKey: key.cacheKey, cost: Int(pixels) * 4)
            }
            loading[key] = nil
            return image
        }
        loading[key] = task
        return await task.value
    }

    private struct Key: Hashable {
        var fingerprint: String
        var maxPixel: Int

        var cacheKey: NSString { "\(fingerprint)-\(maxPixel)" as NSString }
    }

    // Sample the JPEG to match the same label across the browsing and detail reads.
    private static func fingerprint(_ data: Data) -> String {
        let samples = 48
        let hash = data.withUnsafeBytes { bytes -> UInt64 in
            guard !bytes.isEmpty else { return 0 }
            var hash: UInt64 = 0xCBF2_9CE4_8422_2325
            for index in 0..<samples {
                hash = (hash ^ UInt64(bytes[index * (bytes.count - 1) / (samples - 1)])) &* 0x100_0000_01B3
            }
            return hash
        }
        return "\(data.count)-\(hash)"
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

extension CellarViewMode {
    var thumbnailPixels: Int { self == .grid ? 896 : 256 }
    // Keep a complete three-column row at the end of each grid batch.
    var photoBatchSize: Int { self == .grid ? 18 : 16 }
}
