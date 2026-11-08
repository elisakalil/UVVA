import Core
import Foundation

/// What the new note shows at each step (CELLAR.md §4). Pure: the flow in, the UI model out.
struct NewNotePresentationBuilder {
    var flow: NewNoteFlow
    var resources = NewNoteResourcesUIModel()
    var noteResources = NoteResourcesUIModel()

    func build(into model: inout NewNoteUIModel) {
        model.step = flow.step
        buildCapture(into: &model)
        buildManual(into: &model)
        buildNote(into: &model)
        model.isConfirmingDiscard = flow.isConfirmingDiscard
    }

    // MARK: Camera (CELLAR-R16, R17)

    private func buildCapture(into model: inout NewNoteUIModel) {
        switch flow.step {
        case .back:
            model.captureTitle = resources.backTitleText
            model.captureBody = resources.backBodyText
        case .reading:
            model.captureTitle = resources.readingTitleText
            model.captureBody = resources.readingBodyText
        default:
            model.captureTitle = resources.frontTitleText
            model.captureBody = resources.frontBodyText
        }
        let frontDone = flow.photoFront != nil
        let backDone = flow.photoBack != nil
        model.captureSteps = [
            NewNoteCaptureStepUIModel(number: "01", label: resources.frontStepText,
                                      isCurrent: flow.step == .front, isDone: frontDone),
            NewNoteCaptureStepUIModel(number: "02", label: resources.backStepText,
                                      isCurrent: flow.step == .back, isDone: backDone)
        ]
        model.readingPhoto = flow.step == .reading ? flow.photoBack : nil
    }

    // MARK: By hand (CELLAR-R23)

    private func buildManual(into model: inout NewNoteUIModel) {
        let labels: [NewNoteField: (String, String)] = [
            .name: (resources.wineFieldText, ""), .producer: (resources.producerFieldText, ""),
            .region: (resources.regionFieldText, resources.regionPromptText),
            .vintage: (resources.vintageFieldText, ""), .grape: (resources.grapeFieldText, resources.grapePromptText)
        ]
        // The artboard's order: Wine, Producer, Region, Vintage, Grape.
        model.manualFields = [NewNoteField.name, .producer, .region, .vintage, .grape].map { field in
            NewNoteManualFieldUIModel(field: field, label: labels[field]?.0 ?? "", text: flow.manual[field],
                                      prompt: labels[field]?.1 ?? "")
        }
        model.types = NewNoteResourcesUIModel.types.map {
            NewNoteTypeUIModel(type: $0, label: resources.type($0), isSelected: flow.manual.type == $0)
        }
        model.canContinue = flow.canContinueManual
    }

    // MARK: The note (CELLAR-R18 to R20, R24)

    private func buildNote(into model: inout NewNoteUIModel) {
        model.photoFront = flow.photoFront
        model.photoBack = flow.photoBack
        model.tasting = flow.tasting
        model.draftNote = flow.note
        model.canSave = flow.canSave
        model.canRedo = flow.canRedo
        guard let wine = flow.wine else {
            model.title = ""
            model.subtitle = ""
            model.facts = []
            model.structure = []
            model.readingText = nil
            model.aromas = nil
            model.findURL = nil
            model.verdicts = []
            return
        }
        // The saved note's builder, on the wine as it would be saved.
        let note = NotePresentationBuilder(entry: Self.entry(wine), wine: wine, resources: noteResources)
        model.title = wine.name
        model.subtitle = note.subtitle
        model.facts = note.facts
        model.structure = note.structure
        model.readingText = wine.originInsight
        model.aromas = note.aromas
        model.verdicts = note.verdicts(selected: flow.verdict)
        model.findURL = WineSearch.url(for: wine)
    }

    static func entry(_ wine: Wine) -> CellarEntry {
        CellarEntry(id: wine.id, name: wine.name, producer: wine.producer, vintage: wine.vintage, type: wine.type,
                    region: wine.region, country: wine.country, origin: wine.origin, grapes: wine.grapes,
                    status: .wantToTry, alcohol: wine.alcohol, classification: wine.classification, createdAt: .now)
    }
}
