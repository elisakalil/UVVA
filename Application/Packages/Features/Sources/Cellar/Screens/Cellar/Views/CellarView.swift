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
        .sheet(item: Binding(get: { viewModel.note }, set: { if $0 == nil { viewModel.closeNote() } })) { note in
            NoteView(viewModel: note)
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
            Color.clear.frame(height: 1)
        case .empty:
            CellarEmptyView(resources: resources)
        case .noMatches:
            CellarNoMatchesView(resources: resources) {
                withAnimation(.easeOut(duration: 0.25)) { viewModel.clearFilters() }
            }
        case .items:
            switch model.viewMode {
            case .grid: CellarGrid(items: model.items, onOpen: viewModel.openNote).transition(.opacity)
            case .list: CellarList(items: model.items, onOpen: viewModel.openNote).transition(.opacity)
            }
        }
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
