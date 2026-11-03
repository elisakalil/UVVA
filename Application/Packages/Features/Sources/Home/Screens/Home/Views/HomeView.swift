import Core
import DesignSystem
import SwiftUI

public struct HomeView: View {
    var viewModel: HomeViewModel
    var tour: GuidedTourViewModel?

    @State private var invite: URL?

    public init(viewModel: HomeViewModel, tour: GuidedTourViewModel? = nil) {
        self.viewModel = viewModel
        self.tour = tour
    }

    public var body: some View {
        Group {
            if let model = viewModel.model {
                HomeContent(
                    model: model,
                    tourTarget: tour?.current?.target,
                    cellarWineKeys: viewModel.cellarWineKeys,
                    onInvite: { invite = viewModel.inviteLink },
                    onOpenCourse: viewModel.openCourse,
                    onOpenLearn: viewModel.openLearn)
            } else {
                ZStack {
                    PageBackground()
                    GrapeLoop().frame(width: 60, height: 84)
                }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .sheet(item: $invite) { link in
            ActivityShareSheet(message: viewModel.inviteMessage, link: link) { invite = nil }
                .presentationDetents([.medium, .large])
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
