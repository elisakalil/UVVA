import Core

@MainActor
struct DeleteNoteUseCase: DeleteNoteUseCaseProtocol {
    let cellar: any CellarRepository
    let recalculate: any RecalculateMapUseCaseProtocol

    func execute(_ entry: CellarEntry) async throws {
        try await cellar.delete(entry.id)
        if entry.verdict != nil { try await recalculate.execute(changing: entry.id, to: nil) }
    }
}
