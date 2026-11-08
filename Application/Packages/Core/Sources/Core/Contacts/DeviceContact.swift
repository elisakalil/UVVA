import Foundation

/// A person from the address book, with every phone as written there.
public struct DeviceContact: Equatable, Identifiable, Sendable {
    public var id: String
    public var givenName: String
    public var familyName: String
    public var phones: [String]

    public init(id: String, givenName: String, familyName: String, phones: [String]) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.phones = phones
    }

    public var displayName: String {
        [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    public var initials: String {
        String(displayName.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
    }

    /// The letter of the A–Z bar; "#" for names that do not start with a letter.
    public var indexLetter: String {
        guard let first = displayName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).first,
              first.isLetter, first.isASCII else { return "#" }
        return String(first).uppercased()
    }
}
