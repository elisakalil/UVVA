import Core

@MainActor
protocol SaveNewNoteUseCaseProtocol {
    /// "Save note" or "Add to cellar" (CELLAR-R19, R20, R13b).
    func execute(_ draft: NewNoteDraft) async throws
}
