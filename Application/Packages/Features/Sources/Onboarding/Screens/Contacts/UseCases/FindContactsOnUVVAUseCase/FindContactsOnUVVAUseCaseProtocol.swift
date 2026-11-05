import Core
import Foundation

@MainActor
protocol FindContactsOnUVVAUseCaseProtocol {
    func execute(excluding userID: String?) async -> DiscoveredContacts
}
