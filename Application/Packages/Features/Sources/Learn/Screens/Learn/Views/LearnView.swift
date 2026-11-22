import Core
import DesignSystem
import SwiftUI

/// The Learn tab (LEARN.md §3): By region, By grape and The path. The lesson player opens over everything;
/// lessons and certificates are presented by modifiers on the app root.
public struct LearnView<ViewModel: LearnViewModelProtocol>: View {
    private var resources: LearnResourcesUIModel { viewModel.uiModel.resources }
    @ObservedObject var viewModel: ViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var scrolled: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var isInfoPresented = false
    /// A region tapped on the map scrolls the page so the list starts just below the search bar.
    @State private var position = ScrollPosition()
    /// Where the region list starts in the visible part of the scroll view.
    @State private var regionListTop: CGFloat = 0
    /// Where the open module starts in the visible part of the scroll view.
    @State private var openRowTop: CGFloat = 0
    /// The height of the scroll view, between the status bar and the tab bar.
    @State private var visibleHeight: CGFloat = 0
    /// A sideways swipe on the list: it follows the finger, then the list of the filter beside it slides in
    /// (France to Italy, Red to White, Essentials to Intermediate).
    @State private var swipeOffset: CGFloat = 0
    /// The side the next filter's list slides in from.
    @State private var filterEdge: Edge = .trailing

