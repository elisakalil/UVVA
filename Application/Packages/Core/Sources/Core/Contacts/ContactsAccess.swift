import Foundation

/// Where the address book permission stands (FRI-R07a).
public enum ContactsAccess: Equatable, Sendable {
    /// Never asked: asking shows the iOS prompt.
    case notDetermined
    /// Full or limited access.
    case granted
    /// Refused or restricted: iOS no longer asks, only the Settings can change it.
    case denied
}
