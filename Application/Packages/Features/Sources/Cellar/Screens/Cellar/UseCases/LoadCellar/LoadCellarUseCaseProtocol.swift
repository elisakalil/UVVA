import Core
import Foundation

protocol LoadCellarUseCaseProtocol: Sendable {
    func entry(_ wineKey: String) async throws -> CellarEntry?
    func frontPhotos(for wineKeys: [String]) async throws -> [String: Data]
    func execute() async throws -> [CellarEntry]
}

extension LoadCellarUseCaseProtocol {
    func entry(_ wineKey: String) async throws -> CellarEntry? {
        try await execute().first { $0.id == wineKey }
    }

    func frontPhotos(for wineKeys: [String]) async throws -> [String: Data] { [:] }
}
