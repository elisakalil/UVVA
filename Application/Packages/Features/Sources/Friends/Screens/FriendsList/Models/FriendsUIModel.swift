import Foundation

public struct FriendsUIModel {
    /// "3 friends" (FRI-R04).
    var countText = ""
    var friends: [FriendRowUIModel] = []
    /// FRI-R04b: added or invited, not friends yet, faded at the end of the list.
    var pending: [PendingFriendRowUIModel] = []
    var requests: [FriendRequestRowUIModel] = []
    /// FRI-R11c: "Sent to you".
    var received: [ReceivedWineRowUIModel] = []
    /// A wine received, open full screen.
    var receivedWine: FriendWineUIModel?
    var quickAdd: QuickAddState = .noSuggestions
    /// No friend and no request (FRI-R06): the invite takes the place of the list.
    var isEmpty = false
    /// The friends kept on the device show while the public database is read.
    var isLoading = true
    /// False until there is something real to show: the list and Quick add stay hidden, without a spinner.
    var isReady = false
    /// "[name] is now your friend." (FRI-R08a).
    var toastText: String?
    /// "Search by name": the friends whose name holds it.
    var query = ""
    var isSearching = false
    /// FRI-R18: the table button turns the list into a choice of who comes.
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
