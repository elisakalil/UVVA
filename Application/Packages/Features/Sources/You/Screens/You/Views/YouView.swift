import DesignSystem
import SwiftUI

/// The You tab: the header, the three tabs and their panels (YOU.md).
public struct YouView<ViewModel: YouViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

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
                        case .progress: ProgressTabView(viewModel: viewModel.progress)
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
        .task { await viewModel.load() }
    }
}
