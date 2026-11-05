import Core
import Foundation

@MainActor
struct FindContactsOnUVVAUseCase: FindContactsOnUVVAUseCaseProtocol {
    let contacts: any ContactsProviding
    let social: any SocialService
    let homeCountry: PhoneCountry

    func execute(excluding userID: String?) async -> DiscoveredContacts {
        let all = ((try? await contacts.fetch()) ?? []).filter { !$0.displayName.isEmpty }
        let phones = normalizedPhones(for: all)
        let accounts = (try? await social.accounts(forPhones: Array(Set(phones.values.joined())))) ?? [:]
        return classify(all, phones: phones, accounts: accounts, excluding: userID)
    }

    private func normalizedPhones(for contacts: [DeviceContact]) -> [String: [String]] {
        var result: [String: [String]] = [:]
        for contact in contacts {
            result[contact.id] = contact.phones.compactMap { PhoneNumber.e164(contact: $0, home: homeCountry) }
        }
        return result
    }

    private func classify(_ contacts: [DeviceContact], phones: [String: [String]],
                          accounts: [String: PublicProfile], excluding userID: String?) -> DiscoveredContacts {
        var result = DiscoveredContacts()
        for contact in contacts {
            let account = phones[contact.id]?.lazy.compactMap { accounts[$0] }.first
            if let account {
                if account.hasMap, account.id != userID { result.onUVVA.append((contact, account)) }
            } else {
                result.toInvite.append(contact)
            }
        }
        result.onUVVA.sort { byName($0.contact, $1.contact) }
        result.toInvite.sort(by: byName)
        return result
    }

    private func byName(_ lhs: DeviceContact, _ rhs: DeviceContact) -> Bool {
        lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
    }
}
