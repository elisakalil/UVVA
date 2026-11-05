import Core
import Foundation
import Match

/// Formats discovered contacts without fetching data or changing request state.
struct ContactsPresentationBuilder {
    func build(from contacts: DiscoveredContacts, query: String, requested: Set<String>,
               invited: Set<String>, isLoadingContacts: Bool) -> ContactsUIModel {
        let onUVVA = accountRows(contacts.onUVVA, query: query, requested: requested)
        let toInvite = inviteRows(contacts.toInvite, query: query, invited: invited)
        let count = contacts.onUVVA.count
        let isSearching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        return ContactsUIModel(
            isLoading: isLoadingContacts,
            title: count == 0 && !isLoadingContacts ? nil : String(localized: "Contacts", bundle: .module),
            onUVVATitle: title(for: count), onUVVA: onUVVA, toInvite: toInvite,
            letters: indexLetters(in: toInvite),
            noResults: isSearching && onUVVA.isEmpty && toInvite.isEmpty
        )
    }

    private func accountRows(_ contacts: [(contact: DeviceContact, account: PublicProfile)],
                             query: String, requested: Set<String>) -> [ContactRowUIModel] {
        contacts.filter { matchesQuery($0.contact, query: query) }.map { row in
            ContactRowUIModel(id: row.contact.id, name: row.contact.displayName, initials: row.contact.initials,
                              note: row.account.map.map { MapReading(map: $0).signature }, letter: row.contact.indexLetter,
                              state: requested.contains(row.contact.id) ? .requested : .add)
        }
    }

    private func inviteRows(_ contacts: [DeviceContact], query: String, invited: Set<String>) -> [ContactRowUIModel] {
        contacts.filter { matchesQuery($0, query: query) }.map { contact in
            ContactRowUIModel(id: contact.id, name: contact.displayName, initials: contact.initials, note: nil,
                              letter: contact.indexLetter,
                              state: invited.contains(contact.id) ? .invited : .invite)
        }
    }

    private func title(for count: Int) -> String {
        count == 1 ? String(localized: "1 of your contacts is on UVVA", bundle: .module)
            : String(localized: "\(count) of your contacts are on UVVA", bundle: .module)
    }

    private func indexLetters(in rows: [ContactRowUIModel]) -> [String] {
        var letters: [String] = []
        for row in rows where letters.last != row.letter { letters.append(row.letter) }
        return letters
    }

    /// Search ignores case and accents ("jose" finds "José").
    private func matchesQuery(_ contact: DeviceContact, query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        return query.isEmpty || contact.displayName.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
