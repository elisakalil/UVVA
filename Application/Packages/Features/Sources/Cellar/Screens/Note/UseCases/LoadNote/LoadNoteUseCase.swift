import Core

@MainActor
struct LoadNoteUseCase: LoadNoteUseCaseProtocol {
    let wines: any WineLookup

    func execute(_ wineKey: String) async -> Wine? {
        try? await wines.wines(keys: [wineKey])[wineKey]
    }
}
