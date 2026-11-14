#if os(iOS)
@preconcurrency import AVFoundation
import Core
import Vision

/// Reads the back label off the camera's video while it moves over it (CELLAR-R17): one frame at a time, as fast as
/// the recognizer goes, the frames that arrive meanwhile dropped. Each frame's lines are votes in a `LabelScan`. It
/// reads only between `begin` and `finish`: on the front, the frames go by unread.
final class LabelScanner: NSObject, @unchecked Sendable {
    /// The languages of the labels UVVA expects, as `VisionLabelReader` reads the photos.
    static let languages = ["pt-PT", "pt-BR", "en-US", "fr-FR", "it-IT", "es-ES", "de-DE"]

    let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "app.uvva.label-scanner", qos: .userInitiated)
    private let lock = NSLock()
    private var scan = LabelScan()
    private var isActive = false
    private var onProgress: (@MainActor @Sendable (Int) -> Void)?
    /// The label frame and the preview on screen, to read only inside the frame.
    private var screen: (label: CGRect, preview: CGRect)?
    private lazy var languages: [String] = {
        let supported = Set((try? VNRecognizeTextRequest().supportedRecognitionLanguages()) ?? [])
        return Self.languages.filter(supported.contains)
    }()

    override init() {
        super.init()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
    }

    /// Starts a new scan, reading only what shows inside `label` of the `preview` (both on screen); `onProgress`
    /// hears, on the main thread, how many lines it is sure of so far.
    func begin(label: CGRect, preview: CGRect, onProgress: @escaping @MainActor @Sendable (Int) -> Void) {
        lock.withLock {
            scan = LabelScan()
            self.onProgress = onProgress
            screen = (label, preview)
            isActive = true
        }
    }

    /// Stops reading and gives what was read.
    func finish() -> LabelScan {
        lock.withLock {
            isActive = false
            onProgress = nil
            return scan
        }
    }

    /// The lines of one frame inside the label frame, upright as the phone is held.
    private func read(_ buffer: CVPixelBuffer) -> [LabelLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages
        // The buffer lies on its side: upright, its width is its height.
        let upright = CGSize(width: CVPixelBufferGetHeight(buffer), height: CVPixelBufferGetWidth(buffer))
        if let screen = lock.withLock({ screen }),
           let region = LabelScanRegion.normalized(label: screen.label, preview: screen.preview, frame: upright) {
            request.regionOfInterest = region
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
        guard (try? handler.perform([request])) != nil else { return [] }
        return (request.results ?? []).compactMap { observation in
            guard let best = observation.topCandidates(1).first else { return nil }
            return LabelLine(best.string, side: .back, height: Double(observation.boundingBox.height),
                             confidence: Double(best.confidence))
        }
    }
}

extension LabelScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard lock.withLock({ isActive }), let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let lines = read(buffer)
        let progress: (count: Int, report: @MainActor @Sendable (Int) -> Void)? = lock.withLock {
            guard isActive else { return nil }
            // A blurred frame, the bottle turning too fast, is left out.
            scan.addFrame(lines)
            return onProgress.map { (scan.confirmedCount, $0) }
        }
        if let progress {
            let count = progress.count
            let report = progress.report
            Task { @MainActor in report(count) }
        }
    }
}
#endif
