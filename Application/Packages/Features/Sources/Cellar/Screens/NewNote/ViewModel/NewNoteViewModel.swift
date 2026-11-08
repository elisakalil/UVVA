import Combine
import Core
import Foundation
import OSLog

/// A new note (CELLAR.md §4): the two label photos, UVVA's reading, "Have you had this wine?" and the save.
@MainActor
public final class NewNoteViewModel: NewNoteViewModelProtocol, Identifiable {
    @Published public private(set) var uiModel = NewNoteUIModel()
    public nonisolated let id = UUID()

    private var flow = NewNoteFlow() { didSet { refresh() } }
    private var isWorking = false { didSet { refresh() } }
    private var errorText: String? { didSet { refresh() } }

    private let prepareCamera: any PrepareCameraUseCaseProtocol
    private let readLabel: any ReadLabelUseCaseProtocol
    private let readManual: any ReadManualUseCaseProtocol
    private let saveNewNote: any SaveNewNoteUseCaseProtocol
    /// The note was kept: the Cellar reads its entries again and says "Note saved".
    private let onSaved: () -> Void
    private let onClose: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(prepareCamera: any PrepareCameraUseCaseProtocol, readLabel: any ReadLabelUseCaseProtocol,
         readManual: any ReadManualUseCaseProtocol, saveNewNote: any SaveNewNoteUseCaseProtocol,
         onSaved: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.prepareCamera = prepareCamera
        self.readLabel = readLabel
        self.readManual = readManual
        self.saveNewNote = saveNewNote
        self.onSaved = onSaved
        self.onClose = onClose
        refresh()
    }

    public func start() async {
        guard flow.step == .checkingCamera else { return }
        flow.cameraChecked(await prepareCamera.execute())
    }

    public func capture(_ photo: Data) async {
        flow.capture(photo)
        guard flow.step == .reading, let front = flow.photoFront, let back = flow.photoBack else { return }
        let result = await readLabel.execute(front: front, back: back)
        flow.labelRead(result)
    }

    public func tryAgain() { flow.tryAgain() }

    public func fillInByHand() {
        errorText = nil
        flow.fillInByHand()
    }

    public func updateManual(_ field: NewNoteField, text: String) { flow.manual[field] = text }

    /// Tapping the chosen type again clears it.
    public func pickType(_ type: String) { flow.manual.type = flow.manual.type == type ? nil : type }

    public func continueManual() async {
        guard flow.canContinueManual, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let wine = try await readManual.execute(flow.manual.facts)
            errorText = nil
            flow.manualRead(wine)
        } catch {
            logger.error("Wine not read by hand: \(error.localizedDescription, privacy: .public)")
            errorText = uiModel.resources.manualErrorText
        }
    }

    public func redo() {
        errorText = nil
        flow.redo()
    }

    public func answer(hasTasted: Bool) {
        errorText = nil
        flow.answer(hasTasted: hasTasted)
    }

    public func pick(_ verdict: Verdict) { flow.pick(verdict) }

    public func updateNote(_ text: String) { flow.note = text }

    public func save() async {
        guard let draft = flow.draft, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await saveNewNote.execute(draft)
            onSaved()
        } catch {
            logger.error("New note not saved: \(error.localizedDescription, privacy: .public)")
            errorText = uiModel.resources.saveErrorText
        }
    }

    public func close() {
        if flow.close() == .close { onClose() }
    }

    public func keepEditing() { flow.keepEditing() }

    /// "Discard": nothing is kept (CELLAR-R25).
    public func discard() {
        flow.keepEditing()
        onClose()
    }

    private func refresh() {
        var model = uiModel
        NewNotePresentationBuilder(flow: flow, resources: model.resources, noteResources: model.noteResources)
            .build(into: &model)
        model.isWorking = isWorking
        model.errorText = errorText
        uiModel = model
    }
}
