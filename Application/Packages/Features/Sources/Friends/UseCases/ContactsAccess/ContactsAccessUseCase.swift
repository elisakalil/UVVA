import Core
import Foundation

/// FRI-R07a: Quick add asks again when access was never given; once iOS no longer asks, only the Settings can.
@MainActor
struct ContactsAccessUseCase: ContactsAccessUseCaseProtocol {
    let contacts: any ContactsProviding

    func current() -> ContactsAccess { contacts.access() }

    func request() async -> ContactsAccess {
        _ = await contacts.requestAccess()
        return contacts.access()
    }
}
