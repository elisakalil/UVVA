import Core
import Foundation

@MainActor
public struct QuizFactory: QuizFactoryProtocol {
    private let questions: any QuizQuestionRepository
    private let maps: any PalateMapRepository
    private let catalog: (any CatalogRepository)?
    private let now: () -> Date

    /// Without a catalog, "Draw the map" reads the answers on the ruler with no wines to settle among (QUIZ-R04b).
    public init(questions: any QuizQuestionRepository, maps: any PalateMapRepository,
                catalog: (any CatalogRepository)? = nil, now: @escaping () -> Date = Date.init) {
        self.questions = questions
        self.maps = maps
        self.catalog = catalog
        self.now = now
    }

    public func makeViewModel(entry: QuizEntry, firstName: String?,
                              coordinator: any QuizCoordinatorProtocol) -> QuizViewModel {
        QuizViewModel(entry: entry, firstName: firstName,
                      loadQuestionsUseCase: LoadQuizQuestionsUseCase(questions: questions),
                      drawMapUseCase: DrawQuizMapUseCase(catalog: catalog),
                      saveMapUseCase: SaveQuizMapUseCase(maps: maps, now: now), coordinator: coordinator)
    }
}
