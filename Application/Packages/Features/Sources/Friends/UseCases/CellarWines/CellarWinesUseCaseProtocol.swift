@MainActor
protocol CellarWinesUseCaseProtocol {
    /// The wines already in the Cellar, so the wine sheet shows "In your cellar" for them (FRI-R11, HOME-R24).
    func wineKeys() async -> Set<String>
}
