import Core

@MainActor
struct AddWineToCellarUseCase: AddWineToCellarUseCaseProtocol {
    let cellar: any CellarRepository

    func execute(_ wine: Wine) async throws {
        try await cellar.addWantToTry(wine)
    }
}
