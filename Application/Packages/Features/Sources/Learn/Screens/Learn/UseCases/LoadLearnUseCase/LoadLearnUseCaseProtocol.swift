import Core
import Foundation

@MainActor
protocol LoadLearnUseCaseProtocol {
    func execute(previous: LearnContent) async -> LearnContent
}
