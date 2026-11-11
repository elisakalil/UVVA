import Combine
import Core
import Foundation
import Match
import OSLog

/// A new note (CELLAR.md §4): the two label photos, UVVA's reading, "Have you had this wine?" and the save.
@MainActor
public final class NewNoteViewModel: NewNoteViewModelProtocol, Identifiable {
    @Published public private(set) var uiModel = NewNoteUIModel()
    public nonisolated let id = UUID()

    private var flow = NewNoteFlow() { didSet { refresh() } }
    private var isWorking = false { didSet { refresh() } }
    private var errorText: String? { didSet { refresh() } }

    private var palate: PalateMap? { didSet { refresh() } }
    private let catalog: LabelCatalogCache?
    private let maps: (any PalateMapRepository)?
    private let prepareCamera: any PrepareCameraUseCaseProtocol
    private let readLabel: any ReadLabelUseCaseProtocol
    private let readManual: any ReadManualUseCaseProtocol
    private let saveNewNote: any SaveNewNoteUseCaseProtocol
    /// The note was kept: the Cellar reads its entries again and says "Note saved".
    private let onSaved: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    /// `wine` is one the app already knows, with the verdict given for it, if any: the note opens on paper (CELLAR-R14a).
    init(wine: Wine? = nil, verdict: Verdict? = nil, asksTasting: Bool = false,
         prepareCamera: any PrepareCameraUseCaseProtocol, readLabel: any ReadLabelUseCaseProtocol,
         readManual: any ReadManualUseCaseProtocol, saveNewNote: any SaveNewNoteUseCaseProtocol,
         maps: (any PalateMapRepository)? = nil, catalog: LabelCatalogCache? = nil,
         onSaved: @escaping () -> Void) {
        if let wine { flow = NewNoteFlow(wine: wine, verdict: verdict, asksTasting: asksTasting) }
        self.maps = maps
        self.catalog = catalog
        self.prepareCamera = prepareCamera
        self.readLabel = readLabel
        self.readManual = readManual
        self.saveNewNote = saveNewNote
        self.onSaved = onSaved
        refresh()
    }

    public convenience init(wine: Wine? = nil, verdict: Verdict? = nil, asksTasting: Bool = false,
                            cellar: any CellarRepository, maps: any PalateMapRepository,
                            labelCatalog: any LabelCatalogRepository, reader: any LabelReading,
                            structurer: any LabelStructuring, camera: any CameraAuthorizing,
                            rewriter: any PalateHistoryRewriting, wines: any WineLookup,
                            now: @escaping () -> Date = Date.init,
                            onSaved: @escaping () -> Void) {
        let catalog = LabelCatalogCache(catalog: labelCatalog)
        let recalculate = RecalculateMapUseCase(history: maps, rewriter: rewriter, wines: wines)
        self.init(
            wine: wine, verdict: verdict, asksTasting: asksTasting,
            prepareCamera: PrepareCameraUseCase(camera: camera),
            readLabel: ReadLabelUseCase(reader: reader, structurer: structurer, catalog: catalog, now: now),
            readManual: ReadManualUseCase(catalog: catalog),
            saveNewNote: SaveNewNoteUseCase(cellar: cellar, catalog: labelCatalog, maps: maps,
                                            recalculate: recalculate, now: now),
            maps: maps, catalog: catalog, onSaved: onSaved)
    }

    public func start() async {
        if flow.step == .checkingCamera {
            flow.cameraChecked(await prepareCamera.execute())
        }
        palate = try? await maps?.currentMap()
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

    public func chipOptions(for field: NewNoteChipField) async -> [String] {
        guard let prepared = try? await catalog?.load() else { return [] }
        let wines = prepared.wines
        return await Task.detached(priority: .userInitiated) { field.options(in: wines) }.value
    }

    public func addChip(_ value: String, to field: NewNoteChipField) { flow.addChip(value, to: field) }

    public func setIntensity(_ value: Double, for axis: PalateAxis) { flow.setIntensity(value, for: axis) }

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

    private func refresh() {
        var model = uiModel
        NewNotePresentationBuilder(flow: flow, palate: palate, resources: model.resources)
            .build(into: &model)
        model.isWorking = isWorking
        model.errorText = errorText
        uiModel = model
    }
}
