@MainActor
protocol DeclineRequestUseCaseProtocol {
    func execute(_ senderID: String) async throws
}
