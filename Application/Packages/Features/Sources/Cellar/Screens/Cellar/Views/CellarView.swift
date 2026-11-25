import CoreUI
import DesignSystem
import SwiftUI

/// The Cellar tab (CELLAR.md §3): "Your Cellar", the filters, and the covers or the list.
/// "Search your cellar" fades in once the page is scrolled (CELLAR-R11).
public struct CellarView<ViewModel: CellarViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Binding private var newNote: NewNoteViewModel?
    @FocusState private var isSearchFocused: Bool
    @State private var scrolled: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var position = ScrollPosition()

    @State private var visibleItems: [CellarItemUIModel] = []
    @State private var photos: [String: UIImage] = [:]
    @State private var visibleMode: CellarViewMode?
    @State private var requestedCount = 0
    @State private var photoLoadFailed = false
    @State private var retry = 0

    private var model: CellarUIModel { viewModel.uiModel }
    private var resources: CellarResourcesUIModel { model.resources }

    /// The search bar with its padding: the room it takes over the top of the page.
    private static var searchSlot: CGFloat { 56 }

    public init(viewModel: ViewModel, newNote: Binding<NewNoteViewModel?> = .constant(nil)) {
        self.viewModel = viewModel
        self._newNote = newNote
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(blur: 2, veiled: true)
            content
            searchBar
                .opacity(searchOpacity)
                .allowsHitTesting(searchOpacity > 0.5)
                .accessibilityHidden(searchOpacity <= 0.5)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .animation(.easeOut(duration: 0.2), value: model.isSearching)
        .overlay(alignment: .top) { noteSaved }
        .animation(.easeOut(duration: 0.3), value: model.isNoteSavedVisible)
        .onChange(of: model.isNoteSavedVisible) { _, isVisible in
            if isVisible { AccessibilityNotification.Announcement(resources.noteSavedText).post() }
        }
        .task { await viewModel.load() }
        .newNoteSheet($newNote)
        // CELLAR-R13: the note in a sheet over the Cellar, dragged down to close.
        .sheet(item: Binding(get: { viewModel.note }, set: { if $0 == nil { viewModel.closeNote() } }),
               onDismiss: viewModel.noteDismissed) { note in
            NoteView(viewModel: note, frontPreview: photos[note.uiModel.wineKey])
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .sheet(item: Binding(get: { model.filterSheet }, set: { if $0 == nil { viewModel.closeFilter() } })) { sheet in
            CellarFilterSheet(resources: resources, model: sheet,
                              onPick: viewModel.pick, onClose: viewModel.closeFilter, onAny: viewModel.clearOpenFilter)
        }
    }

    /// "Note saved" over the top of the Cellar, after a new note (CELLAR-R19).
    @ViewBuilder private var noteSaved: some View {
        if model.isNoteSavedVisible {
            Text(resources.noteSavedText)
                .font(UVVAFont.sans(12.5, .medium))
                .foregroundStyle(UVVAColor.mossDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(UVVAColor.creamFill, in: Capsule())
                .shadow(color: Color(hex: 0x0C100A).opacity(0.28), radius: 17, y: 14)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityAddTraits(.isStaticText)
        }
    }

    /// Search fades in after the header scrolls out of view and stays visible while in use.
    private var searchOpacity: Double {
        if isSearchFocused || model.isSearching { return 1 }
        return min(1, max(0, (scrolled - headerHeight) / 44))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(resources.titleText)
                .font(UVVAFont.sans(31, .ultraLight))
                .tracking(-0.47)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            // Opens "Search your cellar" straight away, without scrolling the header out first (CELLAR-R11).
            Button { isSearchFocused = true } label: {
                Image(systemName: resources.searchIcon)
                    .font(.system(size: 21, weight: .ultraLight))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(resources.searchPromptText)
            .padding(.top, -8)
            .padding(.trailing, -16)
            Button(action: viewModel.add) {
                Text(verbatim: "+")
                    .font(UVVAFont.sans(38, .ultraLight))
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(resources.addText)
            .padding(.top, -8)
            .padding(.trailing, -8)
        }
        .padding(.horizontal, 30)
        .padding(.top, 36)
        .padding(.bottom, 14)
        // The search bar comes down over the header: the title and its buttons step aside while it is open.
        .opacity(isSearchFocused || model.isSearching ? 0 : 1)
        .allowsHitTesting(!(isSearchFocused || model.isSearching))
        .animation(.easeOut(duration: 0.2), value: isSearchFocused)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    }

    private var searchBar: some View {
        SearchField(text: Binding(get: { model.query }, set: { viewModel.updateQuery($0) }),
                    prompt: resources.searchPromptText,
                    isFocused: $isSearchFocused,
                    onCancel: {})
            // The same frosted photo glass as the tab bar: the content scrolls behind it, softly diffused.
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
    }

    private var content: some View {
        ScrollView {
            if model.isSearching {
                searchResults.transition(.opacity)
            } else {
                cellarContent.transition(.opacity)
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
            scrolled = offset
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .scrollEdgeFade(12, throughBottomInset: true)
        .scrollPosition($position)
        .onChange(of: model.isSearching) { _, isSearching in
            if isSearching { position.scrollTo(edge: .top) }
        }
    }

    private var cellarContent: some View {
        VStack(spacing: 0) {
            header
            collection
                // The rule over the covers falls on the same line as the one under You's tabs.
                .padding(.top, 29)
        }
        .padding(.bottom, 24)
    }

    private var collection: some View {
        VStack(spacing: 0) {
            if model.isBannerVisible {
                CellarBanner(resources: resources)
                    .padding(.bottom, 26)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            CellarFilterBar(resources: resources, viewMode: model.viewMode, chips: model.chips,
                            isEnabled: model.areFiltersEnabled, isFiltered: model.isFiltered,
                            onViewMode: { mode in withAnimation(.easeOut(duration: 0.25)) { viewModel.selectViewMode(mode) } },
                            onChip: viewModel.openFilter,
                            onClear: { withAnimation(.easeOut(duration: 0.25)) { viewModel.clearFilters() } })
                .padding(.bottom, 16)
            list
                .animation(.easeOut(duration: 0.25), value: model.state)
        }
        .animation(.easeInOut(duration: 0.6), value: model.isBannerVisible)
    }

    @ViewBuilder private var list: some View {
        switch model.state {
        case .idle:
            loading
        case .failed:
            Button(resources.retryText) { Task { await viewModel.load() } }
                .padding(.vertical, 28)
        case .empty:
            CellarEmptyView(resources: resources)
        case .noMatches:
            CellarNoMatchesView(resources: resources) {
                withAnimation(.easeOut(duration: 0.25)) { viewModel.clearFilters() }
            }
        case .items:
            VStack(spacing: 0) {
                if !visibleItems.isEmpty && visibleMode == model.viewMode {
                    switch model.viewMode {
                    case .grid:
                        CellarGrid(items: visibleItems, photos: photos, onApproachEnd: requestMore,
                                   onOpen: viewModel.openNote)
                    case .list:
                        CellarList(items: visibleItems, photos: photos, onApproachEnd: requestMore,
                                   onOpen: viewModel.openNote)
                    }
                }
                if photoLoadFailed {
                    Button(resources.retryText) { retry += 1 }
                        .padding(.vertical, 28)
                } else if visibleMode != model.viewMode || visibleItems.count < model.items.count {
                    loading
                        .onScrollVisibilityChange(threshold: 0.1) { isVisible in
                            if isVisible { requestMore() }
                        }
                }
            }
            .task(id: photoRequest) { await revealPhotos() }
        }
    }

    private var loading: some View {
        GrapeLoop()
            .frame(width: 44, height: 62)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .accessibilityRepresentation { ProgressView(resources.loadingText) }
    }

    private var photoRequest: PhotoRequest {
        let count = visibleMode == model.viewMode ? max(requestedCount, model.viewMode.photoBatchSize)
                                                   : model.viewMode.photoBatchSize
        return PhotoRequest(mode: model.viewMode, items: Array(model.items.prefix(count)), retry: retry)
    }

    private func requestMore() {
        guard visibleMode == model.viewMode, !visibleItems.isEmpty, !photoLoadFailed,
              visibleItems.count < model.items.count, requestedCount <= visibleItems.count else { return }
        requestedCount = visibleItems.count + model.viewMode.photoBatchSize
    }

    private func revealPhotos() async {
        let request = photoRequest
        photoLoadFailed = false
        let reusable = visibleMode == request.mode
            ? Dictionary(visibleItems.map { ($0.id, $0.updatedAt) }, uniquingKeysWith: { first, _ in first }) : [:]
        let pending = request.items.filter { reusable[$0.id] != $0.updatedAt }
        do {
            let loaded = try await viewModel.preparePhotos(for: pending, mode: request.mode)
            try Task.checkCancellation()
            guard request == photoRequest else { return }
            var ready: [String: UIImage] = [:]
            for item in request.items {
                ready[item.id] = reusable[item.id] == item.updatedAt ? photos[item.id] : loaded[item.id]
            }
            photos = ready
            if visibleMode != request.mode { requestedCount = request.mode.photoBatchSize }
            visibleMode = request.mode
            visibleItems = request.items
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, request == photoRequest else { return }
            photoLoadFailed = true
        }
    }

    private struct PhotoRequest: Equatable {
        var mode: CellarViewMode
        var items: [CellarItemUIModel]
        var retry: Int
    }

    private var searchResults: some View {
        CellarSearchResults(resources: resources, count: model.searchCount,
                            results: model.searchResults, noResultsText: model.noResultsText) { id in
            isSearchFocused = false
            viewModel.openNote(id)
        }
        .padding(.top, Self.searchSlot)
        .padding(.bottom, 24)
    }
}

#if DEBUG
#Preview {
    CellarView(viewModel: MockCellarViewModel())
}
#endif
