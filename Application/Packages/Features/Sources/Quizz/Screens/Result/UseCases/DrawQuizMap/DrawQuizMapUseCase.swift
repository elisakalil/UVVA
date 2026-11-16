import Core
import Foundation
import Match

@MainActor
struct DrawQuizMapUseCase: DrawQuizMapUseCaseProtocol {
    /// Nil, or a catalog that cannot be read yet: the answers are read on the ruler and held, with no wines to settle
    /// among (QUIZ-R04b).
    let catalog: (any CatalogRepository)?

    func execute(_ answers: [PalateAxis: Int]) async -> PalateMap {
        let read = WineRuler.map(answers)
        let wines = (try? await catalog?.winesClosest(to: read, limit: QuizMapBuilder.candidateCount)) ?? []
        return QuizMapBuilder.map(answers, among: wines)
    }
}
