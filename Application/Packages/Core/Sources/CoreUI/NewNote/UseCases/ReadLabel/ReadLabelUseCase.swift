import Core
import Foundation
import Match
import OSLog

/// CELLAR-R17: the text of the photos (Vision), sorted by the model on the phone when there is one, filled in by the
/// parser, then looked up in the catalog on the phone, and in the public catalog when the phone does not have it
/// (the only step that needs a network, and one the reading does without). A catalog wine gains what the label adds to it; a wine
/// the catalog does not have is made from what was read, as soon as there is a name. Either way the model then adds
/// dishes to the pairings found.
@MainActor
struct ReadLabelUseCase: ReadLabelUseCaseProtocol {
    let reader: any LabelReading
    let structurer: any LabelStructuring
    let pairer: any PairingSuggesting
    let catalog: LabelCatalogCache
    let now: () -> Date
    /// Where each step of the reading is written down, in debug builds.
    let log: LabelReadingLog?
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(reader: any LabelReading, structurer: any LabelStructuring, pairer: any PairingSuggesting,
         catalog: LabelCatalogCache, now: @escaping () -> Date, log: LabelReadingLog? = nil) {
        self.reader = reader
        self.structurer = structurer
        self.pairer = pairer
        self.catalog = catalog
        self.now = now
        self.log = log
    }

    func execute(front: Data, back: Data, backScan: LabelScan?,
                 onStage: @MainActor (LabelReadStage) -> Void) async -> LabelReadResult {
        do {
            onStage(.text)
            let photos = try await reader.read(front: front, back: back)
            let read = Self.merging(photos, backScan: backScan)
            // Allergens in every language, the nutrition table, codes and repeats say nothing of the wine.
            let text = LabelTextCleaner.clean(read)
            var entry = LabelReadingLog.Entry(
                front: text.front.map(\.text),
                back: text.back.map(\.text), backConfidence: text.back.map(\.confidence),
                backScanFrames: backScan.flatMap { $0.frames > 0 ? $0.frames : nil },
                droppedLines: read.lines.count - text.lines.count,
                export: LabelScanExport(front: photos.front, backPhoto: photos.back,
                                        frames: backScan?.readings ?? []))
            defer { log?.record(entry) }
            guard !text.isEmpty else { return .failed }
            let prepared = try await catalog.load()
            let year = Calendar(identifier: .gregorian).component(.year, from: now())
            onStage(.wine)
            let parsed = LabelParser.parse(text, vocabulary: prepared.vocabulary, currentYear: year)
            // The model's window is small: it gets the back label's surest lines, not all of them.
            let result = await structurer.structure(LabelTextCleaner.forModel(text))
            var structured = result.facts
            // A temperature the label does not print is the model's guess.
            if let serving = structured?.serving, !ServingEvidence.isRead(serving, in: text.lines) {
                structured?.serving = nil
            }
            entry.parsed = parsed
            entry.structured = structured
            entry.modelFailure = result.failure
            entry.modelContext = result.context
            // Notes that name no aroma are noise; a producer a letter off the catalog's is the catalog's.
            let facts = prepared.vocabulary.cleaning(structured?.filling(from: parsed) ?? parsed)
            onStage(.catalog)
            let wine: Wine
            if let match = LabelMatch.best(for: facts, in: prepared.index), match.isConfident {
                entry.match = match.wine.displayName
                // A wine scanned before keeps none of the noise an older reading stored in it.
                wine = prepared.vocabulary.cleaning(match.wine)
            } else if let match = await catalog.publicMatch(for: facts) {
                entry.match = match.wine.displayName
                wine = prepared.vocabulary.cleaning(match.wine)
            } else if facts.hasName, let profile = ProfileEstimate.estimate(grapes: facts.grapes, type: facts.type,
                                                                            region: facts.region, in: prepared.wines) {
                wine = ScannedWine.make(facts, profile: profile)
            } else {
                return .nameless(facts)
            }
            entry.pairingsFound = wine.pairings
            onStage(.pairings)
            // What the catalog says of the appellation read, for the certificate (CELLAR-R30).
            let enriched = await pairer.enriching(prepared.vocabulary.describingAppellation(of: wine))
            entry.pairingSuggestion = enriched.suggestion
            return .read(enriched.wine)
        } catch {
            logger.error("Label reading failed: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
    }

    /// The back label as the scan read it, with the back photo as one frame more: its sharp still often reads the
    /// small print the video blurs. Without a scan, the photos' text as it is.
    static func merging(_ text: LabelText, backScan: LabelScan?) -> LabelText {
        guard var scan = backScan, scan.frames > 0 else { return text }
        scan.add(text.back)
        return LabelText(text.front + scan.lines(side: .back))
    }
}
