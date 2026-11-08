import Foundation
import SwiftData

/// A friend request the user declined (FRI-R08a). Only on this account, so the sender is never told.
@Model
public final class DeclinedRequestEntity {
    public var userID = ""
    public var declinedAt = Date.distantPast

    init(userID: String, declinedAt: Date) {
        self.userID = userID
        self.declinedAt = declinedAt
    }
}
