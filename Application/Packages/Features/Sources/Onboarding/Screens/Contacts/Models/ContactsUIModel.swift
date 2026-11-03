import Foundation

/// Contacts (ONB-R37).
struct ContactsUIModel: Equatable {
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
}
