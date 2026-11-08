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
        case .back, .reading, .readFailed, .manual, .note:
            flow.cameraChecked(.authorized)
            flow.capture(Data())
            if step != .back { flow.capture(Data()) }
            if step == .readFailed { flow.labelRead(.failed) }
            if step == .manual { flow.labelRead(.unsure(LabelFacts(name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024))) }
            if step == .note { flow.labelRead(.found(Self.wine)) }
        }
        refresh()
    }

    func start() async {}
    func capture(_ photo: Data) async { flow.capture(photo) }
    func tryAgain() { flow.tryAgain() }
    func fillInByHand() { flow.fillInByHand() }
    func updateManual(_ field: NewNoteField, text: String) { flow.manual[field] = text }
    func pickType(_ type: String) { flow.manual.type = type }
    func continueManual() async { flow.manualRead(Self.wine) }
    func redo() { flow.redo() }
    func answer(hasTasted: Bool) { flow.answer(hasTasted: hasTasted) }
    func pick(_ verdict: Verdict) { flow.pick(verdict) }
    func updateNote(_ text: String) { flow.note = text }
    func save() async {}
    func close() { _ = flow.close() }
    func keepEditing() { flow.keepEditing() }
    func discard() { flow.keepEditing() }

    private func refresh() {
        var model = uiModel
        NewNotePresentationBuilder(flow: flow).build(into: &model)
        uiModel = model
    }
}
#endif
