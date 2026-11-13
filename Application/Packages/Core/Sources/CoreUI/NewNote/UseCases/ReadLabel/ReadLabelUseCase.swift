import Core
import Foundation
import Match
import OSLog

/// CELLAR-R17, without a network: the text of the photos (Vision), sorted by the model on the phone when there is
/// one, filled in by the parser, then looked up in the catalog. A wine the catalog does not have is made from what
/// was read, as soon as there is a name.
@MainActor
struct ReadLabelUseCase: ReadLabelUseCaseProtocol {
    let reader: any LabelReading
    let structurer: any LabelStructuring
    let catalog: LabelCatalogCache
    let now: () -> Date
    /// Where each step of the reading is written down, in debug builds.
    let log: LabelReadingLog?
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(reader: any LabelReading, structurer: any LabelStructuring, catalog: LabelCatalogCache,
         now: @escaping () -> Date, log: LabelReadingLog? = nil) {
        self.reader = reader
        self.structurer = structurer
        self.catalog = catalog
        self.now = now
        self.log = log
    }

    func execute(front: Data, back: Data) async -> LabelReadResult {
        do {
            let text = try await reader.read(front: front, back: back)
            var entry = LabelReadingLog.Entry(front: text.front.map(\.text), back: text.back.map(\.text))
            defer { log?.record(entry) }
            guard !text.isEmpty else { return .failed }
            let prepared = try await catalog.load()
            let year = Calendar(identifier: .gregorian).component(.year, from: now())
            let parsed = LabelParser.parse(text, vocabulary: prepared.vocabulary, currentYear: year)
            let result = await structurer.structure(text)
            let structured = result.facts
            entry.parsed = parsed
            entry.structured = structured
            entry.modelFailure = result.failure
            entry.modelContext = result.context
            let facts = structured?.filling(from: parsed) ?? parsed
            if let match = LabelMatch.best(for: facts, in: prepared.index), match.isConfident {
                entry.match = match.wine.displayName
                return .read(match.wine)
            }
            if facts.hasName, let profile = ProfileEstimate.estimate(grapes: facts.grapes, type: facts.type,
                                                                     region: facts.region, in: prepared.wines) {
                return .read(ScannedWine.make(facts, profile: profile))
            }
            return .nameless(facts)
        } catch {
            logger.error("Label reading failed: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
    }
}
