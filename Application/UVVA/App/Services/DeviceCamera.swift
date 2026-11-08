import AVFoundation
import Core

/// The camera permission (CELLAR-R15, R22). The text of the system request is `NSCameraUsageDescription`.
struct DeviceCamera: CameraAuthorizing {
    func access() async -> CameraAccess {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        default: .denied
        }
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
