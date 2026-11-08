import Combine
import Core
import Foundation
import OSLog

/// The Cellar tab (CELLAR.md §3): the covers or the list, the filters and the search.
@MainActor
public final class CellarViewModel: CellarViewModelProtocol {
    @Published public private(set) var uiModel = CellarUIModel()
    @Published public private(set) var note: NoteViewModel?

    /// The banner shows on the first visits only, for a few seconds each.
    static let bannerVisits = 2

    private var entries: [CellarEntry] = [] { didSet { refresh() } }
    private var filters: [CellarFacet: String] = [:] { didSet { refresh() } }
    private var openFacet: CellarFacet? { didSet { refresh() } }
    private var query = "" { didSet { refresh() } }
    private var isBannerVisible = false { didSet { refresh() } }
    private var bannerTask: Task<Void, Never>?

    private let loadCellar: any LoadCellarUseCaseProtocol
    private let preferences: any CellarPreferencesProtocol
    private let makeNote: (CellarEntry, _ owner: CellarViewModel) -> NoteViewModel
    private let bannerDuration: Duration
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(loadCellar: any LoadCellarUseCaseProtocol, preferences: any CellarPreferencesProtocol,
         bannerDuration: Duration = .seconds(5),
         makeNote: @escaping (CellarEntry, CellarViewModel) -> NoteViewModel) {
        self.loadCellar = loadCellar
        self.preferences = preferences
        self.makeNote = makeNote
        self.bannerDuration = bannerDuration
        refresh()
    }

    /// Every time the tab opens, so wines saved from the Home are there.
    public func load() async {
        await reload()
        showBannerIfDue()
    }

    /// A cover, a row or a search result opens its note (CELLAR-R13).
    public func openNote(_ wineKey: String) {
        guard let entry = entries.first(where: { $0.id == wineKey }) else { return }
        note = makeNote(entry, self)
    }

    /// Back to the Cellar, where it was.
    public func closeNote() { note = nil }

    /// The note was saved or deleted: the Cellar reads its entries again.
    func noteChanged() {
        Task { await reload() }
    }

    private func reload() async {
        do {
            entries = try await loadCellar.execute()
        } catch {
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
                                                query: query, resources: uiModel.resources)
        var model = uiModel
        model.viewMode = preferences.viewMode
        model.state = builder.state
        model.items = builder.items
        model.chips = builder.chips
        model.areFiltersEnabled = !entries.isEmpty
        model.isFiltered = !filters.isEmpty
        model.filterSheet = builder.filterSheet
        model.isBannerVisible = isBannerVisible
        model.query = query
        model.isSearching = builder.isSearching
        let results = builder.searchResults
        model.searchResults = results
        model.searchCount = model.resources.notesCount(results.count)
        model.noResultsText = model.resources.noNotes(query.trimmingCharacters(in: .whitespacesAndNewlines))
        uiModel = model
    }
}
