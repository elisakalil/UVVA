import Foundation
import SwiftData

/// A Home notification the user opened (HOME-R04).
@Model
public final class ReadNotificationEntity {
    public var notificationID = ""
    public var readAt = Date.distantPast

    init(notificationID: String, readAt: Date) {
        self.notificationID = notificationID
        self.readAt = readAt
    }
}
