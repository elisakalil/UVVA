#if os(iOS)
@preconcurrency import AVFoundation
import UIKit

/// The back camera for the label photos: a live preview and a still at full size. Each photo is then made into
/// two copies: a light one the Cellar keeps, and a sharp one the label is read from. The session runs on its own
/// queue, off the main thread, as AVFoundation asks.
final class LabelCamera: NSObject, @unchecked Sendable {
    /// The longest side of a kept photo, in pixels: light enough for iCloud.
    static let maxSide: CGFloat = 1800
    /// The longest side of the copy that is read: the camera's full 12 MP, so the small print of a back label
    /// stays tall enough for Vision (shrunk to 1800, it was a few pixels high and went unread).
    static let readingMaxSide: CGFloat = 4032

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "app.uvva.label-camera")
    private var isConfigured = false
    private var pending: CheckedContinuation<Data?, Never>?

    /// False in the simulator and on a device without a back camera.
    let isAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil

    func start() {
        guard isAvailable else { return }
        queue.async { [self] in
            configureIfNeeded()
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    /// The photo as the camera took it, or nil when it could not take it. `LabelCamera.prepare` makes it into the
    /// two copies.
    func takePhoto() async -> Data? {
        guard isAvailable else { return nil }
        return await withCheckedContinuation { continuation in
            queue.async { [self] in
                guard session.isRunning, pending == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                pending = continuation
                output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured,
              let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        isConfigured = true
    }

    private func finish(_ data: Data?) {
        queue.async { [self] in
            pending?.resume(returning: data)
            pending = nil
        }
    }

    /// The kept photo and the copy to read, both upright: drawing them bakes in the camera's orientation, which
    /// Vision would otherwise have to guess. Slow on a 12 MP photo: call it off the main thread.
    static func prepare(_ data: Data) -> LabelPhoto? {
        guard let kept = shrink(data), let reading = shrink(data, maxSide: readingMaxSide, quality: 0.9) else {
            return nil
        }
        return LabelPhoto(kept: kept, reading: reading)
    }

    static func shrink(_ data: Data, maxSide: CGFloat = maxSide, quality: CGFloat = 0.72) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}

/// A label photo in its two copies (CELLAR-R17).
struct LabelPhoto: Sendable {
    /// What the Cellar keeps and shows.
    var kept: Data
    /// What the label is read from, at full size.
    var reading: Data
}

extension LabelCamera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        finish(error == nil ? photo.fileDataRepresentation() : nil)
    }
}
#endif
