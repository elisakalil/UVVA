#if DEBUG
import Combine
import Core
import Foundation

/// A presentation-only preview: no repositories, use cases or application coordinator.
@MainActor
final class MockHomeViewModel: HomeViewModelProtocol {
    @Published var uiModel: HomeUIModel

    init() {
        uiModel = HomeUIModel(
            content: HomeContentUIModel(cards: HomeCardsBuilder().build(from: .full, now: .now),
                                         glossary: MockData.glossary, palateMap: HomeContentModel.full.palateMap),
            isLoading: false
        )
    }

    func loadIfNeeded() async {}
    func openCourse(_ id: String) {}
    func openLearn(_ kind: CourseKind) {}
    func scan() {}
    func openFriends() {}
    func openLastTable() {}
    func openMapHistory() {}
    func addToCellar(_ wine: Wine) async {
        uiModel.cellarWineKeys.insert(wine.id)
        uiModel.notice = uiModel.resources.savedToCellarNotice(wine)
    }
    func rate(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async {
        uiModel.ratedVerdicts[wine.id] = verdict
        uiModel.notice = uiModel.resources.mapUpdatedNotice([(.acidity, true), (.fruit, true)], savedToCellar: addToCellar)
    }
}
#endif
