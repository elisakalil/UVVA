import Combine
import Core
import Foundation
import OSLog
import UIKit

/// The Cellar tab (CELLAR.md §3): the covers or the list, the filters and the search.
@MainActor
public final class CellarViewModel: CellarViewModelProtocol {
    @Published public private(set) var uiModel = CellarUIModel()
    @Published public private(set) var note: NoteViewModel?

    /// The banner shows on the first visits only, for a few seconds each.
    static let bannerVisits = 2

    private var entries: [CellarEntry] = [] { didSet { refresh() } }
    private var initialRead: Task<Void, Never>?
    private var mutations: Task<Void, Never>?
    private var mutationVersion = 0
    private var firstPhotos: (items: [CellarItemUIModel], mode: CellarViewMode, task: Task<[String: UIImage], Error>)?
    private var noteRead: Task<Void, Never>?
    private var readFailed = false
    private var isLoaded = false
    private var didOpen = false
    private var filters: [CellarFacet: String] = [:] { didSet { refresh() } }
    private var openFacet: CellarFacet? { didSet { refresh() } }
    private var query = "" { didSet { refresh() } }
    private var isBannerVisible = false { didSet { refresh() } }
    private var bannerTask: Task<Void, Never>?
    private var isNoteSavedVisible = false { didSet { refresh() } }
    private var noteSavedTask: Task<Void, Never>?

    private let loadCellar: any LoadCellarUseCaseProtocol
    private let preferences: any CellarPreferencesProtocol
    private let makeNote: (CellarEntry, _ owner: CellarViewModel) -> NoteViewModel
    private let bannerDuration: Duration
    /// The `+` (CELLAR-R14): the app opens the new note, the same as from the Home.
    private let onAdd: () -> Void
    /// A note was saved or deleted: its verdict may have moved the map (CELLAR-R29), which the Home follows.
    private let onNoteChange: () -> Void
    /// CELLAR-R27: the app opens the new note on a saved one.
    private let onEditNote: (CellarEntry, Wine) -> Void
    /// The note asked to be edited: the new note opens once its sheet has gone.
    private var pendingEdit: (entry: CellarEntry, wine: Wine)?
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(loadCellar: any LoadCellarUseCaseProtocol, preferences: any CellarPreferencesProtocol,
         bannerDuration: Duration = .seconds(5), onAdd: @escaping () -> Void = {},
         onNoteChange: @escaping () -> Void = {},
         onEditNote: @escaping (CellarEntry, Wine) -> Void = { _, _ in },
         makeNote: @escaping (CellarEntry, CellarViewModel) -> NoteViewModel) {
        self.onAdd = onAdd
        self.onNoteChange = onNoteChange
        self.onEditNote = onEditNote
        self.loadCellar = loadCellar
        self.preferences = preferences
        self.makeNote = makeNote
        self.bannerDuration = bannerDuration
        refresh()
    }

    /// Reads the entries ahead of the first visit, when the tabs open, so the Cellar shows them at once.
    /// No banner: that is for when the user is looking.
    public func prefetch() async {
        await readIfNeeded()
        guard !Task.isCancelled, !didOpen else { return }
        let mode = uiModel.viewMode
        let items = Array(uiModel.items.prefix(mode.photoBatchSize))
        guard !items.isEmpty else { return }
        let task = Task(priority: .utility) { [weak self] in
            guard let self else { return [String: UIImage]() }
            return try await loadPhotos(for: items, mode: mode)
        }
        firstPhotos = (items, mode, task)
        _ = try? await task.value
    }

    public func load() async {
        await readIfNeeded()
        guard !Task.isCancelled else { return }
        if didOpen, isLoaded, mutations == nil {
            await refreshSummaries()
        }
        didOpen = isLoaded
        showBannerIfDue()
    }

