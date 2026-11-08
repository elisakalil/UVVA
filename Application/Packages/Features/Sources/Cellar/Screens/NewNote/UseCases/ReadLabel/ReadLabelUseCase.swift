import Core
import Foundation
import Match
import OSLog

/// CELLAR-R17, without a network: the text of the photos (Vision), sorted by the model on the phone when there is
/// one, filled in by the parser, then looked up in the catalog.
@MainActor
struct ReadLabelUseCase: ReadLabelUseCaseProtocol {
    let reader: any LabelReading
    let structurer: any LabelStructuring
    let catalog: LabelCatalogCache
    let now: () -> Date
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(reader: any LabelReading, structurer: any LabelStructuring, catalog: LabelCatalogCache,
         now: @escaping () -> Date) {
        self.reader = reader
        self.structurer = structurer
        self.catalog = catalog
        self.now = now
    }

    func execute(front: Data, back: Data) async -> LabelReadResult {
        do {
            let text = try await reader.read(front: front, back: back)
            guard !text.isEmpty else { return .failed }
            let prepared = try await catalog.load()
            let year = Calendar(identifier: .gregorian).component(.year, from: now())
            let parsed = LabelParser.parse(text, vocabulary: prepared.vocabulary, currentYear: year)
            let facts = await structurer.structure(text)?.filling(from: parsed) ?? parsed
            if let match = LabelMatch.best(for: facts, in: prepared.index), match.isConfident {
                return .found(match.wine)
            }
            return .unsure(facts)
        } catch {
            logger.error("Label reading failed: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
    }
}
