import Core
import Foundation

@MainActor
protocol ReadWineListUseCaseProtocol {
    /// One page of the list (WINELIST-R03, R04, R05): its text read on the phone, sorted into wines, each found in the
    /// catalog or estimated. Throws when the photo cannot be read at all.
    func execute(_ photo: Data) async throws -> WineListPage
}
