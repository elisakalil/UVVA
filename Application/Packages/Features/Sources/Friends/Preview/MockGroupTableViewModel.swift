#if DEBUG
import Combine
import Core
import Foundation

/// A table of four, for previews.
final class MockGroupTableViewModel: GroupTableViewModelProtocol {
    let id = "marina+bia+rui"
    @Published private(set) var uiModel = GroupTableUIModel()

    init() {
        var model = GroupTableUIModel()
        model.membersText = "You, Marina, Bia and Rui"
        model.memberNames = ["Marina", "Bia", "Rui", "You"]
        model.mapsText = "4 maps · one bottle"
        model.matchTitle = "71% match across all 4 palate maps at the table"
        model.matchValueText = "71%"
        model.matchCaption = "match across all 4 palate maps at the table"
        model.phrase = "You all want fruit in a glass."
        model.averageChart = [0.3, 0.6, 0.4, 0.4, 0.3, 0.2, 0.7, 0.75]
        model.boldestChart = [0.5, 0.8, 0.8, 0.8, 0.7, 0.4, 0.9, 0.85]
        model.isReadingsExpanded = true
        model.readings = [
            AxisSpreadRowUIModel(name: "Acidity", spreadText: "Some give", phrase: "Someone gives a little here.", rangeText: "6–8",
                                 low: 0.66, high: 0.88, middle: 0.75, isClose: false),
            AxisSpreadRowUIModel(name: "Fruit", spreadText: "Closest", phrase: "Close enough to share a bottle.", rangeText: "6.5–7.5",
                                 low: 0.72, high: 0.83, middle: 0.78, isClose: true)
        ]
        model.dinnerTitle = "The perfect dinner for The 4 of you"
        model.footerText = "Read from all 4 palate maps · UVVA"
        model.guestsText = "The 4 of you"
        let friend = MockFriendProfileViewModel().uiModel
        model.bottles = friend.bottles
        model.togetherWines = friend.bottles?.map {
            WineCardRowUIModel(id: $0.id, title: $0.wineName, axisName: "", axisText: $0.axisText)
        }
        model.recipes = friend.recipes
        model.dinner = TableDinnerBuilder(resources: model.resources.dinner, table: model.resources.table)
            .dinner(DinnerPreferences(), now: .now, isStale: false)
        model.canScan = true
        uiModel = model
    }

    func load() async {}
    func toggleReadings() {}
    func setTable() async {}
    func closeTable() {}
    func toggleCourse(_ course: TableCourse) {}
    func pickFood(_ food: DinnerPreferences.Food) {}
    func toggleInSeason() {}
    func pickTime(_ time: DinnerPreferences.Time) {}
    func openTableWine(_ id: String) {}
    func closeWine() {}
    func sendWine() async {}
    func addWineToCellar() {}
    func wineDismissed() {}
    func scanWine() {}
    func closeScanner() {}
    func scannerDismissed() {}
    func openShare() {}
    func closeShare() {}
    func close() {}
}
#endif
