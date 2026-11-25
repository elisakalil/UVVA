import Core
import Foundation
import Match
import SwiftData

/// `CellarRepository` on the Personal store.
public actor CellarStore: StoreActor, CellarRepository {
    public nonisolated let executor: StoreExecutor

    public init(modelContainer: ModelContainer) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.cellar")
    }

    public func entries() throws -> [CellarEntry] {
        let descriptor = FetchDescriptor<CellarEntryEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map(\.entry)
    }

    public func entrySummaries() throws -> [CellarEntry] {
        let descriptor = FetchDescriptor<CellarEntryEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.makeEntry(includingPhotos: false) }
    }

    public func entry(_ wineKey: String) throws -> CellarEntry? {
        try entry(for: wineKey)?.entry
    }

    public func frontPhotos(for wineKeys: [String]) throws -> [String: Data] {
        guard !wineKeys.isEmpty else { return [:] }
        let descriptor = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { wineKeys.contains($0.wineKey) })
        var photos: [String: Data] = [:]
        for entry in try modelContext.fetch(descriptor) {
            photos[entry.wineKey] = entry.photoFront
        }
        return photos
    }

    public func wineKeys() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<CellarEntryEntity>()).map(\.wineKey))
    }

    public func tastedWineKeys() throws -> Set<String> {
        let tasted = CellarEntryEntity.Status.tasted.rawValue
        let descriptor = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { $0.status == tasted })
        return Set(try modelContext.fetch(descriptor).map(\.wineKey))
    }

    public func addWantToTry(_ wine: Wine) throws {
        try addWantToTry(wine, at: Date())
    }

    func addWantToTry(_ wine: Wine, at date: Date) throws {
        guard try entry(for: wine.id) == nil else { return }
        let entry = CellarEntryEntity(wineKey: wine.id, status: .wantToTry, date: date)
        entry.copyFacts(of: wine)
        modelContext.insert(entry)
        try modelContext.save()
    }

    public func addTasted(_ wine: Wine, verdict: Verdict) throws {
        try addTasted(wine, verdict: verdict, at: Date())
    }

    func addTasted(_ wine: Wine, verdict: Verdict, at date: Date) throws {
        let entry: CellarEntryEntity
        if let existing = try self.entry(for: wine.id) {
            entry = existing
            entry.status = CellarEntryEntity.Status.tasted.rawValue
            entry.updatedAt = date
        } else {
            entry = CellarEntryEntity(wineKey: wine.id, status: .tasted, date: date)
            entry.copyFacts(of: wine)
            modelContext.insert(entry)
        }
        entry.verdict = verdict.rawValue
        try modelContext.save()
    }

    @discardableResult
    public func save(_ draft: NewNoteDraft) throws -> CellarEntry? {
        try save(draft, at: Date())
    }

    @discardableResult
    func save(_ draft: NewNoteDraft, at date: Date) throws -> CellarEntry? {
        let existing = try entry(for: draft.wine.id)
        let before = existing?.entry
        // A new entry starts as Want to try; only a verdict makes it Tasted (CELLAR-R01).
        let entry = existing ?? CellarEntryEntity(wineKey: draft.wine.id, status: .wantToTry, date: date)
        if existing == nil { modelContext.insert(entry) }
        entry.copyFacts(of: draft.wine)
        entry.wineProfile = PalateAxis.allCases.map { draft.wine.profile[$0] }
        entry.wineNotes = draft.wine.note ?? ""
        entry.pairings = draft.wine.pairings
        // CELLAR-R13b: what the new note has replaces the old; what it lacks leaves the old in place.
        if draft.status == .tasted, let verdict = draft.verdict {
            entry.status = CellarEntryEntity.Status.tasted.rawValue
            entry.verdict = verdict.rawValue
            if let score = draft.score { entry.score = score }
        }
        if let photo = draft.photoFront { entry.photoFront = photo }
        if let photo = draft.photoBack { entry.photoBack = photo }
        let note = draft.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if draft.replacesNote {
            // CELLAR-R27: an edited note is kept as written, and an emptied one goes.
            entry.note = note.isEmpty ? nil : note
        } else if !note.isEmpty {
            entry.note = note
        }
        entry.updatedAt = date
        try modelContext.save()
        return before
    }

    public func update(_ wineKey: String, verdict: Verdict?, score: Int?, note: String?) throws {
        try update(wineKey, verdict: verdict, score: score, note: note, at: Date())
    }

    public func update(_ wineKey: String, verdict: Verdict?, note: String?) throws {
        try update(wineKey, verdict: verdict, score: nil, note: note, at: Date())
    }

    func update(_ wineKey: String, verdict: Verdict?, score: Int? = nil, note: String?, at date: Date) throws {
        guard let entry = try entry(for: wineKey) else { return }
        if let verdict {
            entry.status = CellarEntryEntity.Status.tasted.rawValue
            entry.verdict = verdict.rawValue
            entry.score = score
        }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        entry.note = trimmed.isEmpty ? nil : trimmed
        entry.updatedAt = date
        try modelContext.save()
    }

    public func delete(_ wineKey: String) throws {
        let descriptor = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { $0.wineKey == wineKey })
        for entry in try modelContext.fetch(descriptor) { modelContext.delete(entry) }
        try modelContext.save()
    }

    private func entry(for key: String) throws -> CellarEntryEntity? {
        var descriptor = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { $0.wineKey == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

private extension CellarEntryEntity {
    /// The entry keeps its own copy of the wine's facts (CELLAR.md §2).
    func copyFacts(of wine: Wine) {
        name = wine.name
        producer = wine.producer
        vintage = wine.vintage
        type = wine.type
        origin = wine.origin
        region = wine.region
        country = wine.country
        grapes = wine.grapes
        alcohol = wine.alcohol
        classification = wine.classification
        designation = wine.designation
        awards = wine.awards.map(\.text)
        oakAging = wine.oakAging?.rawValue
        oakWoods = wine.oakWoods
        // The "Top X%" as the new note showed it, kept as it is (CELLAR-R30).
        certificateTop = Certification.make(for: wine)?.topPercent ?? 0
    }
}

private extension CellarEntryEntity {
    var entry: CellarEntry { makeEntry(includingPhotos: true) }

    func makeEntry(includingPhotos: Bool) -> CellarEntry {
        // An entry saved before region and country were kept falls back on its origin, "Douro, Portugal".
        let parts = origin.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let profile = wineProfile.map { values in
            PalateMap(Dictionary(uniqueKeysWithValues: zip(PalateAxis.allCases, values)))
        }
        return CellarEntry(id: wineKey, name: name, producer: producer, vintage: vintage, type: type,
                           region: region ?? parts.first.flatMap { $0.isEmpty ? nil : $0 },
                           country: country ?? (parts.count > 1 ? parts.last : nil),
                           origin: origin, grapes: grapes,
                           status: CellarEntryStatus(rawValue: status) ?? .wantToTry,
                           verdict: verdict.flatMap(Verdict.init(rawValue:)),
                           note: note, alcohol: alcohol, classification: classification,
                           photoFront: includingPhotos ? photoFront : nil, photoBack: includingPhotos ? photoBack : nil,
                           createdAt: createdAt, updatedAt: updatedAt,
                           wineProfile: profile, wineNotes: wineNotes, pairings: pairings, designation: designation,
                           awards: awards?.compactMap(WineAward.init(text:)), certificateTop: certificateTop,
                           score: score, oakAging: oakAging.flatMap(OakAging.init(rawValue:)),
                           oakWoods: oakWoods ?? [])
    }
}
