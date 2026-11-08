import Core
import Foundation

/// FRI-R07: the address book's phones become contact keys on the device; only the keys are asked about
/// (ARCHITECTURE §4.4). Contacts who skipped the phone, or who have no map yet (FRI-R01), are not found.
/// Contacts taken out with `×` are excluded by the caller, with friends and pending requests to the user.
@MainActor
struct FindQuickAddUseCase: FindQuickAddUseCaseProtocol {
    let contacts: any ContactsProviding
    let social: any SocialService
    let friends: any FriendsRepository
    let homeCountry: PhoneCountry

    func execute(userID: String, excluding: Set<String>) async -> [QuickAddSuggestion] {
        guard contacts.access() == .granted else { return [] }
        let all = ((try? await contacts.fetch()) ?? []).filter { !$0.displayName.isEmpty }
        let phonesByContact = Dictionary(all.map { contact in
            (contact.id, contact.phones.compactMap { PhoneNumber.e164(contact: $0, home: homeCountry) })
        }) { first, _ in first }
        let phones = Array(Set(phonesByContact.values.joined()))
        guard !phones.isEmpty, let accounts = try? await social.accounts(forPhones: phones) else { return [] }
        let dismissed = (try? await friends.dismissedSuggestions()) ?? []
        let hidden = excluding.union(dismissed).union([userID])

        var seen = Set<String>()
        var result: [QuickAddSuggestion] = []
        for contact in all {
            guard let account = phonesByContact[contact.id]?.lazy.compactMap({ accounts[$0] }).first,
                  account.hasMap, let map = account.map,
                  !hidden.contains(account.id), seen.insert(account.id).inserted else { continue }
            result.append(QuickAddSuggestion(id: account.id, contactName: contact.displayName, map: map))
        }
        return result.sorted { $0.contactName.localizedStandardCompare($1.contactName) == .orderedAscending }
    }
}
