import Foundation

/// Contacts (ONB-R37).
struct ContactsUIModel: Equatable {
    var isLoading: Bool
    var onUVVATitle: String
    var onUVVA: [ContactRowUIModel]
    var toInvite: [ContactRowUIModel]
    /// Letters that have at least one contact to invite, for the A–Z bar.
    var letters: [String]
}
