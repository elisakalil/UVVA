import Foundation

/// A contact not on UVVA whom the user invited from the contacts list (ONB-R37a). Kept on the device, so the
/// Friends tab can show them, faded, until they join (FRI-R04b).
public struct InvitedContact: Identifiable, Equatable, Sendable {
    /// The address book's identifier of the contact.
    public var id: String
    public var name: String
    /// As in the address book: they are compared with the accounts once normalised.
    public var phones: [String]
    public var invitedAt: Date

    public init(id: String, name: String, phones: [String], invitedAt: Date) {
        self.id = id
        self.name = name
        self.phones = phones
        self.invitedAt = invitedAt
    }
}
