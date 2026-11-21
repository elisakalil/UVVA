import Core
import Foundation
import Match

/// What a table shows of its dinner, for two or for a group: the choices (FRI-R13a), the bottles as rows of the wine
/// card (FRI-R12 "Open this together") and how to make each dish (FRI-R15a). Pure.
struct TableDinnerBuilder {
    var resources: DinnerResourcesUIModel
    var table: TableResourcesUIModel

    /// FRI-R13a: the choices of the dinner, as chips.
    func dinner(_ preferences: DinnerPreferences, now: Date, isStale: Bool) -> DinnerUIModel {
        DinnerUIModel(
            courses: TableCourse.allCases.map {
                .init(value: $0, title: table.course($0), isOn: preferences.courses.contains($0))
            },
            food: DinnerPreferences.Food.allCases.map { food in
                .init(value: food, title: resources.food(food), isOn: preferences.food == food)
            },
            season: .init(value: true, title: resources.inSeason(resources.season(DinnerPreferences.season(of: now))),
                          isOn: preferences.inSeason),
            time: DinnerPreferences.Time.allCases.map { time in
                let title = time == .quick ? resources.quick(DinnerPreferences.quickMinutes) : resources.anyTimeText
                return .init(value: time, title: title, isOn: preferences.time == time)
            },
            buttonTitle: isStale ? resources.setAgainButtonText : resources.setTableButtonText)
    }

    /// A row of a wine card: the wine and its producer, the reading and how strong the wine is on it.
    func wineRow(_ wine: Wine, axis: PalateAxis) -> WineCardRowUIModel {
        WineCardRowUIModel(id: wine.id, title: wine.displayName, axisName: axis.label,
                           axisText: resources.wineAxis(axis, score: wine.profile[axis]))
    }

    /// FRI-R15a: a course of the table and how to make its dish, as the Home writes a recipe (HOME-R09).
    func recipe(_ bottle: TableBottle) -> TableRecipeUIModel {
        let dish = Pairing.dish(from: bottle.recipe)
        return TableRecipeUIModel(id: bottle.wine.id, courseText: table.course(bottle.course),
                                  wineText: TableShareBuilder.wine(bottle.wine), title: dish.title, why: dish.why,
                                  servesText: dish.serves ?? "", ingredients: dish.ingredients, steps: dish.steps)
    }
}
