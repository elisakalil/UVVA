import CoreUI
import Foundation

/// Friend Wine (FRI-R11a, R12a, R11c): a wine read against the friend's map, against the two maps together when it
/// was scanned from Compatibility, or against the user's own map when a friend sent it.
public struct FriendWineUIModel: Identifiable {
    /// What the button at the foot does.
    enum Footer: Equatable {
        /// FRI-R11b: "Send to Marina", "Sending…", "Sent to Marina"; `failed` says so over it.
        case send(title: String, isEnabled: Bool, failed: String?)
        /// FRI-R11c: a wine received, kept with "Add to cellar" ("In your cellar" once there).
        case addToCellar(isInCellar: Bool)
    }

    /// One person's match with the wine, for a scanned wine: "You 68%", "Marina 81%".
    struct PersonMatch: Identifiable, Equatable {
        var name: String
        var percentage: String
        var id: String { name }
    }

    public var id: String
    /// The wine as the sheet's body shows it: its match, its facts and its two maps.
    var content: WineSheetContent
    var strings: WineSheetStrings
    /// A scanned wine: each one's match under the producer. Empty for a wine of the friend's Map.
    var people: [PersonMatch] = []
    /// "MARINA SENT YOU THIS WINE", over the name of a wine received.
    var note: String?
    var footer: Footer
    var resources = FriendWineResourcesUIModel()
}
