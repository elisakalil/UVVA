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
    @State private var cellarNote: (wine: Wine, verdict: Verdict?, asksTasting: Bool)?

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
                          ratedVerdicts: viewModel.uiModel.ratedVerdicts,
                          // HOME-R24: the sheet stays open, with the verdict marked.
                          onRate: { wine, verdict, isInCellar in
                              Task { await viewModel.rate(wine, verdict: verdict, addToCellar: isInCellar) }
                          },
                          onAddToCellar: { wine, verdict, asksTasting in
                              cellarNote = (wine, verdict, asksTasting)
                              wineSheet = nil
                          })
            }
        }
        .newNoteSheet($newNote)
        .overlay(alignment: .top) { HomeNoticeView(text: wineSheet == nil ? viewModel.uiModel.notice : nil) }
    }

    private func openCellarNote() {
        guard let note = cellarNote else { return }
        cellarNote = nil
        viewModel.openCellarNote(for: note.wine, verdict: note.verdict, asksTasting: note.asksTasting)
    }

    private func content(_ model: HomeContentUIModel, target: String?) -> some View {
        HomeContent(
            model: model,
            resources: viewModel.uiModel.resources,
            tourTarget: target,
            cellarWineKeys: viewModel.uiModel.cellarWineKeys,
            isRefreshingMatches: viewModel.uiModel.isRefreshingMatches,
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
            onSaveToCellar: { wine in
                let verdict = viewModel.uiModel.ratedVerdicts[wine.id]
                viewModel.openCellarNote(for: wine, verdict: verdict, asksTasting: verdict == nil)
            },
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

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    HomeView(viewModel: MockHomeViewModel())
}
