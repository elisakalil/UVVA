import Foundation

/// The address book.
public protocol ContactsProviding: Sendable {
    /// The current permission, without asking.
    func access() -> ContactsAccess
    /// Asks for access the first time; true when access is full or limited to some contacts.
    func requestAccess() async -> Bool
    func fetch() async throws -> [DeviceContact]
}
