#if os(iOS)
import DesignSystem
import SwiftUI

/// A new note (CELLAR.md §4): the camera, the reading, a message when it goes wrong, "Fill in by hand", and the wine
/// on paper. The same flow opens from the `+` of the Cellar and of the Home (CELLAR-R14), in a sheet that is
/// dragged down to close: no bar, no `×`.
public struct NewNoteView<ViewModel: NewNoteViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    private var model: NewNoteUIModel { viewModel.uiModel }

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        screen
            .animation(.easeOut(duration: 0.3), value: model.step)
            .task { await viewModel.start() }
            .interactiveDismissDisabled(model.isWorking)
    }

    @ViewBuilder private var screen: some View {
        switch model.step {
        case .checkingCamera:
            NotePalette.cameraGround.ignoresSafeArea()
        case .front, .back, .reading:
            NewNoteCaptureView(model: model, onCapture: { photo in
                Task { await viewModel.capture(photo.kept, reading: photo.reading) }
            })
                .transition(.opacity)
        case .readFailed, .cameraDenied:
            NewNoteMessageView(model: model, onPrimary: viewModel.tryAgain, onFillInByHand: viewModel.fillInByHand)
                .transition(.opacity)
        case .manual:
            NewNoteManualView(model: model, onChange: viewModel.updateManual(_:text:), onPickType: viewModel.pickType,
                              onContinue: { Task { await viewModel.continueManual() } })
                .transition(.opacity)
        case .note:
            NewNotePaperView(model: model, onAnswer: viewModel.answer(hasTasted:), onPick: viewModel.pick,
                             onNote: viewModel.updateNote, onAddChip: viewModel.addChip,
                             loadChipOptions: viewModel.chipOptions, onIntensity: viewModel.setIntensity,
                             onReplacePhoto: viewModel.replacePhoto,
                             onSave: { Task { await viewModel.save() } })
                .transition(.opacity)
        }
    }
}

public extension View {
    func newNoteSheet(_ note: Binding<NewNoteViewModel?>) -> some View {
        sheet(item: note) { viewModel in
            NewNoteView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
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
#endif
