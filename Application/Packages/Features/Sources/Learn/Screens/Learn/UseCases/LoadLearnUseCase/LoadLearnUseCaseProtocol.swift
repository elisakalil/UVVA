import Core
import Foundation

@MainActor
protocol LoadLearnUseCaseProtocol {
    func execute(previous: LearnContentModel) async -> LearnContentModel
}
