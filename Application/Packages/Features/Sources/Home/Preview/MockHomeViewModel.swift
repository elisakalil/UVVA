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
            isLoading: false,
            notifications: HomeContentModel.full.notifications
        )
    }

    func loadIfNeeded() async {}
    func openCourse(_ id: String) {}
    func openLearn(_ kind: CourseKind) {}
    func scan() {}
    func openFriends() {}
    func openFriendTable(_ id: String) {}
    func openMapHistory() {}
    func addToCellar(_ wine: Wine) async {
        uiModel.cellarWineKeys.insert(wine.id)
        uiModel.notice = uiModel.resources.savedToCellarNotice(wine)
    }
}
#endif
