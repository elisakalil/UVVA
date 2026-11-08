import Core

@MainActor
protocol LoadNoteUseCaseProtocol {
    /// The catalog wine behind an entry, for UVVA's reading; nil for a wine not in the catalog.
    func execute(_ wineKey: String) async -> Wine?
}
