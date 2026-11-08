@MainActor
protocol FindQuickAddUseCaseProtocol {
    /// Contacts on UVVA with a map, other than the user and the ids in `excluding`, by name.
    func execute(userID: String, excluding: Set<String>) async -> [QuickAddSuggestion]
}
