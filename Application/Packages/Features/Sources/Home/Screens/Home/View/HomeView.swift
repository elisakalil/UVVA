import Core
import DesignSystem
import SwiftUI

public struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: ViewModel
    var tour: GuidedTourViewModel?

    @State private var glossaryViewModel: GlossaryViewModel?
    @State private var inviting = false

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
        .fullScreenCover(isPresented: Binding(
            get: { glossaryViewModel != nil },
            set: { if !$0 { glossaryViewModel = nil } }
        )) {
            if let glossaryViewModel {
                GlossaryView(viewModel: glossaryViewModel)
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.loadIfNeeded() } }
        }
        .sheet(isPresented: $inviting) {
            if let model = viewModel.uiModel.content {
                InvitePalateView(name: model.firstName, map: model.palateMap) { inviting = false }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    private func content(_ model: HomeContentUIModel, target: String?) -> some View {
        HomeContent(
            model: model,
            resources: viewModel.uiModel.resources,
            tourTarget: target,
            cellarWineKeys: viewModel.uiModel.cellarWineKeys,
            onInvite: { inviting = true },
            onOpenLesson: viewModel.openLesson,
            onOpenCourse: viewModel.openCourse,
            onOpenGlossary: { term in
                glossaryViewModel = GlossaryViewModel(terms: model.glossary, initialTerm: term) {
                    glossaryViewModel = nil
                }
            },
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
