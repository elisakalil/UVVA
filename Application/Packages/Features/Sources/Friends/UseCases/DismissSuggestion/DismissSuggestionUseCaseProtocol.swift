@MainActor
protocol DismissSuggestionUseCaseProtocol {
    func execute(_ userID: String) async throws
}
