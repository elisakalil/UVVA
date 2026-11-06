import Core
import Foundation

@MainActor
protocol LoadYouUseCaseProtocol {
    func execute(previous: YouContentModel) async -> YouContentModel
}
