import Foundation

/// A friend in the list (FRI-R04): name, palate signature in capitals, compatibility.
struct FriendRowUIModel: Identifiable, Equatable {
    var id: String
    var name: String
    var signature: String
    var compatibilityText: String
}
