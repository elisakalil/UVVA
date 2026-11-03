import Foundation

/// The address book.
public protocol ContactsProviding: Sendable {
    /// Asks for access the first time; true when access is full or limited to some contacts.
    func requestAccess() async -> Bool
    func fetch() async throws -> [DeviceContact]
}
