import Core

@MainActor
struct DeleteNoteUseCase: DeleteNoteUseCaseProtocol {
    let cellar: any CellarRepository
    let recalculate: any RecalculateMapUseCaseProtocol
    /// Where a scanned wine is kept; nil in previews.
    var catalog: (any LabelCatalogRepository)?

    /// CELLAR-R28: the entry leaves, its rating leaves the map, and a wine only its scan brought leaves with it, so a
    /// bad reading is not found again on the next scan.
    func execute(_ entry: CellarEntry) async throws {
        try await cellar.delete(entry.id)
        // The map is worked out again first: it still looks the wine up.
        if entry.verdict != nil { try await recalculate.execute(changing: entry.id, to: nil) }
        try await catalog?.forgetScanned(entry.id)
    }
}
