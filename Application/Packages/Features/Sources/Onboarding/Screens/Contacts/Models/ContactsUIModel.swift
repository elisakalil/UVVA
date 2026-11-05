import Foundation
import SwiftUI
import DesignSystem

/// Contacts (ONB-R37).
struct ContactsUIModel: Equatable {
    var accountsIllustration: Image { UVVAIllustration.grape(3) }
    var inviteIllustration: Image { UVVAIllustration.grape(5) }
    var query = ""
    var inviteLink: URL?
    var inviteMessage = String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    var noResultsMessage: String { String(localized: "No contacts match “\(query)”", bundle: .module) }
    var isLoading: Bool
    /// "Contacts"; none when nobody is on UVVA and that section is left out.
    var title: String?
    var onUVVATitle: String
    var onUVVA: [ContactRowUIModel]
    var toInvite: [ContactRowUIModel]
    /// Letters that have at least one contact to invite, for the A–Z bar.
    var letters: [String]
    /// A search is on and no name matches it.
    var noResults: Bool
    var inviteContactsWhoArenTOnText = String(localized: "Invite contacts who aren't on UVVA", bundle: .module)
    var searchContactsText = String(localized: "Search contacts", bundle: .module)
    var nextText = String(localized: "Next", bundle: .module)
}
