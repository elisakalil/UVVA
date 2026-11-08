import DesignSystem
import SwiftUI

/// The Cellar tab (CELLAR.md §3): "Your Cellar", the filters, and the covers or the list.
/// "Search your cellar" fades in once the page is scrolled (CELLAR-R11).
public struct CellarView<ViewModel: CellarViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var scrolled: CGFloat = 0

    private var model: CellarUIModel { viewModel.uiModel }
    private var resources: CellarResourcesUIModel { model.resources }

    /// The search bar with its padding: the room it takes over the top of the page.
    private static var searchSlot: CGFloat { 56 }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(blur: 2, veiled: true)
            VStack(spacing: 0) {
                header
                ZStack(alignment: .top) {
                    if model.isSearching {
                        searchContent.transition(.opacity)
                    } else {
                        cellarContent.transition(.opacity)
                    }
                    searchBar
                        .opacity(searchOpacity)
                        .allowsHitTesting(searchOpacity > 0.5)
                }
                .animation(.easeOut(duration: 0.2), value: model.isSearching)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .task { await viewModel.load() }
        .fullScreenCover(item: Binding(get: { viewModel.note }, set: { if $0 == nil { viewModel.closeNote() } })) { note in
            NoteView(viewModel: note)
        }
        .sheet(item: Binding(get: { model.filterSheet }, set: { if $0 == nil { viewModel.closeFilter() } })) { sheet in
            CellarFilterSheet(resources: resources, model: sheet,
                              onPick: viewModel.pick, onClose: viewModel.closeFilter, onAny: viewModel.clearOpenFilter)
        }
    }

    /// In use, the search bar stays; otherwise it fades in between 40 and 140 points of scroll.
    private var searchOpacity: Double {
        if isSearchFocused || model.isSearching { return 1 }
        return min(1, max(0, (scrolled - 40) / 100))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(resources.titleText)
                .font(UVVAFont.sans(31, .ultraLight))
                .tracking(-0.47)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            // The new note (CELLAR-R14) is not built yet: the button is there, resting.
            Button {} label: {
                Text(verbatim: "+")
                    .font(UVVAFont.sans(38, .ultraLight))
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.35)
            .accessibilityLabel(resources.addText)
            .padding(.top, -8)
            .padding(.trailing, -14)
        }
        .padding(.horizontal, 30)
        .padding(.top, 36)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        SearchField(text: Binding(get: { model.query }, set: { viewModel.updateQuery($0) }),
                    prompt: resources.searchPromptText,
                    isFocused: $isSearchFocused,
                    glassOpacity: 0.45,
                    onCancel: {})
            .environment(\.backdropFrame, nil)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
    }

    private var cellarContent: some View {
        ScrollView {
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
            }
            // The rule over the covers falls on the same line as the one under You's tabs.
            .padding(.top, 29)
            .padding(.bottom, 24)
            .animation(.easeInOut(duration: 0.6), value: model.isBannerVisible)
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
            scrolled = offset
        }
        .mask {
            // Once the search bar shows, the page fades out under it.
            VStack(spacing: 0) {
                Color.black.opacity(1 - searchOpacity).frame(height: Self.searchSlot - 6)
                LinearGradient(colors: [.black.opacity(1 - searchOpacity), .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                Color.black.padding(.bottom, -200)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder private var list: some View {
        switch model.state {
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

    private var searchContent: some View {
        ScrollView {
            CellarSearchResults(resources: resources, count: model.searchCount,
                                results: model.searchResults, noResultsText: model.noResultsText) { id in
                isSearchFocused = false
                viewModel.openNote(id)
            }
                .padding(.top, Self.searchSlot)
                .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .scrollEdgeFade(12, throughBottomInset: true)
    }
}

#if DEBUG
#Preview {
    CellarView(viewModel: MockCellarViewModel())
}
#endif
