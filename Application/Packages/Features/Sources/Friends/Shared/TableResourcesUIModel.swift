import Core
import Foundation

/// The words of a table, for two or for a group.
struct TableResourcesUIModel {
    var openTogetherText = String(localized: "Open this together", bundle: .module)
    var buildingText = String(localized: "Reading the maps at the table…", bundle: .module)
    var noBottlesText = String(localized: "No bottle on your phone fits this table yet.", bundle: .module)

    var shareText = String(localized: "Share", bundle: .module)
    var shareTitleText = String(localized: "Share this table", bundle: .module)
    var invitedText = String(localized: "You're invited to dinner", bundle: .module)
    var tonightText = String(localized: "Tonight's table", bundle: .module)
    var guideText = String(localized: "What to buy", bundle: .module)
    var shareFooterText = String(localized: "Open the menu on UVVA · uvva.app", bundle: .module)
    var bothLine = String(localized: "Dinner at mine? I built the menu from both our palate maps. Three courses, three bottles.", bundle: .module)
    var allLine = String(localized: "Dinner at mine? I built the menu from all our palate maps. Three courses, three bottles.", bundle: .module)

    func askFor(_ wine: String) -> String { String(localized: "Ask for: \(wine)", bundle: .module) }

    /// "Starter · Alvarinho, Soalheiro — Grilled sardines".
    func menuLine(_ course: String, _ wine: String, _ dish: String) -> String { "\(course) · \(wine) — \(dish)" }

    func course(_ course: TableCourse) -> String {
        switch course {
        case .starter: String(localized: "Starter", bundle: .module)
        case .main: String(localized: "Main", bundle: .module)
        case .dessert: String(localized: "Dessert", bundle: .module)
        }
    }

    func sharedWhy(_ axis: String) -> String {
        String(localized: "Where your maps meet: \(axis).", bundle: .module)
    }

    func leaningWhy(_ axis: String) -> String {
        String(localized: "Leans on \(axis), the strongest reading at the table.", bundle: .module)
    }

    /// "acidity, fruit and spice".
    func joined(_ head: String, _ last: String) -> String {
        String(localized: "\(head) and \(last)", bundle: .module)
    }
}
