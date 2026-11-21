#if DEBUG
import Combine
import Core
import Foundation

/// Marina, with the bottles worked out, for previews.
final class MockFriendProfileViewModel: FriendProfileViewModelProtocol {
    let id = "marina"
    @Published private(set) var uiModel = FriendProfileUIModel()

    init(tab: FriendProfileTab = .compatibility, isTableOpen: Bool = false) {
        var model = FriendProfileUIModel()
        model.tab = tab
        model.name = "Marina Alves"
        model.signature = "ACIDITY · FRUIT · BODY"
        model.compatibilityText = "82%"
        model.mapTitle = "Marina Map"
        model.friendChart = [0.4, 0.6, 0.3, 0.3, 0.2, 0.2, 0.85, 0.75]
        model.userChart = [0.3, 0.5, 0.4, 0.3, 0.4, 0.1, 0.75, 0.65]
        model.strongAxes = [6, 7]
        model.caption = "Bright and juicy, with acidity in front."
        model.matchTitle = "82% of your palate map matches Marina Alves"
        model.matchCaption = "of your palate map matches Marina Alves"
        model.overlapPhrase = "You both want acidity and fruit in a glass."
        model.compareRows = [
            FriendCompareRowUIModel(name: "Acidity", verdict: "Close", mineLevel: 7, theirsLevel: 8, isSame: false),
            FriendCompareRowUIModel(name: "Fruit", verdict: "Same", mineLevel: 6, theirsLevel: 6, isSame: true),
            FriendCompareRowUIModel(name: "Oak", verdict: "Apart", mineLevel: 4, theirsLevel: 2, isSame: false)
        ]
        model.dinnerTitle = "The perfect dinner for You & Marina Alves"
        model.guestsText = "You & Marina Alves"
        model.bottles = [
            TableBottleUIModel(id: "1", courseText: "Starter", wineName: "Alvarinho", producer: "Soalheiro",
                               axisText: "Acidity", why: "Where your maps meet: acidity.", dishTitle: "Grilled sardines"),
            TableBottleUIModel(id: "2", courseText: "Main", wineName: "Chianti Classico", producer: "Isole e Olena",
                               axisText: "Fruit", why: "Where your maps meet: fruit.", dishTitle: "Mushroom risotto"),
            TableBottleUIModel(id: "3", courseText: "Dessert", wineName: "10 Year Tawny", producer: "Graham's",
                               axisText: "Fruit", why: "Leans on fruit, the strongest reading at the table.",
                               dishTitle: "Pastel de nata")
        ]
        model.recipes = [
            TableRecipeUIModel(id: "1", courseText: "Starter", wineText: "Alvarinho, Soalheiro", title: "Grilled sardines",
                               why: "Salt and char want the wine's acidity.", servesText: "Serves 4 · 25 min",
                               ingredients: ["8 sardines, gutted", "1 lemon", "Coarse salt"],
                               steps: ["Salt the sardines for 10 minutes.", "Grill over high heat, 3 minutes a side."])
        ]
        model.isTableOpen = isTableOpen
        uiModel = model
    }

    func load() async {}
    func selectTab(_ tab: FriendProfileTab) {}
    func setTable() async { uiModel.isTableOpen = true }
    func closeTable() { uiModel.isTableOpen = false }
    func toggleCourse(_ course: TableCourse) {}
    func pickFood(_ food: DinnerPreferences.Food) {}
    func toggleInSeason() {}
    func pickTime(_ time: DinnerPreferences.Time) {}
    func askToRemove() {}
    func cancelRemoval() {}
    func confirmRemoval() async {}
    func openWine(_ id: String) {}
    func openTableWine(_ id: String) {}
    func closeWine() {}
    func sendWine() async {}
    func scanWine() {}
    func closeScanner() {}
    func scannerDismissed() {}
    func openShare() {}
    func closeShare() {}
    func close() {}
}
#endif
