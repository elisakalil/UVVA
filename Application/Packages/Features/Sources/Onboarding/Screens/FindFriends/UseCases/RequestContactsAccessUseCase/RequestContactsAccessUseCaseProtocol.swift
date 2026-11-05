import Core
import Foundation

@MainActor
protocol RequestContactsAccessUseCaseProtocol {
    func execute() async -> Bool
}
