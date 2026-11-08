@preconcurrency import AVFoundation
import UIKit

/// The back camera for the label photos: a live preview and a still, shrunk to what the reading and the Cellar
/// need. The session runs on its own queue, off the main thread, as AVFoundation asks.
final class LabelCamera: NSObject, @unchecked Sendable {
    /// The longest side of a kept photo, in pixels: enough for Vision, light enough for iCloud.
    static let maxSide: CGFloat = 1800

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

    /// A JPEG of the label, or nil when the camera could not take it.
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

    static func shrink(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.72)
    }
}

extension LabelCamera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        finish(error == nil ? photo.fileDataRepresentation().flatMap(Self.shrink) : nil)
    }
}
