import Core
import Foundation

/// What the Friends tab shows, owned by `FriendsViewModel`.
struct FriendsContentModel: Equatable, Sendable {
    var user: FriendsUser?
    var snapshot = FriendsSnapshot()
    var suggestions: [QuickAddSuggestion] = []
    var contactsAccess: ContactsAccess = .notDetermined
    /// The friends were read from the device and the public database was not reached yet.
    var isLoading = true
    /// Something real to show: friends kept on the device, or the public database was asked. Until then the list
    /// stays hidden, so the invite never flashes before the friends.
    var isReady = false
    /// The name of the friend just accepted, for "[name] is now your friend." (FRI-R08a).
    var newFriendName: String?
}
