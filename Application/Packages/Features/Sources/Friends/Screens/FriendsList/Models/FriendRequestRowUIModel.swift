import Foundation

/// A request to the user (FRI-R08a): who sent it, their palate signature, Accept and Decline.
struct FriendRequestRowUIModel: Identifiable, Equatable {
    var id: String
    var name: String
    var signature: String
}
