import Core
import Foundation

/// The words of "Set the perfect dinner" (FRI-R13a) and of the table's sheet (FRI-R15a), for two or for a group.
struct DinnerResourcesUIModel {
    var setTableButtonText = String(localized: "Set the perfect dinner", bundle: .module)
    var setAgainButtonText = String(localized: "Set it again", bundle: .module)
    var coursesText = String(localized: "Courses", bundle: .module)
    var onTheTableText = String(localized: "On the table", bundle: .module)
    var whenText = String(localized: "When", bundle: .module)
    var anyTimeText = String(localized: "No rush", bundle: .module)
    var howToMakeText = String(localized: "How to make it", bundle: .module)
    var ingredientsText = String(localized: "You'll need", bundle: .module)
    var methodText = String(localized: "Method", bundle: .module)

    /// FRI-R13a "On the table".
    func food(_ food: DinnerPreferences.Food) -> String {
        switch food {
        case .anything: String(localized: "Anything", bundle: .module)
        case .vegetarian: String(localized: "Vegetarian", bundle: .module)
        case .vegan: String(localized: "Vegan", bundle: .module)
        case .pasta: String(localized: "Pasta", bundle: .module)
        case .risotto: String(localized: "Risotto", bundle: .module)
        case .fish: String(localized: "Fish", bundle: .module)
        case .seafood: String(localized: "Seafood", bundle: .module)
        case .poultry: String(localized: "Poultry", bundle: .module)
        case .meat: String(localized: "Meat", bundle: .module)
        case .pork: String(localized: "Pork", bundle: .module)
        }
    }

    /// "Under 45 min".
    func quick(_ minutes: Int) -> String { String(localized: "Under \(minutes) min", bundle: .module) }

    /// "In season · Autumn".
    func inSeason(_ season: String) -> String { String(localized: "In season · \(season)", bundle: .module) }

    func season(_ name: String) -> String {
        switch name {
        case "spring": String(localized: "Spring", bundle: .module)
        case "summer": String(localized: "Summer", bundle: .module)
        case "autumn": String(localized: "Autumn", bundle: .module)
        default: String(localized: "Winter", bundle: .module)
        }
    }

    /// FRI-R11, R12: under a wine of a card, the reading it leans on and how strong the wine is on it, as the
    /// Home's "Wines for your palate" ("High acidity", "Full body").
    func wineAxis(_ axis: PalateAxis, score: Double) -> String {
        let level = score >= 7 ? 2 : score <= 4 ? 0 : 1
        switch (axis, level) {
        case (.body, 2): return String(localized: "Full body", bundle: .module)
        case (.body, 0): return String(localized: "Light body", bundle: .module)
        case (.body, _): return String(localized: "Medium body", bundle: .module)
        case (_, 2): return String(localized: "High \(axis.label.lowercased())", bundle: .module)
        case (_, 0): return String(localized: "Low \(axis.label.lowercased())", bundle: .module)
        default: return String(localized: "Medium \(axis.label.lowercased())", bundle: .module)
        }
    }
}
