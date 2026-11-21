import Core
import Foundation

/// A wine a friend sent the user (FRI-R11c), with the wine itself: from the catalog on the phone, or as the sender
/// saw it when the catalog does not have it.
struct ReceivedWine: Identifiable, Equatable, Sendable {
    /// The sent wine's record.
    var id: String
    var fromID: String
    /// "Marina": the friend's name as cached, or as it was when sent.
    var fromName: String
    var wine: Wine
    var sentAt: Date
}
