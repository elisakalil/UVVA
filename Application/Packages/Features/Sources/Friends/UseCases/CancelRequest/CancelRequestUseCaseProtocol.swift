@MainActor
protocol CancelRequestUseCaseProtocol {
    func execute(from userID: String, to friendID: String) async throws
}
