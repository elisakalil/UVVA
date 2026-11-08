import Foundation

/// Whether UVVA may use the camera (CELLAR-R15, R22).
public enum CameraAccess: Sendable {
    /// Never asked: the system asks on the first `+`.
    case notDetermined
    case authorized
    /// Refused, or restricted on this phone.
    case denied
}
