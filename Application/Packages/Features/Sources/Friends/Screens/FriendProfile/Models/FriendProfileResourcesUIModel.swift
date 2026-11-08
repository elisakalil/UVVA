import Foundation

struct FriendProfileResourcesUIModel {
    var closeText = String(localized: "Close", bundle: .module)
    var closeIcon = "xmark"
    var readingsText = String(localized: "Readings", bundle: .module)
    var removeText = String(localized: "Remove friend", bundle: .module)
    var cancelText = String(localized: "Cancel", bundle: .module)
    var noOverlapText = String(localized: "You barely overlap — you like different things.", bundle: .module)
    var menuFooterText = String(localized: "Read from both palate maps · UVVA", bundle: .module)
    var table = TableResourcesUIModel()

    func tab(_ tab: FriendProfileTab) -> String {
        switch tab {
        case .palate: String(localized: "Palate", bundle: .module)
        case .compatibility: String(localized: "Compatibility", bundle: .module)
        case .table: String(localized: "Table", bundle: .module)
        }
    }

    func palateTitle(_ name: String) -> String { String(localized: "\(name)'s palate", bundle: .module) }

    func matches(_ value: Int, _ name: String) -> String {
        String(localized: "\(value)% of your palate map matches \(name)", bundle: .module)
    }

    func bothWant(_ list: String) -> String {
        String(localized: "You both want \(list) in a glass.", bundle: .module)
    }

    func dinnerTitle(_ name: String) -> String {
        String(localized: "The perfect dinner for You & \(name)", bundle: .module)
    }

    func youAnd(_ name: String) -> String { String(localized: "You and \(name)", bundle: .module) }

    func removeTitle(_ name: String) -> String { String(localized: "Remove \(name)?", bundle: .module) }

    func removeBody(_ name: String) -> String {
        String(localized: "\(name) won't be told. You can add each other again later.", bundle: .module)
    }
}
