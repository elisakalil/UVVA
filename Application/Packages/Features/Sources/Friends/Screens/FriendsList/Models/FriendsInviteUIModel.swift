import Foundation

/// The invite of the empty list (D2): the user's palate with the link `uvva.app/invite/<id>`, shared the same way as
/// every share of the app (SHARED-R20).
struct FriendsInviteUIModel: Equatable {
    var title: String
    var message: String
    var heading: String
    var name: String
    var phrase: String
    var chartValues: [Double]
    var strongAxes: Set<Int>
}
