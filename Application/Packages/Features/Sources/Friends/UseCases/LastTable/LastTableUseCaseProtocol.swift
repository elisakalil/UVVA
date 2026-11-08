@MainActor
protocol LastTableUseCaseProtocol {
    /// Who was at the last table opened (FRI-R17).
    func load() async -> [String]?
    func save(_ friendIDs: [String]) async
}
