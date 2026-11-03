import Contacts
import Foundation

/// `ContactsProviding` on the iOS address book.
public struct DeviceContacts: ContactsProviding {
    public init() {}

    public func requestAccess() async -> Bool {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited: return true
        case .notDetermined: return (try? await store.requestAccess(for: .contacts)) ?? false
        default: return false
        }
    }

    public func fetch() async throws -> [DeviceContact] {
        try await Task.detached(priority: .userInitiated) {
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            var contacts: [DeviceContact] = []
            try CNContactStore().enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { contact, _ in
                let phones = contact.phoneNumbers.map(\.value.stringValue)
                guard !phones.isEmpty else { return }
                contacts.append(DeviceContact(id: contact.identifier, givenName: contact.givenName,
                                              familyName: contact.familyName, phones: phones))
            }
            return contacts
        }.value
    }
}
