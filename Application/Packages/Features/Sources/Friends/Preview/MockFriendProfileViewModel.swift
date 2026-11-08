#if DEBUG
import Combine
import Foundation

/// Marina, with the bottles worked out, for previews.
final class MockFriendProfileViewModel: FriendProfileViewModelProtocol {
    let id = "marina"
    @Published private(set) var uiModel = FriendProfileUIModel()

    init(tab: FriendProfileTab = .compatibility) {
        var model = FriendProfileUIModel()
        model.tab = tab
        model.name = "Marina Alves"
        model.signature = "ACIDITY · FRUIT · BODY"
        model.compatibilityText = "82%"
        model.palateTitle = "Marina Alves's palate"
        model.friendChart = [0.4, 0.6, 0.3, 0.3, 0.2, 0.2, 0.85, 0.75]
        model.userChart = [0.3, 0.5, 0.4, 0.3, 0.4, 0.1, 0.75, 0.65]
        model.strongAxes = [6, 7]
        model.caption = "Bright and juicy, with acidity in front."
        model.matchTitle = "82% of your palate map matches Marina Alves"
        model.overlapPhrase = "You both want acidity and fruit in a glass."
        model.dinnerTitle = "The perfect dinner for You & Marina Alves"
        model.bottles = [
            TableBottleUIModel(id: "1", courseText: "Starter", wineName: "Alvarinho", producer: "Soalheiro",
                               axisText: "Acidity", why: "Where your maps meet: acidity.", dishTitle: "Grilled sardines"),
            TableBottleUIModel(id: "2", courseText: "Main", wineName: "Chianti Classico", producer: "Isole e Olena",
                               axisText: "Fruit", why: "Where your maps meet: fruit.", dishTitle: "Mushroom risotto"),
            TableBottleUIModel(id: "3", courseText: "Dessert", wineName: "10 Year Tawny", producer: "Graham's",
                               axisText: "Fruit", why: "Leans on fruit, the strongest reading at the table.",
                               dishTitle: "Pastel de nata")
        ]
        uiModel = model
    }

    func load() async {}
    func selectTab(_ tab: FriendProfileTab) {}
    func askToRemove() {}
    func cancelRemoval() {}
    func confirmRemoval() async {}
    func openShare() {}
    func closeShare() {}
    func close() {}
}
#endif
