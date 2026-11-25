import Foundation

struct FriendsResourcesUIModel {
    var titleText = String(localized: "Your Friends", bundle: .module)
    var requestsText = String(localized: "Requests", bundle: .module)
    var quickAddText = String(localized: "Quick add", bundle: .module)
    var acceptText = String(localized: "Accept", bundle: .module)
    var declineText = String(localized: "Decline", bundle: .module)
    var addText = String(localized: "Add", bundle: .module)
    var requestedText = String(localized: "Requested", bundle: .module)
    var dismissText = String(localized: "Not now", bundle: .module)
    var cancelRequestHint = String(localized: "Takes the request back", bundle: .module)
    var emptyBodyText = String(localized: "Add the people you drink with. Once they accept, you will see where your palates meet and what to open together.", bundle: .module)
    var compareTitleText = String(localized: "Find out what your friends like to drink", bundle: .module)
    var addFriendsText = String(localized: "Invite friends", bundle: .module)
    var needTwoFriendsText = String(localized: "Add at least two friends to set a table.", bundle: .module)
    var inviteTitleText = String(localized: "Share your palate", bundle: .module)
    var inviteHeadingText = String(localized: "This is my wine palate", bundle: .module)
    var askAccessText = String(localized: "See which of your contacts are already on UVVA. Their numbers never leave your phone.", bundle: .module)
    var allowContactsText = String(localized: "Allow contacts", bundle: .module)
    var deniedAccessText = String(localized: "UVVA can't see your contacts. Allow it in Settings to find friends who are already here.", bundle: .module)
    var openSettingsText = String(localized: "Open Settings", bundle: .module)
    var inviteFriendsText = String(localized: "Invite your friends and find out what they like to drink.", bundle: .module)
    var dismissIcon = "xmark"
    var searchIcon = "magnifyingglass"
    var pickPromptText = String(localized: "Pick who’s coming. We’ll set the perfect table: the bottles and the dinner everyone will love.", bundle: .module)
    var buildTableText = String(localized: "Build a table", bundle: .module)
    var cancelText = String(localized: "Cancel", bundle: .module)
    var pickAtLeastTwoText = String(localized: "Pick at least two friends", bundle: .module)
    var searchPromptText = String(localized: "Search by name", bundle: .module)
    var noMatchesText = String(localized: "No friend by that name.", bundle: .module)

    var sentToYouText = String(localized: "Sent to you", bundle: .module)
    /// FRI-R04b: a request the user sent, not answered yet; a contact invited, not on UVVA yet.
    var addedText = String(localized: "Added", bundle: .module)
    var invitedText = String(localized: "Invited", bundle: .module)

    /// FRI-R11c: "Marina sent you a wine".
    func sentYouAWine(_ name: String) -> String { String(localized: "\(name) sent you a wine", bundle: .module) }

    func findBottle(_ count: Int) -> String {
        String(localized: "Find a bottle for these \(count)", bundle: .module)
    }

    func tableFull(_ count: Int) -> String {
        String(localized: "A table seats you and \(count) friends", bundle: .module)
    }

    func count(_ friends: Int) -> String {
        friends == 1 ? String(localized: "1 friend", bundle: .module)
                     : String(localized: "\(friends) friends", bundle: .module)
    }

    func compatibility(_ value: Int) -> String { "\(value)%" }

    func newFriend(_ name: String) -> String {
        String(localized: "\(name) is now your friend.", bundle: .module)
    }

    func inviteMessage(_ link: URL) -> String {
        String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together. \(link.absoluteString)", bundle: .module)
    }
}
