import Core
import CoreUI
import DesignSystem
import SwiftUI

public struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: ViewModel
    var tour: GuidedTourViewModel?
    @Binding private var newNote: NewNoteViewModel?

    @State private var glossaryViewModel: GlossaryViewModel?
    @State private var inviting = false
    @State private var wineSheet: WineSheetModel?
    /// "Add to cellar" on the wine sheet: the note opens over the tabs once the sheet is gone (HOME-R24).
    @State private var cellarNote: Wine?

    public init(viewModel: ViewModel, tour: GuidedTourViewModel? = nil,
                newNote: Binding<NewNoteViewModel?> = .constant(nil)) {
        self.viewModel = viewModel
        self.tour = tour
        self._newNote = newNote
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
        .sheet(item: $wineSheet, onDismiss: openCellarNote) { sheet in
            if let model = viewModel.uiModel.content {
                WineSheet(resources: viewModel.uiModel.resources, sheet: sheet, palateMap: model.palateMap,
                          cellarWineKeys: viewModel.uiModel.cellarWineKeys,
                          onAddToCellar: { wine in
                              cellarNote = wine
                              wineSheet = nil
                          })
            }
        }
        .newNoteSheet($newNote)
        .overlay(alignment: .top) { HomeNoticeView(text: wineSheet == nil ? viewModel.uiModel.notice : nil) }
    }

    private func openCellarNote() {
        guard let wine = cellarNote else { return }
        cellarNote = nil
        viewModel.openCellarNote(for: wine, fromHero: false)
    }

    private func content(_ model: HomeContentUIModel, target: String?) -> some View {
        HomeContent(
            model: model,
            resources: viewModel.uiModel.resources,
            tourTarget: target,
            cellarWineKeys: viewModel.uiModel.cellarWineKeys,
            isRefreshingMatches: viewModel.uiModel.isRefreshingMatches,
            isReloading: viewModel.uiModel.isReloading,
            isReturningToTop: viewModel.uiModel.isReturningToTop,
            onInvite: { inviting = true },
            onOpenLesson: viewModel.openLesson,
            onOpenCourse: viewModel.openCourse,
            onOpenGlossary: { term in
                glossaryViewModel = GlossaryViewModel(terms: model.glossary, initialTerm: term) {
                    glossaryViewModel = nil
                }
            },
            onOpenLearn: viewModel.openLearn,
            onOpenWine: { wineSheet = $0 },
            onSaveToCellar: { viewModel.openCellarNote(for: $0, fromHero: true) },
            onScan: viewModel.scan,
            onOpenFriends: viewModel.openFriends,
            onOpenLastTable: viewModel.openLastTable,
            onOpenMapHistory: viewModel.openMapHistory)
    }

}

private struct HomeTourObserver<Tour: GuidedTourViewModelProtocol, Content: View>: View {
    @ObservedObject var tour: Tour
    @ViewBuilder var content: (String?) -> Content
    var body: some View { content(tour.uiModel.current?.target) }
}

#Preview {
    HomeView(viewModel: MockHomeViewModel())
}
