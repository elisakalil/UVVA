import Core
import Foundation

/// The words of a table, for two or for a group.
struct TableResourcesUIModel {
    var openTogetherText = String(localized: "Open this together", bundle: .module)
    var buildingText = String(localized: "Reading the maps at the table…", bundle: .module)
    var noBottlesText = String(localized: "No bottle on your phone fits this table yet.", bundle: .module)

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
