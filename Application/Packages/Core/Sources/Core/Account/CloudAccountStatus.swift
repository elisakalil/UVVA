import Foundation

/// Whether the device is signed in to iCloud, which UVVA needs (ARCHITECTURE §7).
public protocol CloudAccountStatus: Sendable {
    func isAvailable() async -> Bool
}
