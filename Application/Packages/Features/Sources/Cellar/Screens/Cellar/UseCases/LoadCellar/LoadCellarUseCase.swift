import Core
import Foundation

/// Reads every entry of the Cellar, newest first (CELLAR-R02).
struct LoadCellarUseCase: LoadCellarUseCaseProtocol {
    let cellar: any CellarRepository

    func execute() async throws -> [CellarEntry] {
        try await cellar.entrySummaries()
    }

    func entry(_ wineKey: String) async throws -> CellarEntry? {
        try await cellar.entry(wineKey)
    }

    func frontPhotos(for wineKeys: [String]) async throws -> [String: Data] {
        try await cellar.frontPhotos(for: wineKeys)
    }
}
