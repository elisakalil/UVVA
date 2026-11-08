import Core

@MainActor
protocol DeleteNoteUseCaseProtocol {
    /// "Delete" (CELLAR-R28): the entry leaves the Cellar and its rating leaves the map.
    func execute(_ entry: CellarEntry) async throws
}