    /// The search bar with its padding: the room the list keeps for it.
    private static var searchSlot: CGFloat { 56 }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
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
        .task { await viewModel.load() }
        .overlay {
            if isInfoPresented {
                Rectangle()
                    .fill(.black.opacity(0.25))
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .onTapGesture { isInfoPresented = false }
            }
        }
        .sheet(isPresented: $isInfoPresented) {
            LearnTracksSheet(resources: resources)
                .presentationBackground {
                    PageBackground(photo: UVVAPhoto.hills, veiled: true)
                }
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationDragIndicator(.visible)
        }
    }

    /// The title and info button scroll out of view with the tabs.
    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(resources.learnText)
                .font(UVVAFont.sans(31, .ultraLight))
                .tracking(-0.47)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button { isInfoPresented = true } label: {
                // A hairline ring and a light "i" in the app's own type, like the title beside it.
                Text(verbatim: "i")
                    .font(UVVAFont.sans(14, .thin))
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(lineWidth: 0.75))
                    .foregroundStyle(UVVAColor.creamFill)
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("About Learn", bundle: .module))
            .padding(.top, -8)
            .padding(.trailing, -8)
        }
        .padding(.horizontal, 30)
        .padding(.top, 36)
        .padding(.bottom, 14)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    }

    /// Search fades in after the header scrolls out of view and stays visible while in use.
    private var searchOpacity: Double {
        if isSearchFocused || viewModel.uiModel.isSearching { return 1 }
        return min(1, max(0, (scrolled - headerHeight) / 44))
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                sections
                    .padding(.bottom, 24)
                    .animation(.easeOut(duration: 0.2), value: viewModel.uiModel.isSearching)
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
                scrolled = offset
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { visibleHeight = $0 }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
            .scrollEdgeFade(12, throughBottomInset: true)
            .scrollPosition($position)
            .onChange(of: viewModel.uiModel.isSearching) { _, isSearching in
                if isSearching { position.scrollTo(edge: .top) }
            }
            .onChange(of: viewModel.uiModel.focusedCourseID, initial: true) { _, id in
                guard let id else { return }
                proxy.scrollTo(id, anchor: .top)
            }
            .onChange(of: viewModel.uiModel.isPresentingPlayer) { _, presenting in
                guard !presenting, let id = viewModel.uiModel.focusedCourseID else { return }
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }

    private func scrollToRegionList() {
        withAnimation(.easeInOut(duration: 0.45)) {
            // `scrolled` counts from the top of the content, as `scrollTo(y:)` does.
            position.scrollTo(y: max(0, scrolled + regionListTop - Self.searchSlot))
        }
    }

    /// A grape or a module found by the search: the page scrolls so it starts just below the search bar.
    private func scrollToOpenRow() {
        withAnimation(.easeInOut(duration: 0.45)) {
            position.scrollTo(y: max(0, scrolled + openRowTop - Self.searchSlot))
        }
    }

    private var searchBar: some View {
        SearchField(text: Binding(get: { viewModel.uiModel.query }, set: { viewModel.updateQuery($0) }),
                    prompt: resources.searchModulesText,
                    isFocused: $isSearchFocused,
                    onCancel: {})
            // The same frosted photo glass as the tab bar: the content scrolls behind it, softly diffused.
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
    }

    @ViewBuilder private var sections: some View {
        if viewModel.uiModel.isSearching {
            SearchResultsView(resources: resources, groups: viewModel.uiModel.searchResults, query: viewModel.uiModel.query) { result in
                isSearchFocused = false
                Task {
                    await viewModel.openResult(result)
                    // A region found by the search scrolls to the list, as one tapped on the map does;
                    // a grape or a module, to its row. Once the list has taken the results' place.
                    guard case .course = result.target else { return }
                    try? await Task.sleep(for: .milliseconds(300))
                    if viewModel.uiModel.tab == .region { scrollToRegionList() } else { scrollToOpenRow() }
                }
            }
            .padding(.top, Self.searchSlot)
            .transition(.opacity)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                header
                LearnTabBar(resources: resources, selected: viewModel.uiModel.tab) { kind in
                    withAnimation(.easeOut(duration: 0.3)) { viewModel.show(kind) }
                }
                .padding(.horizontal, 24)
                // The 40-point tabs end at Cellar's rule, below its filters.
                .padding(.top, 35)
                tabContent
                    .id(viewModel.uiModel.tab)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Filters, tapped or swiped through

    /// The filters of the tab on screen: countries, grape colours and countries, or levels.
    private var filters: [FilterUIModel] {
        switch viewModel.uiModel.tab {
        case .region: viewModel.uiModel.countryFilters
        case .grape: viewModel.uiModel.grapeFilters
        case .path: viewModel.uiModel.pathFilters
        }
    }

    private var selectedFilter: String? { filters.first(where: \.isSelected)?.id }

    private func neighbour(_ step: Int) -> String? {
        let filters = filters
        guard let index = filters.firstIndex(where: \.isSelected), filters.indices.contains(index + step) else { return nil }
        return filters[index + step].id
    }

    /// A filter tapped or swiped to: its list slides in from the filter's side.
    private func selectFilter(_ id: String) {
        let ids = filters.map(\.id)
        guard id != selectedFilter, let to = ids.firstIndex(of: id) else { return }
        filterEdge = to > (selectedFilter.flatMap(ids.firstIndex(of:)) ?? -1) ? .trailing : .leading
        let tab = viewModel.uiModel.tab
        // The leaving list takes its side from the render before the change.
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.3)) {
                switch tab {
                case .region: viewModel.selectCountry(id)
                case .grape: viewModel.selectGrapeFilter(id: id)
                case .path: viewModel.selectPathLevel(id == "all" ? nil : id)
                }
                swipeOffset = 0
            }
        }
    }

    private var filterSwipe: SidewaysSwipe {
        SidewaysSwipe { dx in
            // At the first and last filter the list gives a little, then holds.
            swipeOffset = neighbour(dx < 0 ? 1 : -1) == nil ? dx * 0.2 : dx
        } onEnded: { dx, velocity in
            if dx < -70 || (dx < -20 && velocity < -500), let next = neighbour(1) {
                selectFilter(next)
            } else if dx > 70 || (dx > 20 && velocity > 500), let previous = neighbour(-1) {
                selectFilter(previous)
            } else {
                withAnimation(.spring(duration: 0.3)) { swipeOffset = 0 }
            }
        }
    }

    /// What a filter shows, below the filter row: it slides sideways with the swipe, and the next one slides in.
    private func filterPage(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .id(selectedFilter)
            .transition(.asymmetric(insertion: .move(edge: filterEdge).combined(with: .opacity),
                                    removal: .move(edge: filterEdge == .trailing ? .leading : .trailing).combined(with: .opacity)))
            .offset(x: swipeOffset)
            // Takes the swipe on its empty space too. The filter row above keeps its own sideways scroll.
            .contentShape(Rectangle())
            .gesture(filterSwipe)
    }

    @ViewBuilder private var tabContent: some View {
        switch viewModel.uiModel.tab {
        case .region:
            VStack(alignment: .leading, spacing: 0) {
                FilterRow(filters: viewModel.uiModel.countryFilters) { selectFilter($0) }
                    .padding(.top, 30)
                filterPage {
                    if let map = viewModel.uiModel.regionMap {
                        RegionMapView(resources: resources, model: map) { id in
                            withAnimation(.easeOut(duration: 0.28)) { viewModel.selectRegion(id) }
                            scrollToRegionList()
                        }
                        .id(map.country.name)
                        .transition(.opacity)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                    list(viewModel.uiModel.regionGroups)
                        // A short list (Portugal's five regions) still reaches up to the search bar.
                        .frame(minHeight: max(0, visibleHeight - Self.searchSlot), alignment: .top)
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView(axis: .vertical)).minY } action: {
                            regionListTop = $0
                        }
                }
            }
        case .grape:
            VStack(alignment: .leading, spacing: 0) {
                FilterRow(filters: viewModel.uiModel.grapeFilters) { selectFilter($0) }
                    .padding(.top, 24)
                filterPage { list(viewModel.uiModel.grapeGroups) }
            }
        case .path:
            VStack(alignment: .leading, spacing: 0) {
                FilterRow(filters: viewModel.uiModel.pathFilters) { selectFilter($0) }
                    .padding(.top, 24)
                filterPage { list(viewModel.uiModel.pathGroups) }
            }
        }
    }

    private func list(_ groups: [CourseGroupUIModel]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(groups) { group in
                if let title = group.title {
                    Text(title.uppercased())
                        .font(UVVAFont.sans(9.5))
                        .tracking(2.6)
                        .opacity(0.72)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                }
                ForEach(group.rows) { row in
                    CourseRow(resources: resources, model: row,
                              onToggle: { withAnimation(.easeOut(duration: 0.28)) { viewModel.toggle(row.id) } },
                              onStart: { Task { await viewModel.startCourse(id: row.id) } })
                    .id(row.id)
                    .onGeometryChange(for: CGFloat?.self) { row.isOpen ? $0.frame(in: .scrollView(axis: .vertical)).minY : nil } action: {
                        if let top = $0 { openRowTop = top }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LearnView(viewModel: MockLearnViewModel())
}
