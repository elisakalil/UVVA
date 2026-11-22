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
    private var history: TasteHistory? { didSet { refresh() } }
    private let cellar: (any CellarRepository)?
    private let catalog: LabelCatalogCache?
    private let maps: (any PalateMapRepository)?
    private let prepareCamera: any PrepareCameraUseCaseProtocol
    private let readLabel: any ReadLabelUseCaseProtocol
    private let readManual: any ReadManualUseCaseProtocol
    private let saveNewNote: any SaveNewNoteUseCaseProtocol
    /// The note was kept: the Cellar refreshes the saved wine and says "Note saved".
    private let onSaved: (String) -> Void
    /// Scan only (FRI-R12a): the wine read from the label is handed over instead of opening on paper.
    private let onScanned: ((Wine) -> Void)?
    private var hasScanned = false
    /// The full-size copies of the label photos, held only until they are read.
    private var readingFront: Data?
    private var readingBack: Data?
    /// The back label as the camera read it, moving over it (CELLAR-R17).
    private var backScan: LabelScan?
    /// The step "Reading your label" is at, and whether it has come to an end (CELLAR-R17).
    private var readingStage: LabelReadStage? { didSet { refresh() } }
    private var isReadingDone = false { didSet { refresh() } }
    /// How long the full reading line shows before the note opens, so the wait is seen to end.
    private let readingSettle: Duration
    /// What the last reading saw, for the debug section of the note (CELLAR-R17).
    private let readingLog: LabelReadingLog?
    private var readingDebugText: String? { didSet { refresh() } }
    private var readingExportText: String? { didSet { refresh() } }
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    /// `wine` is one the app already knows: the note opens on paper, asking "Rate it again?" when it was rated before
    /// with `ratedVerdict` (CELLAR-R14a).
    /// With `editing`, a saved note of the Cellar opens to be edited, on `wine` as it shows (CELLAR-R27).
    init(wine: Wine? = nil, ratedVerdict: Verdict? = nil, editing: CellarEntry? = nil,
         prepareCamera: any PrepareCameraUseCaseProtocol, readLabel: any ReadLabelUseCaseProtocol,
         readManual: any ReadManualUseCaseProtocol, saveNewNote: any SaveNewNoteUseCaseProtocol,
         maps: (any PalateMapRepository)? = nil, cellar: (any CellarRepository)? = nil,
         catalog: LabelCatalogCache? = nil, readingLog: LabelReadingLog? = nil, readingSettle: Duration = .milliseconds(450),
         onScanned: ((Wine) -> Void)? = nil, onSaved: @escaping (String) -> Void) {
        if let wine, let entry = editing {
            flow = NewNoteFlow(editing: wine, verdict: entry.verdict, score: entry.score, note: entry.note,
                               photoFront: entry.photoFront, photoBack: entry.photoBack)
        } else if let wine {
            flow = NewNoteFlow(wine: wine, ratedVerdict: ratedVerdict)
        }
        self.readingLog = readingLog
        self.readingSettle = readingSettle
        self.maps = maps
        self.cellar = cellar
        self.catalog = catalog
        self.prepareCamera = prepareCamera
        self.readLabel = readLabel
        self.readManual = readManual
        self.saveNewNote = saveNewNote
        self.onSaved = onSaved
        self.onScanned = onScanned
        refresh()
    }

    public convenience init(wine: Wine? = nil, ratedVerdict: Verdict? = nil,
                            editing: CellarEntry? = nil, cellar: any CellarRepository, maps: any PalateMapRepository,
                            labelCatalog: any LabelCatalogRepository, reader: any LabelReading,
                            structurer: any LabelStructuring, pairer: any PairingSuggesting,
                            camera: any CameraAuthorizing,
                            rewriter: any PalateHistoryRewriting, wines: any WineLookup,
                            now: @escaping () -> Date = Date.init,
                            onScanned: ((Wine) -> Void)? = nil,
                            onSaved: @escaping (String) -> Void) {
        let catalog = LabelCatalogCache(catalog: labelCatalog)
        #if DEBUG
        let readingLog: LabelReadingLog? = LabelReadingLog()
        #else
        let readingLog: LabelReadingLog? = nil
        #endif
        let recalculate = RecalculateMapUseCase(history: maps, rewriter: rewriter, wines: wines)
        self.init(
            wine: wine, ratedVerdict: ratedVerdict, editing: editing,
            prepareCamera: PrepareCameraUseCase(camera: camera),
            readLabel: ReadLabelUseCase(reader: reader, structurer: structurer, pairer: pairer, catalog: catalog,
                                        now: now, log: readingLog),
            readManual: ReadManualUseCase(catalog: catalog, pairer: pairer),
            saveNewNote: SaveNewNoteUseCase(cellar: cellar, catalog: labelCatalog, maps: maps,
                                            recalculate: recalculate, now: now),
            maps: maps, cellar: cellar, catalog: catalog, readingLog: readingLog, onScanned: onScanned, onSaved: onSaved)
    }

    public func start() async {
        if flow.step == .checkingCamera {
            flow.cameraChecked(await prepareCamera.execute())
        }
        palate = try? await maps?.currentMap()
        if let entries = try? await cellar?.entrySummaries() {
            history = TasteHistory(entries: entries)
        }
    }

    public func capture(_ photo: Data, reading: Data?, scan: LabelScan?) async {
        switch flow.step {
        case .front: readingFront = reading
        case .back:
            readingBack = reading
            backScan = scan
        default: break
        }
        flow.capture(photo)
        guard flow.step == .reading, let front = flow.photoFront, let back = flow.photoBack else { return }
        // The full-size copies are read when there are; the kept photos otherwise.
        readingStage = nil
        isReadingDone = false
        let result = await readLabel.execute(front: readingFront ?? front, back: readingBack ?? back,
                                             backScan: backScan) { [weak self] stage in self?.readingStage = stage }
        readingFront = nil
        readingBack = nil
        backScan = nil
        refreshDiagnostics()
        if result != .failed {
            // The line fills to the end before the wine shows: a reading that stops at 90% looks stuck.
            isReadingDone = true
            try? await Task.sleep(for: readingSettle)
        }
        flow.labelRead(result)
        readingStage = nil
        isReadingDone = false
        handOverIfScanned()
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
            handOverIfScanned()
        } catch {
            logger.error("Wine not read by hand: \(error.localizedDescription, privacy: .public)")
            errorText = uiModel.resources.manualErrorText
        }
    }

    public func replacePhoto(_ photo: Data, side: NewNotePhotoSide) { flow.replacePhoto(photo, side: side) }

    public func answer(hasTasted: Bool) {
        errorText = nil
        flow.answer(hasTasted: hasTasted)
    }

    public func pick(_ verdict: Verdict) {
        errorText = nil
        flow.pick(verdict)
    }

    public func rate(_ verdict: Verdict, score: Int?) {
        errorText = nil
        flow.rate(verdict, score: score)
    }

    public func updateNote(_ text: String) { flow.note = text }

    public func chipOptions(for field: NewNoteChipField) async -> [String] {
        guard let prepared = try? await catalog?.load() else { return [] }
        let wines = prepared.wines
        return await Task.detached(priority: .userInitiated) { field.options(in: wines) }.value
    }

    public func addChip(_ value: String, to field: NewNoteChipField) { flow.addChip(value, to: field) }

    public func setIntensity(_ value: Double, for axis: PalateAxis) { flow.setIntensity(value, for: axis) }

    public func save() async {
        guard !isWorking else { return }
        guard let draft = flow.draft else {
            if flow.needsVerdict { errorText = uiModel.resources.verdictRequiredText }
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await saveNewNote.execute(draft)
            onSaved(draft.wine.id)
        } catch {
            logger.error("New note not saved: \(error.localizedDescription, privacy: .public)")
            errorText = uiModel.resources.saveErrorText
        }
    }

    /// Scan only: once the label (or the form) gives a wine, it goes to whoever asked, once.
    private func handOverIfScanned() {
        guard let onScanned, !hasScanned, flow.step == .note, let wine = flow.wine else { return }
        hasScanned = true
        onScanned(wine)
    }

    /// The last reading, as text, for the debug section of the note.
    private func refreshDiagnostics() {
        readingDebugText = readingLog?.last.map(LabelReadingLog.text)
        readingExportText = readingLog?.last?.export?.json
    }

    private func refresh() {
        var model = uiModel
        NewNotePresentationBuilder(flow: flow, palate: palate, history: history, resources: model.resources)
            .build(into: &model)
        model.isWorking = isWorking
        model.readingStage = readingStage
        model.isReadingDone = isReadingDone
        model.isScanOnly = onScanned != nil
        model.readingDebugText = readingDebugText
        model.readingExportText = readingExportText
        model.errorText = errorText
        uiModel = model
    }
}
