import Core
import Foundation

@MainActor
public struct QuizFactory: QuizFactoryProtocol {
    private let questions: any QuizQuestionRepository
    private let maps: any PalateMapRepository
    private let now: () -> Date

    public init(questions: any QuizQuestionRepository, maps: any PalateMapRepository,
                now: @escaping () -> Date = Date.init) {
        self.questions = questions
        self.maps = maps
        self.now = now
    }

    public func makeViewModel(entry: QuizEntry, firstName: String?,
                              coordinator: any QuizCoordinatorProtocol) -> QuizViewModel {
        QuizViewModel(entry: entry, firstName: firstName,
                      loadQuestionsUseCase: LoadQuizQuestionsUseCase(questions: questions),
                      saveMapUseCase: SaveQuizMapUseCase(maps: maps, now: now), coordinator: coordinator)
    }
}
