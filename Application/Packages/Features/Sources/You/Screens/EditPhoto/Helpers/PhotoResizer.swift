import UIKit

/// The profile photo is kept small: a 512 px square JPEG.
enum PhotoResizer {
    static func squareJPEG(_ data: Data, side: CGFloat = 512) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let crop = min(image.size.width, image.size.height)
        let origin = CGPoint(x: (image.size.width - crop) / 2, y: (image.size.height - crop) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let square = renderer.image { _ in
            let scale = side / crop
            image.draw(in: CGRect(x: -origin.x * scale, y: -origin.y * scale,
                                  width: image.size.width * scale, height: image.size.height * scale))
        }
        return square.jpegData(compressionQuality: 0.8)
    }
}
