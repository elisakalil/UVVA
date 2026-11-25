#if os(iOS)
import DesignSystem
import SwiftUI

/// The wine list (WINELIST.md): the camera, "What's on the table?", "Order this" and "Say it or show it", one after
/// the other in the scan's sheet.
public struct WineListView<ViewModel: WineListViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    private var model: WineListUIModel { viewModel.uiModel }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        screen
            .animation(.easeOut(duration: 0.3), value: model.step)
            .task { await viewModel.start() }
            .interactiveDismissDisabled(model.isReading)
    }

    @ViewBuilder private var screen: some View {
        switch model.step {
        case .checkingCamera:
            NotePalette.cameraGround.ignoresSafeArea()
        case .cameraDenied:
            WineListDeniedView(model: model).transition(.opacity)
        case .capture:
            WineListCaptureView(model: model, onCapture: { photo in Task { await viewModel.capture(photo) } },
                                onUseList: viewModel.useList)
                .transition(.opacity)
        case .questions:
            WineListQuestionsView(model: model, onBack: viewModel.back, onDish: viewModel.toggleDish,
                                  onBudget: viewModel.chooseBudget, onPerson: viewModel.togglePerson,
                                  onOrder: viewModel.showPicks)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        case .results:
            WineListResultsView(model: model, onBack: viewModel.back, onAsk: viewModel.ask)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        case .ask:
            WineListAskView(model: model, onClose: viewModel.back, onLanguage: viewModel.chooseLanguage,
                            onAddToCellar: viewModel.addToCellar)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
#endif
