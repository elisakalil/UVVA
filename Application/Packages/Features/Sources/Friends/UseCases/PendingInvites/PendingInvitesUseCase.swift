import Core
import Foundation

/// FRI-R04b: the invites kept on the device, without those who joined UVVA since. Who joined is asked by contact key,
/// as in Quick add (ARCHITECTURE §4.4), and their invite is forgotten: from then on they are a suggestion, a request
/// or a friend. Offline, every invite stays.
@MainActor
struct PendingInvitesUseCase: PendingInvitesUseCaseProtocol {
    let friends: any FriendsRepository
    let social: any SocialService
    let homeCountry: PhoneCountry

    func execute() async -> [InvitedContact] {
        guard let invites = try? await friends.invitedContacts(), !invites.isEmpty else { return [] }
        let phonesByInvite = Dictionary(invites.map { invite in
            (invite.id, invite.phones.compactMap { PhoneNumber.e164(contact: $0, home: homeCountry) })
        }) { first, _ in first }
        let phones = Array(Set(phonesByInvite.values.joined()))
        guard !phones.isEmpty, let accounts = try? await social.accounts(forPhones: phones) else { return invites }
        let joined = Set(invites.filter { invite in
            phonesByInvite[invite.id]?.contains { accounts[$0] != nil } ?? false
        }.map(\.id))
        if !joined.isEmpty { try? await friends.removeInvites(joined) }
        return invites.filter { !joined.contains($0.id) }
    }
}
