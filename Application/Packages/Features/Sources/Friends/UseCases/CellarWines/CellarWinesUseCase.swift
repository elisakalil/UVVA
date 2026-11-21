import Core
import Foundation

/// FRI-R11: which wines the Cellar holds, read from the shared `CellarRepository` of Core. Without one, none.
@MainActor
struct CellarWinesUseCase: CellarWinesUseCaseProtocol {
    let cellar: (any CellarRepository)?

    func wineKeys() async -> Set<String> {
        guard let cellar else { return [] }
        return (try? await cellar.wineKeys()) ?? []
    }
}
