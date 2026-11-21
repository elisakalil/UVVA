import Core
import Foundation

struct FriendProfileResourcesUIModel {
    var closeText = String(localized: "Close", bundle: .module)
    var closeIcon = "xmark"
    var readingByReadingText = String(localized: "Reading by reading", bundle: .module)
    var youText = String(localized: "You", bundle: .module)
    var scanButtonText = String(localized: "Scan a wine", bundle: .module)
    var dinner = DinnerResourcesUIModel()

    var removeText = String(localized: "Remove friend", bundle: .module)
    var cancelText = String(localized: "Cancel", bundle: .module)
    var noOverlapText = String(localized: "You barely overlap — you like different things.", bundle: .module)
    var menuFooterText = String(localized: "Read from both palate maps · UVVA", bundle: .module)
    var table = TableResourcesUIModel()

    func tab(_ tab: FriendProfileTab) -> String {
        switch tab {
        case .map: String(localized: "Map", bundle: .module)
        case .compatibility: String(localized: "Compatibility", bundle: .module)
        }
    }

    /// FRI-R11, over the first card of Map: "Beatriz Map".
    func mapTitle(_ name: String) -> String { String(localized: "\(name) Map", bundle: .module) }

    /// FRI-R11, over the second card of Map.
    func giftTitle(_ name: String) -> String { String(localized: "Picks for \(name)", bundle: .module) }

    func matches(_ value: Int, _ name: String) -> String {
        String(localized: "\(value)% of your palate map matches \(name)", bundle: .module)
    }

    /// "of your palate map matches Marina", beside the large percentage.
    func matchCaption(_ name: String) -> String {
        String(localized: "of your palate map matches \(name)", bundle: .module)
    }

    /// "You & Marina", on the menu card.
    func guests(_ name: String) -> String { String(localized: "You & \(name)", bundle: .module) }

    /// How far apart the two readings of an axis are (FRI-R12, "Reading by reading").
    func verdict(_ spread: AxisSpread) -> String {
        switch spread {
        case .same: String(localized: "Same", bundle: .module)
        case .closest: String(localized: "Close", bundle: .module)
        case .someGive: String(localized: "Apart", bundle: .module)
        case .widest: String(localized: "Opposed", bundle: .module)
        }
    }

    func bothWant(_ list: String) -> String {
        String(localized: "You both want \(list) in a glass.", bundle: .module)
    }

    func dinnerTitle(_ name: String) -> String {
        String(localized: "The perfect dinner for You & \(name)", bundle: .module)
    }

    func removeTitle(_ name: String) -> String { String(localized: "Remove \(name)?", bundle: .module) }

    func removeBody(_ name: String) -> String {
        String(localized: "\(name) won't be told. You can add each other again later.", bundle: .module)
    }
}
