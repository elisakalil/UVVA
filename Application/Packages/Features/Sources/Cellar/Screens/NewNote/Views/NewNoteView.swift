import DesignSystem
import SwiftUI

/// A new note (CELLAR.md §4): the camera, the reading, a message when it goes wrong, "Fill in by hand", and the wine
/// on paper. The same flow opens from the `+` of the Cellar and of the Home (CELLAR-R14).
public struct NewNoteView<ViewModel: NewNoteViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    private var model: NewNoteUIModel { viewModel.uiModel }
    private var resources: NewNoteResourcesUIModel { model.resources }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        screen
            .animation(.easeOut(duration: 0.3), value: model.step)
            .task { await viewModel.start() }
            .sheet(isPresented: Binding(get: { model.isConfirmingDiscard }, set: { if !$0 { viewModel.keepEditing() } })) {
                CellarPaperSheet(title: resources.discardTitleText, message: resources.discardBodyText,
                                 primary: resources.discardText, secondary: resources.keepEditingText,
                                 onPrimary: viewModel.discard, onSecondary: viewModel.keepEditing)
            }
    }

    @ViewBuilder private var screen: some View {
        switch model.step {
        case .checkingCamera:
            CellarPalette.cameraGround.ignoresSafeArea()
        case .front, .back, .reading:
            NewNoteCaptureView(model: model, onCapture: { photo in Task { await viewModel.capture(photo) } },
                               onClose: viewModel.close)
                .transition(.opacity)
        case .readFailed, .cameraDenied:
            NewNoteMessageView(model: model, onPrimary: viewModel.tryAgain, onFillInByHand: viewModel.fillInByHand,
                               onClose: viewModel.close)
                .transition(.opacity)
        case .manual:
            NewNoteManualView(model: model, onChange: viewModel.updateManual(_:text:), onPickType: viewModel.pickType,
                              onContinue: { Task { await viewModel.continueManual() } }, onClose: viewModel.close)
                .transition(.opacity)
        case .note:
            NewNotePaperView(model: model, onAnswer: viewModel.answer(hasTasted:), onPick: viewModel.pick,
                             onNote: viewModel.updateNote, onRedo: viewModel.redo,
                             onSave: { Task { await viewModel.save() } }, onClose: viewModel.close)
                .transition(.opacity)
        }
    }
}

#if DEBUG
#Preview("Note") {
    NewNoteView(viewModel: MockNewNoteViewModel(step: .note))
}

#Preview("By hand") {
    NewNoteView(viewModel: MockNewNoteViewModel(step: .manual))
}

#Preview("Read failed") {
    NewNoteView(viewModel: MockNewNoteViewModel(step: .readFailed))
}

#Preview("Camera") {
    NewNoteView(viewModel: MockNewNoteViewModel(step: .front))
}
#endif
