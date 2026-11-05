import Core
import DesignSystem
import SwiftUI

public struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel
    var tour: GuidedTourViewModel?

    @State private var invite: URL?

    public init(viewModel: ViewModel, tour: GuidedTourViewModel? = nil) {
        self.viewModel = viewModel
        self.tour = tour
    }

    public var body: some View {
        Group {
            if let model = viewModel.uiModel.content {
                if let tour {
                    HomeTourObserver(tour: tour) { target in content(model, target: target) }
                } else {
                    content(model, target: nil)
                }
            } else {
                ZStack {
                    PageBackground()
                    GrapeLoop().frame(width: 60, height: 84)
                }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .sheet(item: $invite) { link in
            ActivityShareSheet(message: viewModel.uiModel.inviteMessage, link: link) { invite = nil }
                .presentationDetents([.medium, .large])
        }
    }
    private func content(_ model: HomeContentUIModel, target: String?) -> some View {
                HomeContent(
                    model: model,
                    resources: viewModel.uiModel.resources,
                    tourTarget: target,
                    cellarWineKeys: viewModel.uiModel.cellarWineKeys,
                    onInvite: { invite = viewModel.uiModel.inviteLink },
                    onOpenCourse: viewModel.openCourse,
                    onOpenLearn: viewModel.openLearn)
    }

}

private struct HomeTourObserver<Tour: GuidedTourViewModelProtocol, Content: View>: View {
    @ObservedObject var tour: Tour
    @ViewBuilder var content: (String?) -> Content
    var body: some View { content(tour.uiModel.current?.target) }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    HomeView(viewModel: MockHomeViewModel())
}
