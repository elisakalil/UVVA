import Core
import Foundation

@MainActor
protocol SignOutUseCaseProtocol {
    func execute() async
}
