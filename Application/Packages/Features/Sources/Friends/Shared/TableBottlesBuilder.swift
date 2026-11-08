import Core
import Foundation

/// The bottles of a table as the screens show them, shared by the table for two and the group table.
struct TableBottlesBuilder {
    var resources: TableResourcesUIModel

    func rows(_ bottles: [TableBottle], shared: [PalateAxis]) -> [TableBottleUIModel] {
        bottles.map { bottle in
            let axis = bottle.axis.label.lowercased()
            return TableBottleUIModel(
                id: bottle.wine.id,
                courseText: resources.course(bottle.course),
                wineName: bottle.wine.name,
                producer: bottle.wine.producer,
                axisText: bottle.axis.label,
                why: shared.contains(bottle.axis) ? resources.sharedWhy(axis) : resources.leaningWhy(axis),
                dishTitle: bottle.recipe.title)
        }
    }

    /// "acidity", "acidity and fruit", "acidity, fruit and spice".
    static func list(_ axes: [PalateAxis], resources: TableResourcesUIModel) -> String {
        let names = axes.map { $0.label.lowercased() }
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        default: return resources.joined(names.dropLast().joined(separator: ", "), names[names.count - 1])
        }
    }
}
