import DesignSystem
import SwiftUI

/// The You tab: the header, the three tabs and their panels (YOU.md).
public struct YouView<ViewModel: YouViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    @State private var selectedProgressStat: ProgressStat?

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
                YouTabBar(selected: Binding(get: { viewModel.uiModel.tab }, set: { viewModel.selectTab($0) }))
                    .padding(.top, 30)
                ScrollView {
                    Group {
                        switch viewModel.uiModel.tab {
                        case .progress:
                            ProgressTabView(viewModel: viewModel.progress, selectedStat: $selectedProgressStat)
                        case .map: MapTabView(viewModel: viewModel.map)
                        case .settings: SettingsTabView(viewModel: viewModel.settings)
                        }
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 26)
                    // The tab bar already holds its own room at the foot of the scroll.
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollEdgeFade(12, throughBottomInset: true)
                // Each tab opens at its top, not at the offset the last one was left at.
                .id(viewModel.uiModel.tab)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .overlay {
            if selectedProgressStat != nil {
                Rectangle()
                    .fill(.black.opacity(0.25))
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .onTapGesture { selectedProgressStat = nil }
            }
        }
        .sheet(item: $selectedProgressStat) { stat in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(stat.items.enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 10) {
                            UVVAIllustration.grape(index % UVVAIllustration.grapeCount + 1)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(UVVAFont.sans(17))
                                if !item.detail.isEmpty {
                                    Text(item.detail)
                                        .font(UVVAFont.sans(12))
                                        .opacity(0.84)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
                .padding(.vertical, 28)
            }
            .foregroundStyle(UVVAColor.creamFill)
            .presentationBackground {
                PageBackground(photo: viewModel.uiModel.backgroundPhoto, veiled: true)
            }
            .presentationDetents([.medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationDragIndicator(.visible)
        }
        .task { await viewModel.load() }
    }
}
