import Foundation

/// Someone the user added or invited who is not a friend yet, faded at the end of the list (FRI-R04b).
struct PendingFriendRowUIModel: Identifiable, Equatable {
    var id: String
    var name: String
    /// "ADDED" (a request waiting for an answer) or "INVITED" (not on UVVA yet).
    var statusText: String
}
