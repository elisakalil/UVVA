import Core
import DesignSystem
import SwiftUI

/// The Home tab (HOME.md). With a tour running, it scrolls to whatever the tour points at.
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
                    onInvite: { invite = viewModel.inviteLink
                    })
            } else {
                ZStack {
                    PageBackground()
                    GrapeLoop().frame(width: 60, height: 84)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $invite) { link in
            ActivityShareSheet(message: viewModel.inviteMessage, link: link) { invite = nil }
                .presentationDetents([.medium, .large])
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
