import Core
import Foundation

@MainActor
protocol LoadYouUseCaseProtocol {
    func execute(previous: YouContent) async -> YouContent
}
