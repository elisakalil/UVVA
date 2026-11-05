import Core
import Foundation

@MainActor
struct RequestContactsAccessUseCase: RequestContactsAccessUseCaseProtocol {
    let contacts: any ContactsProviding

    func execute() async -> Bool { await contacts.requestAccess() }
}
