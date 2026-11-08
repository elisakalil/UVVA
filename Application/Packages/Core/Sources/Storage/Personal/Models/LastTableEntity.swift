import Foundation
import SwiftData

/// The last table opened (FRI-R17): only who was at it, so it follows the friends' maps when opened again.
/// One at most.
@Model
public final class LastTableEntity {
    public var friendIDs: [String] = []
    public var openedAt = Date.distantPast

    init(friendIDs: [String], openedAt: Date) {
        self.friendIDs = friendIDs
        self.openedAt = openedAt
    }
}