    // Keep CloudKit changes visible on return visits while the existing collection remains available.
    private func refreshSummaries() async {
        let version = mutationVersion
        do {
            let updated = try await loadCellar.execute()
            guard !Task.isCancelled, version == mutationVersion else { return }
            if updated != entries { entries = updated }
        } catch {
            logger.error("Cellar did not refresh: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func readIfNeeded() async {
        guard !isLoaded else { return }
        if let initialRead {
            await initialRead.value
            return
        }
        readFailed = false
        refresh()
        let read = Task { [weak self] in
            guard let self else { return }
            await reload()
        }
        initialRead = read
        await read.value
        initialRead = nil
    }

    public func preparePhotos(for items: [CellarItemUIModel], mode: CellarViewMode) async throws -> [String: UIImage] {
        if let firstPhotos, firstPhotos.mode == mode, firstPhotos.items == items {
            let images = try? await firstPhotos.task.value
            try Task.checkCancellation()
            self.firstPhotos = nil
            if let images { return images }
        } else if let firstPhotos {
            firstPhotos.task.cancel()
            self.firstPhotos = nil
        }
        return try await loadPhotos(for: items, mode: mode)
    }

    public func frontPhotos(for wineKeys: [String]) async throws -> [String: Data] {
        try await loadCellar.frontPhotos(for: wineKeys)
    }

    /// A cover, a row or a search result opens its note (CELLAR-R13).
    public func openNote(_ wineKey: String) {
        guard let entry = entries.first(where: { $0.id == wineKey }) else { return }
        noteRead?.cancel()
        let model = makeNote(entry, self)
        model.startReadingPhotos()
        note = model
        noteRead = Task { [weak model, loadCellar, logger] in
            do {
                let fullEntry = try await loadCellar.entry(wineKey)
                guard !Task.isCancelled else { return }
                if let fullEntry {
                    model?.setFullEntry(fullEntry)
                } else {
                    model?.finishReadingPhotos()
                }
            } catch {
                logger.error("Note photos could not load: \(error.localizedDescription, privacy: .public)")
                model?.finishReadingPhotos()
            }
        }
    }

    /// Back to the Cellar, where it was.
    public func closeNote() {
        noteRead?.cancel()
        note = nil
    }

    /// CELLAR-R27: Edit closes the note; the new note opens on it when the sheet is gone (`noteDismissed`), since
    /// one sheet cannot open over another that is closing.
    func editNote(_ entry: CellarEntry, wine: Wine) {
        pendingEdit = (entry, wine)
        closeNote()
    }

    /// The note's sheet has gone.
    public func noteDismissed() {
        guard let edit = pendingEdit else { return }
        pendingEdit = nil
        onEditNote(edit.entry, edit.wine)
    }

    public func add() { onAdd() }

    /// Refresh the saved wine and show "Note saved" for a few seconds (CELLAR-R19).
    public func newNoteSaved(_ wineKey: String) {
        refreshEntry(wineKey)
        isNoteSavedVisible = true
        noteSavedTask?.cancel()
        noteSavedTask = Task { [weak self, bannerDuration] in
            try? await Task.sleep(for: min(bannerDuration, .seconds(3)))
            guard !Task.isCancelled else { return }
            self?.isNoteSavedVisible = false
        }
    }

    /// Updates a single persisted wine after a write from Home or New Note.
    public func refreshEntry(_ wineKey: String) {
        let previous = mutations
        mutationVersion += 1
        let version = mutationVersion
        mutations = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            defer { if version == mutationVersion { mutations = nil } }
            await readIfNeeded()
            do {
                guard var entry = try await loadCellar.entry(wineKey) else { return }
                if let data = entry.photoFront {
                    _ = await CellarPhotoCache.load(data, maxPixel: uiModel.viewMode.thumbnailPixels)
                }
                entry.photoFront = nil
                entry.photoBack = nil
                var updated = entries
                if let index = updated.firstIndex(where: { $0.id == wineKey }) {
                    updated[index] = entry
                } else {
                    let index = updated.firstIndex(where: { $0.createdAt < entry.createdAt }) ?? updated.endIndex
                    updated.insert(entry, at: index)
                }
                entries = updated
            } catch {
                logger.error("Cellar entry did not refresh: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func noteRated(_ wineKey: String) {
        refreshEntry(wineKey)
        onNoteChange()
    }

    func noteDeleted(_ wineKey: String) {
        let previous = mutations
        mutationVersion += 1
        let version = mutationVersion
        mutations = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            entries.removeAll { $0.id == wineKey }
            if version == mutationVersion { mutations = nil }
        }
        onNoteChange()
    }

    private func reload() async {
        do {
            let loaded = try await loadCellar.execute()
            isLoaded = true
            entries = loaded
        } catch {
            readFailed = true
            refresh()
            logger.error("Cellar did not load: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// CELLAR-R07: the choice is kept for the next time the Cellar opens.
    public func selectViewMode(_ mode: CellarViewMode) {
        preferences.viewMode = mode
        refresh()
    }

    public func openFilter(_ facet: CellarFacet) {
        guard !entries.isEmpty else { return }
        openFacet = facet
    }

    public func closeFilter() { openFacet = nil }

    /// One value per filter: picking the one already on turns the filter off.
    public func pick(_ value: String) {
        guard let facet = openFacet else { return }
        filters[facet] = filters[facet] == value ? nil : value
    }

    /// "Any …": the open filter lets everything through again, and its sheet closes.
    public func clearOpenFilter() {
        if let facet = openFacet { filters[facet] = nil }
        openFacet = nil
    }

    public func clearFilters() { filters = [:] }

    public func updateQuery(_ query: String) { self.query = query }

    private func showBannerIfDue() {
        guard !entries.isEmpty, preferences.bannerViews < Self.bannerVisits, bannerTask == nil else { return }
        preferences.bannerViews += 1
        isBannerVisible = true
        bannerTask = Task { [weak self, bannerDuration] in
            try? await Task.sleep(for: bannerDuration)
            self?.isBannerVisible = false
            self?.bannerTask = nil
        }
    }

    private func refresh() {
        let builder = CellarPresentationBuilder(entries: entries, filters: filters, openFacet: openFacet,
                                                query: query, isLoaded: isLoaded, resources: uiModel.resources)
        var model = uiModel
        model.viewMode = preferences.viewMode
        model.state = readFailed && !isLoaded ? .failed : builder.state
        model.items = builder.items
        model.chips = builder.chips
        model.areFiltersEnabled = !entries.isEmpty
        model.isFiltered = !filters.isEmpty
        model.filterSheet = builder.filterSheet
        model.isBannerVisible = isBannerVisible
        model.isNoteSavedVisible = isNoteSavedVisible
        model.query = query
        model.isSearching = builder.isSearching
        let results = builder.searchResults
        model.searchResults = results
        model.searchCount = model.resources.notesCount(results.count)
        model.noResultsText = model.resources.noNotes(query.trimmingCharacters(in: .whitespacesAndNewlines))
        uiModel = model
    }
}
