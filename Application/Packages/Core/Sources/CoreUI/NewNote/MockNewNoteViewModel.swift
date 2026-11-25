#if DEBUG
import Combine
import Core
import Foundation

/// A new note at a given step, for the previews.
@MainActor
final class MockNewNoteViewModel: NewNoteViewModelProtocol {
    @Published var uiModel = NewNoteUIModel()
    private var flow = NewNoteFlow() { didSet { refresh() } }

    static let wine = Wine(id: "ravasqueira-ponto-forte-2024", name: "Ponto Forte", producer: "Ravasqueira",
                           vintage: 2024, type: "Red", origin: "Vinho Regional Alentejano, Portugal",
                           region: "Alentejo", country: "Portugal", grapes: ["Syrah", "Viognier"], alcohol: 13.5,
                           profile: PalateMap([.body: 7, .tannin: 5, .acidity: 5, .fruit: 7, .spice: 6, .sweetness: 1]),
                           note: "Plum, pepper, violet.",
                           originInsight: "Hot, dry plains where reds come out ripe, round and generous.")

    init(step: NewNoteStep) {
        switch step {
        case .checkingCamera: break
        case .cameraDenied: flow.cameraChecked(.denied)
        case .front: flow.cameraChecked(.authorized)
        case .back, .reading, .readFailed, .notWine, .manual, .note:
            flow.cameraChecked(.authorized)
            flow.capture(Data())
            if step != .back { flow.capture(Data()) }
            if step == .readFailed { flow.labelRead(.failed) }
            if step == .notWine { flow.labelRead(.notWine) }
            if step == .manual { flow.labelRead(.incomplete(LabelFacts(producer: "Ravasqueira", vintage: 2024))) }
            if step == .note { flow.labelRead(.read(Self.wine)) }
        }
        refresh()
    }

    func start() async {}
    /// The whole reading, step by step, so the preview shows it as the app does.
    func capture(_ photo: Data, reading: Data?, scan: LabelScan?) async {
        flow.capture(photo)
        guard flow.step == .reading else { return }
        for stage in LabelReadStage.allCases {
            uiModel.readingStage = stage
            try? await Task.sleep(for: .seconds(1.2))
        }
        uiModel.isReadingDone = true
        try? await Task.sleep(for: .milliseconds(450))
        flow.labelRead(.read(Self.wine))
    }
    func tryAgain() { flow.tryAgain() }
    func fillInByHand() { flow.fillInByHand() }
    func updateManual(_ field: NewNoteField, text: String) { flow.manual[field] = text }
    func pickType(_ type: String) { flow.manual.type = type }
    func manualChipOptions(for field: NewNoteManualChipField) async -> [String] {
        switch field {
        case .region: ["Alentejo", "Douro", "Dão", "Lisboa"]
        case .appellation: ["Alentejo DOC", "Douro DOC", "Vinho Regional Alentejano"]
        case .grapes: ["Touriga Nacional", "Aragonez", "Trincadeira", "Alicante Bouschet"]
        case .notes: ["Blackberry", "Cedar", "Cherry", "Licorice", "Vanilla"]
        case .designation, .oakWoods: field.options(in: [])
        }
    }
    func validateManualChip(_ typed: String, for field: NewNoteManualChipField) async -> ChipWordResult {
        guard let kind = field.wordKind else { return .rejected(.notAWord) }
        return await ChipWordValidator(known: await manualChipOptions(for: field), kind: kind)
            .validate(typed, checker: NoChipWordChecker())
    }
    func chooseManual(_ values: [String], for field: NewNoteManualChipField) { flow.manual.choose(values, for: field) }
    func removeManual(_ value: String, from field: NewNoteManualChipField) { flow.manual.remove(value, from: field) }
    func pickOakAging(_ aging: OakAging) { flow.manual.pick(aging) }
    func addAward(_ award: WineAward) { flow.manual.add(award) }
    func removeAward(_ award: WineAward) { flow.manual.remove(award) }
    func continueManual() async { flow.manualRead(Self.wine) }
    func replacePhoto(_ photo: Data, side: NewNotePhotoSide) { flow.replacePhoto(photo, side: side) }
    func answer(hasTasted: Bool) { flow.answer(hasTasted: hasTasted) }
    func pick(_ verdict: Verdict) { flow.pick(verdict) }
    func rate(_ verdict: Verdict, score: Int?) { flow.rate(verdict, score: score) }
    func updateNote(_ text: String) { flow.note = text }
    func chipOptions(for field: NewNoteChipField) async -> [String] {
        switch field {
        case .grapes: ["Touriga Nacional", "Aragonez", "Trincadeira", "Alicante Bouschet"]
        case .notes: ["Blackberry", "Cedar", "Cherry", "Licorice", "Vanilla"]
        case .pairings: ["Grilled meat", "Mushrooms", "Roast vegetables", "Hard cheeses"]
        }
    }
    func validateChip(_ typed: String, for field: NewNoteChipField) async -> ChipWordResult {
        await ChipWordValidator(known: await chipOptions(for: field), kind: field.wordKind)
            .validate(typed, checker: NoChipWordChecker())
    }
    func addChip(_ value: String, to field: NewNoteChipField) { flow.addChip(value, to: field) }
    func setIntensity(_ value: Double, for axis: PalateAxis) { flow.setIntensity(value, for: axis) }
    func save() async {}

    private func refresh() {
        var model = uiModel
        NewNotePresentationBuilder(flow: flow, palate: PalateMap([.body: 6, .fruit: 8, .acidity: 4])).build(into: &model)
        uiModel = model
    }
}
#endif
