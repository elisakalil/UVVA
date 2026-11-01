import DesignSystem
import SwiftUI

/// The You tab: the header, the three tabs and their panels (YOU.md).
public struct YouView: View {
    @Bindable var viewModel: YouViewModel

    public init(viewModel: YouViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground(photo: UVVAPhoto.hills, veiled: true)
            VStack(spacing: 0) {
                YouHeader(model: viewModel.header)
                    .padding(.horizontal, 30)
                    .padding(.top, 36)
                YouTabBar(selected: $viewModel.tab)
                    .padding(.top, 30)
                ScrollView {
                    Group {
                        switch viewModel.tab {
                        case .progress: ProgressTabView(viewModel: viewModel)
                        case .map: MapTabView(viewModel: viewModel)
                        case .settings: SettingsTabView(viewModel: viewModel)
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
                .id(viewModel.tab)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .task { await viewModel.load() }
    }
}
