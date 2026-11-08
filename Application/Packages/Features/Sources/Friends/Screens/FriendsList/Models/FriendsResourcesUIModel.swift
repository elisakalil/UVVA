import Foundation

struct FriendsResourcesUIModel {
    var titleText = String(localized: "Friends", bundle: .module)
    var requestsText = String(localized: "Requests", bundle: .module)
    var quickAddText = String(localized: "Quick add", bundle: .module)
    var acceptText = String(localized: "Accept", bundle: .module)
    var declineText = String(localized: "Decline", bundle: .module)
    var addText = String(localized: "Add", bundle: .module)
    var requestedText = String(localized: "Requested", bundle: .module)
    var dismissText = String(localized: "Not now", bundle: .module)
    var cancelRequestHint = String(localized: "Takes the request back", bundle: .module)
    var emptyTitleText = String(localized: "Your table is empty", bundle: .module)
    var emptyBodyText = String(localized: "Add the people you drink with. Once they accept, you will see where your palates meet and what to open together.", bundle: .module)
    var inviteText = String(localized: "Invite friends", bundle: .module)
    var inviteTitleText = String(localized: "Share your palate", bundle: .module)
    var inviteHeadingText = String(localized: "This is my wine palate", bundle: .module)
    var askAccessText = String(localized: "See which of your contacts are already on UVVA. Their numbers never leave your phone.", bundle: .module)
    var allowContactsText = String(localized: "Allow contacts", bundle: .module)
    var deniedAccessText = String(localized: "UVVA can't see your contacts. Allow it in Settings to find friends who are already here.", bundle: .module)
    var openSettingsText = String(localized: "Open Settings", bundle: .module)
    var noSuggestionsText = String(localized: "None of your contacts are on UVVA yet. Invite them with your palate.", bundle: .module)
    var dismissIcon = "xmark"
    var hostingText = String(localized: "Hosting tonight?", bundle: .module)
    var selectText = String(localized: "Select", bundle: .module)
    var cancelText = String(localized: "Cancel", bundle: .module)
    var pickAtLeastTwoText = String(localized: "Pick at least two friends", bundle: .module)
    var selectedIcon = "checkmark.circle.fill"
    var unselectedIcon = "circle"

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
