import Foundation

/// The camera permission, implemented by the app with AVFoundation.
public protocol CameraAuthorizing: Sendable {
    func access() async -> CameraAccess
    /// Shows the system request (CELLAR-R15); true when the person allows it.
    func requestAccess() async -> Bool
}
