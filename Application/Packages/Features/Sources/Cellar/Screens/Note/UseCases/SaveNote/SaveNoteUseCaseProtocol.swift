import Core

@MainActor
protocol SaveNoteUseCaseProtocol {
    /// "Save changes" (CELLAR-R27): keeps the verdict and the note, and moves the map when the verdict changed.
    func execute(_ entry: CellarEntry, verdict: Verdict?, note: String) async throws
}
