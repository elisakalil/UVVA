import Core
import Foundation
import Match

/// WINELIST-R03 to R05: the page's text (Vision, on the phone), its rows and sections, and each wine looked up in the
/// catalog on the phone, or made from the grape, region and type the list prints. No network.
@MainActor
struct ReadWineListUseCase: ReadWineListUseCaseProtocol {
    let reader: any WineListReading
    let catalog: LabelCatalogCache
    let now: () -> Date

    func execute(_ photo: Data) async throws -> WineListPage {
        let lines = try await reader.read(photo)
        let prepared = try await catalog.load()
        let year = Calendar(identifier: .gregorian).component(.year, from: now())
        // Hundreds of lookups over 10 000 wines: off the main actor.
        return await Task.detached(priority: .userInitiated) {
            let entries = WineListParser.entries(in: lines)
            let wines = entries.compactMap {
                WineListIdentifier.wine(for: $0, index: prepared.index, vocabulary: prepared.vocabulary,
                                        wines: prepared.wines, currentYear: year)
            }
            return WineListPage(wines: wines, currency: WineListParser.currency(in: lines))
        }.value
    }
}
