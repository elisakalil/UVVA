import Core
import Foundation
import SwiftData

/// A contact invited from the contacts list (ONB-R37a), shown faded in the Friends tab until they join (FRI-R04b).
@Model
public final class InvitedContactEntity {
    public var contactID = ""
    public var name = ""
    public var phones: [String] = []
    public var invitedAt = Date.distantPast

    init(_ invite: InvitedContact) {
        contactID = invite.id
        name = invite.name
        phones = invite.phones
        invitedAt = invite.invitedAt
    }

    var invite: InvitedContact {
        InvitedContact(id: contactID, name: name, phones: phones, invitedAt: invitedAt)
    }
}
