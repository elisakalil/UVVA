#if DEBUG
import Combine
import Foundation

/// A table of four, for previews.
final class MockGroupTableViewModel: GroupTableViewModelProtocol {
    let id = "marina+bia+rui"
    @Published private(set) var uiModel = GroupTableUIModel()

    init() {
        var model = GroupTableUIModel()
        model.membersText = "You, Marina, Bia and Rui"
        model.matchTitle = "71% match across all 4 palate maps at the table"
        model.phrase = "You all want fruit in a glass."
        model.averageChart = [0.3, 0.6, 0.4, 0.4, 0.3, 0.2, 0.7, 0.75]
        model.boldestChart = [0.5, 0.8, 0.8, 0.8, 0.7, 0.4, 0.9, 0.85]
        model.isReadingsExpanded = true
        model.readings = [
            AxisSpreadRowUIModel(name: "Acidity", spreadText: "Some give", phrase: "Someone gives a little here.", rangeText: "6–8"),
            AxisSpreadRowUIModel(name: "Fruit", spreadText: "Closest", phrase: "Close enough to share a bottle.", rangeText: "6.5–7.5")
        ]
        model.dinnerTitle = "The perfect dinner for The 4 of you"
        model.footerText = "Read from all 4 palate maps · UVVA"
        model.bottles = MockFriendProfileViewModel().uiModel.bottles
        uiModel = model
    }

    func load() async {}
    func toggleReadings() {}
    func openShare() {}
    func closeShare() {}
    func close() {}
}
#endif
