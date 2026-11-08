import Foundation
import SwiftData

/// A Quick add suggestion taken out with `×` (FRI-R09). It is not suggested again (D4).
@Model
public final class DismissedSuggestionEntity {
    public var userID = ""
    public var dismissedAt = Date.distantPast

    init(userID: String, dismissedAt: Date) {
        self.userID = userID
        self.dismissedAt = dismissedAt
    }
}
