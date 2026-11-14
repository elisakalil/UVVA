import DesignSystem
import SwiftUI

/// The You tab: the header, the three tabs and their panels (YOU.md).
public struct YouView<ViewModel: YouViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    @State private var selectedProgressStat: ProgressStat?
    /// How far a Progress sheet is open: it opens at half of the half screen it used to open at.
    @State private var progressDetent = Self.progressOpeningDetent

    private static var progressOpeningDetent: PresentationDetent { .fraction(0.25) }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(photo: viewModel.uiModel.backgroundPhoto, veiled: true)
            VStack(spacing: 0) {
                YouHeader(model: viewModel.uiModel.header)
                    .padding(.horizontal, 30)
                    .padding(.top, 36)
                    .opacity(viewModel.uiModel.isLoaded ? 1 : 0)
                YouTabBar(selected: Binding(get: { viewModel.uiModel.tab }, set: { viewModel.selectTab($0) }))
                    .padding(.top, 30)
                ScrollViewReader { proxy in
                    ScrollView {
                        Group {
                            switch viewModel.uiModel.tab {
                            case .progress:
                                ProgressTabView(viewModel: viewModel.progress, selectedStat: $selectedProgressStat)
                            case .map:
                                MapTabView(viewModel: viewModel.map, focusesHistory: viewModel.uiModel.focusesMapHistory) {
                                    // YOU-R03. After this pass, when the page has its height.
                                    // A beat for the tab to settle in, then a slow glide down to the section.
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(350))
                                        withAnimation(.smooth(duration: 0.9)) {
                                            proxy.scrollTo(MapTabView<ViewModel.MapModel>.historyID, anchor: .top)
                                        }
                                        viewModel.mapHistoryShown()
                                    }
                                }
                            case .settings: SettingsTabView(viewModel: viewModel.settings)
                            }
                        }
                        .padding(.horizontal, 26)
                        .padding(.top, 26)
                        // The tab bar already holds its own room at the foot of the scroll.
                        .padding(.bottom, 24)
                        // While Regions or Bottles is open, room under the page lets the map rise to the top, above
                        // the sheet; it goes with the sheet.
                        .padding(.bottom, viewModel.uiModel.tab == .progress && selectedProgressStat?.mapKind != nil ? 420 : 0)
                        // It comes at once, so the scroll to the map has it; it leaves smoothly.
                        .animation(selectedProgressStat?.mapKind == nil ? .smooth(duration: 0.6) : nil,
                                   value: selectedProgressStat?.mapKind)
                    }
                    .scrollIndicators(.hidden)
                    .scrollEdgeFade(12, throughBottomInset: true)
                    .opacity(viewModel.uiModel.isLoaded ? 1 : 0)
                    // Each tab opens at its top, not at the offset the last one was left at.
                    .id(viewModel.uiModel.tab)
                    // Regions and Bottles keep only their pins: the page brings the map up, above their sheet.
                    .onChange(of: selectedProgressStat?.mapKind) { _, kind in
                        guard kind != nil else { return }
                        // After the room under the page is laid out: scrolled before it, the page stops short.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(250))
                            withAnimation(.smooth(duration: 0.6)) {
                                proxy.scrollTo(ProgressTabView<ViewModel.ProgressModel>.mapID, anchor: UnitPoint(x: 0.5, y: -0.1))
                            }
                        }
                    }
                }
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .animation(.easeOut(duration: 0.25), value: viewModel.uiModel.isLoaded)
        // Over the foot of the screen, above the tab bar, and not inside the scroll (YOU-R27).
        .overlay(alignment: .bottom) {
            if viewModel.uiModel.tab == .settings { DeleteFailureCard(viewModel: viewModel.settings) }
        }
        .overlay {
            if selectedProgressStat != nil {
                Rectangle()
                    .fill(.black.opacity(0.25))
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .onTapGesture { selectedProgressStat = nil }
            }
        }
        // The next sheet opens small again, however far this one was dragged.
        .sheet(item: $selectedProgressStat, onDismiss: { progressDetent = Self.progressOpeningDetent }) { stat in
            ProgressDetailSheet(stat: stat)
            .presentationBackground {
                PageBackground(photo: viewModel.uiModel.backgroundPhoto, veiled: true)
            }
            .presentationDetents([Self.progressOpeningDetent, .medium, .large], selection: $progressDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationDragIndicator(.visible)
        }
        .task { await viewModel.load() }
        // A request the page never met (no "Over time" yet) ends with the visit.
        .onDisappear { viewModel.mapHistoryShown() }
    }
}
