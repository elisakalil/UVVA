import Foundation

public struct FriendsUIModel {
    /// "3 friends" (FRI-R04).
    var countText = ""
    var friends: [FriendRowUIModel] = []
    var requests: [FriendRequestRowUIModel] = []
    var quickAdd: QuickAddState = .noSuggestions
    /// No friend and no request (FRI-R06): the invite takes the place of the list.
    var isEmpty = false
    /// The friends kept on the device show while the public database is read.
    var isLoading = true
    /// False until there is something real to show: the list and Quick add stay hidden, without a spinner.
    var isReady = false
    /// "[name] is now your friend." (FRI-R08a).
    var toastText: String?
    /// FRI-R18: "Hosting tonight? · Select" turns the list into a choice of who comes.
    var canSelect = false
    var isSelecting = false
    var selectedIDs: Set<String> = []
    var selectButtonText = ""
    var canFindBottle = false
    var tableFullText: String?
    var invite: FriendsInviteUIModel?
    var isInviting = false
    var resources = FriendsResourcesUIModel()
}
