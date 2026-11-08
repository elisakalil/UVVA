import Core
import Foundation

struct GroupTableResourcesUIModel {
    var closeText = String(localized: "Close", bundle: .module)
    var closeIcon = "xmark"
    var whereItLandsText = String(localized: "Where the table lands", bundle: .module)
    var averageText = String(localized: "The table", bundle: .module)
    var boldestText = String(localized: "The boldest reading", bundle: .module)
    var readingByReadingText = String(localized: "Reading by reading", bundle: .module)
    var expandText = String(localized: "Expand", bundle: .module)
    var collapseText = String(localized: "Collapse", bundle: .module)
    var perfectTableText = String(localized: "The perfect table", bundle: .module)
    var youText = String(localized: "You", bundle: .module)
    var table = TableResourcesUIModel()

    func match(_ value: Int, _ count: Int) -> String {
        String(localized: "\(value)% match across all \(count) palate maps at the table", bundle: .module)
    }

    func allWant(_ list: String) -> String {
        String(localized: "You all want \(list) in a glass.", bundle: .module)
    }

    func nothingLinesUp(_ count: Int) -> String {
        String(localized: "Nothing lines up across all \(count) — the menu is built on compromise.", bundle: .module)
    }

    func dinnerTitle(_ count: Int) -> String {
        String(localized: "The perfect dinner for The \(count) of you", bundle: .module)
    }

    func footer(_ count: Int) -> String {
        String(localized: "Read from all \(count) palate maps · UVVA", bundle: .module)
    }

    func range(_ low: String, _ high: String) -> String { "\(low)–\(high)" }

    func spread(_ spread: AxisSpread) -> String {
        switch spread {
        case .same: String(localized: "Same", bundle: .module)
        case .closest: String(localized: "Closest", bundle: .module)
        case .someGive: String(localized: "Some give", bundle: .module)
        case .widest: String(localized: "Widest", bundle: .module)
        }
    }

    func spreadPhrase(_ spread: AxisSpread) -> String {
        switch spread {
        case .same: String(localized: "Everyone reads it the same way.", bundle: .module)
        case .closest: String(localized: "Close enough to share a bottle.", bundle: .module)
        case .someGive: String(localized: "Someone gives a little here.", bundle: .module)
        case .widest: String(localized: "This is where the table splits.", bundle: .module)
        }
    }
}
