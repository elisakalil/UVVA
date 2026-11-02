import Core
import DesignSystem
import SwiftUI

/// The Learn tab (LEARN.md §3): By region, By grape and The path. The lesson player opens over everything;
/// a certificate opens through `certificateCover(_:)`, set on the app's root.
public struct LearnView: View {
    var viewModel: LearnViewModel
    @FocusState private var isSearchFocused: Bool
    /// How far the page has scrolled, and the height of the title above the search bar.
    @State private var scrolled: CGFloat = 0
    @State private var titleHeight: CGFloat = 0
    /// A region tapped on the map scrolls the page so the list starts just below the search bar.
    @State private var position = ScrollPosition()
    /// Where the region list starts in the visible part of the scroll view.
    @State private var regionListTop: CGFloat = 0
    /// Where the open module starts in the visible part of the scroll view.
    @State private var openRowTop: CGFloat = 0
    /// The height of the scroll view, between the status bar and the tab bar.
    @State private var visibleHeight: CGFloat = 0

    /// The search bar with its padding: the room the list keeps for it.
    private static let searchSlot: CGFloat = 56

    public init(viewModel: LearnViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(blur: 2, veiled: true)
            content
            searchBar
                .offset(y: max(0, titleHeight - scrolled))
        }
        .foregroundStyle(UVVAColor.creamFill)
        .task { await viewModel.load() }
        .fullScreenCover(isPresented: Binding(get: { viewModel.player != nil }, set: { _ in })) {
            if let player = viewModel.player {
                LessonPlayerView(viewModel: player).id(player.id)
            }
        }
    }

    /// The title has scrolled away and the search bar holds the top.
    private var isSearchPinned: Bool { titleHeight > 0 && scrolled > titleHeight }

    /// The title scrolls away; the search bar rides with it, then stays at the top while the lists fade out under it.
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Learn", bundle: .module)
                    .font(UVVAFont.sans(31, .ultraLight))
                    .tracking(-0.47)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 30)
                    .padding(.top, 36)
                    .padding(.bottom, 6)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { titleHeight = $0 }
                Color.clear.frame(height: Self.searchSlot)
                sections
            }
            .padding(.bottom, 24)
            .animation(.easeOut(duration: 0.2), value: viewModel.isSearching)
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
            scrolled = offset
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { visibleHeight = $0 }
        .mask {
            VStack(spacing: 0) {
                Color.black.opacity(isSearchPinned ? 0 : 1).frame(height: Self.searchSlot - 6)
                LinearGradient(colors: [.black.opacity(isSearchPinned ? 0 : 1), .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                Color.black
                    // Past the bottom inset too, so the lists still show through the tab bar's glass.
                    .padding(.bottom, -200)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .scrollEdgeFade(12, throughBottomInset: true)
        .scrollPosition($position)
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
        SearchField(text: Binding(get: { viewModel.query }, set: { viewModel.query = $0 }),
                    prompt: String(localized: "Search modules", bundle: .module),
                    isFocused: $isSearchFocused,
                    glassOpacity: 0.45,
                    onCancel: {})
            // The search bar keeps its light material; only the tab bar takes the photo behind it.
            .environment(\.backdropFrame, nil)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }

    @ViewBuilder private var sections: some View {
        if viewModel.isSearching {
            SearchResultsView(groups: viewModel.searchResults, query: viewModel.query) { result in
                isSearchFocused = false
                Task {
                    await viewModel.openResult(result)
                    // A region found by the search scrolls to the list, as one tapped on the map does;
                    // a grape or a module, to its row. Once the list has taken the results' place.
                    guard case .course = result.target else { return }
                    try? await Task.sleep(for: .milliseconds(300))
                    if viewModel.tab == .region { scrollToRegionList() } else { scrollToOpenRow() }
                }
            }
            .transition(.opacity)
        } else {
            Text("Study wine by region, by grape or through a sommelier’s complete curriculum.", bundle: .module)
                .font(UVVAFont.sans(13))
                .lineSpacing(5)
                .opacity(0.82)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 24)
            LearnTabBar(selected: viewModel.tab) { kind in withAnimation(.easeOut(duration: 0.3)) { viewModel.show(kind) } }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            tabContent
                .id(viewModel.tab)
                .transition(.opacity)
        }
    }

    @ViewBuilder private var tabContent: some View {
        switch viewModel.tab {
        case .region:
            VStack(alignment: .leading, spacing: 0) {
                FilterRow(filters: viewModel.countryFilters) { name in
                    withAnimation(.easeOut(duration: 0.28)) { viewModel.selectCountry(name) }
                }
                .padding(.top, 30)
                if let map = viewModel.regionMap {
                    RegionMapView(model: map) { id in
                        withAnimation(.easeOut(duration: 0.28)) { viewModel.selectRegion(id) }
                        scrollToRegionList()
                    }
                    .id(map.country.name)
                    .transition(.opacity)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                list(viewModel.regionGroups)
                    // A short list (Portugal's five regions) still reaches up to the search bar.
                    .frame(minHeight: max(0, visibleHeight - Self.searchSlot), alignment: .top)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView(axis: .vertical)).minY } action: {
                        regionListTop = $0
                    }
            }
        case .grape:
            VStack(alignment: .leading, spacing: 0) {
                FilterRow(filters: viewModel.grapeFilters) { id in
                    withAnimation(.easeOut(duration: 0.28)) { viewModel.selectGrapeFilter(id: id) }
                }
                .padding(.top, 24)
                list(viewModel.grapeGroups)
            }
        case .path:
            VStack(alignment: .leading, spacing: 0) {
                FilterRow(filters: viewModel.pathFilters) { id in
                    withAnimation(.easeOut(duration: 0.28)) { viewModel.selectPathLevel(id == "all" ? nil : id) }
                }
                .padding(.top, 24)
                list(viewModel.pathGroups)
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
                    CourseRow(model: row,
                              onToggle: { withAnimation(.easeOut(duration: 0.28)) { viewModel.toggle(row.id) } },
                              onStart: { Task { await viewModel.startCourse(id: row.id) } },
                              onCertificate: { Task { await viewModel.showCertificate(courseID: row.id) } })
                    .onGeometryChange(for: CGFloat?.self) { row.isOpen ? $0.frame(in: .scrollView(axis: .vertical)).minY : nil } action: {
                        if let top = $0 { openRowTop = top }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
}
