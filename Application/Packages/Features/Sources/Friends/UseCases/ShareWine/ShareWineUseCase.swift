import Core
import Foundation
import OSLog

/// FRI-R11b, R11c: wines sent through the public database (`WineSharingService` of Core). The wine a friend sent is
/// read from the catalog on the phone (`WineLookup`), and from what the sender saw when the catalog does not have it.
@MainActor
struct ShareWineUseCase: ShareWineUseCaseProtocol {
    let sharing: (any WineSharingService)?
    let wines: (any WineLookup)?
    private let logger = Logger(subsystem: "app.uvva", category: "friends")

    init(sharing: (any WineSharingService)?, wines: (any WineLookup)?) {
        self.sharing = sharing
        self.wines = wines
    }

    var isAvailable: Bool { sharing != nil }

    func send(_ wine: Wine, from user: FriendsUser, to friendID: String) async throws {
        guard let sharing else { return }
        try await sharing.sendWine(wine, from: user.id, fromName: user.firstName, to: friendID)
    }

    func received(userID: String) async -> [ReceivedWine] {
        guard let sharing else { return [] }
        do {
            return await resolve(try await sharing.sharedWines(to: userID))
        } catch {
            logger.error("Sent wines were not read: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func received(id: String) async -> ReceivedWine? {
        guard let sharing, let record = try? await sharing.sharedWine(id: id) else { return nil }
        return await resolve([record]).first
    }

    private func resolve(_ records: [SharedWineRecord]) async -> [ReceivedWine] {
        let known = (try? await wines?.wines(keys: Set(records.map(\.wineID)))) ?? [:]
        return records.compactMap { record in
            guard let wine = known[record.wineID] ?? record.snapshot?.wine(id: record.wineID) else { return nil }
            return ReceivedWine(id: record.id, fromID: record.from, fromName: record.fromName, wine: wine,
                                sentAt: record.sentAt)
        }
    }
}
