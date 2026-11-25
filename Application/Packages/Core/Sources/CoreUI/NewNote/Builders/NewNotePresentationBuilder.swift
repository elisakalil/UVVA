import Core
import Foundation
import Match

/// What the new note shows at each step (CELLAR.md §4). Pure: the flow in, the UI model out.
struct NewNotePresentationBuilder {
    var flow: NewNoteFlow
    var palate: PalateMap?
    /// The wines the user rated, for what they know of the grape and the region. Nil until it loads.
    var history: TasteHistory?
    var resources = NewNoteResourcesUIModel()

    func build(into model: inout NewNoteUIModel) {
        model.step = flow.step
        buildCapture(into: &model)
        buildManual(into: &model)
        buildNote(into: &model)
    }

    // MARK: Camera (CELLAR-R16, R17)

    private func buildCapture(into model: inout NewNoteUIModel) {
        // A word or two: the frame, the shutter and the motion say the rest.
        model.captureTitle = switch flow.step {
        case .back: resources.backTitleText
        case .reading: resources.readingTitleText
        default: resources.frontTitleText
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
        let form = flow.manual
        let labels: [NewNoteField: (String, String)] = [
            .name: (resources.wineFieldText, ""), .producer: (resources.producerFieldText, ""),
            .vintage: (resources.vintageFieldText, ""), .alcohol: (resources.alcoholFieldText, resources.alcoholPromptText)
        ]
        let hints = ([
            .vintage: form.isVintageValid ? nil : resources.vintageHint(form.currentYear),
            .alcohol: form.isAlcoholValid ? nil : resources.alcoholHintText
        ] as [NewNoteField: String?]).compactMapValues { $0 }
        // What is typed; then the type; then what is chosen from the catalog's lists (CELLAR-R23).
        model.manualFields = [NewNoteField.name, .producer, .vintage, .alcohol].map { field in
            NewNoteManualFieldUIModel(field: field, label: labels[field]?.0 ?? "", text: form[field],
                                      prompt: labels[field]?.1 ?? "", hint: hints[field])
        }
        model.types = NewNoteResourcesUIModel.types.map {
            NewNoteTypeUIModel(type: $0, label: resources.type($0), isSelected: form.type == $0)
        }
        model.manualChipRows = [NewNoteManualChipField.region, .appellation, .designation, .grapes, .notes]
            .map { chipRow($0, form: form) }
        model.oakAgings = OakAging.allCases.map {
            NewNoteOakUIModel(aging: $0, label: resources.oakAging($0), isSelected: form.oakAging == $0)
        }
        model.oakWoodsRow = form.oakAging == nil || form.oakAging == OakAging.none ? nil : chipRow(.oakWoods, form: form)
        model.awards = form.awards.map { NewNoteAwardUIModel(award: $0, label: resources.award($0)) }
        model.mapBasisHint = form.hasMapBasis ? nil : resources.mapBasisText
        model.canContinue = flow.canContinueManual
    }

    private func chipRow(_ field: NewNoteManualChipField, form: NewNoteManualForm) -> NewNoteManualChipRowUIModel {
        let label = resources.manualChipField(field)
        return NewNoteManualChipRowUIModel(
            field: field, label: label,
            chips: form.chips(field).map { NewNoteManualChipUIModel(value: $0, label: resources.manualChip($0, field: field)) },
            addLabel: resources.paper.addText(label))
    }

    // MARK: The note (CELLAR-R18 to R20, R24)

    private func buildNote(into model: inout NewNoteUIModel) {
        model.wine = flow.wine
        model.palate = palate
        model.tasting = flow.tasting
        model.isRatedBefore = flow.ratedVerdict != nil
        model.currentVerdict = flow.draft?.verdict
        model.currentScore = flow.draft?.score
        model.draftNote = flow.note
        model.canSave = flow.canSave
        model.photoFront = flow.photoFront
        model.photoBack = flow.photoBack
        guard let wine = flow.wine else { return }
        let content = NotePaperContent(wine: wine, palate: palate, history: history, resources: resources.paper)
        model.content = content
        model.title = content.title
        model.facts = content.facts
        model.findURL = content.findURL
        model.verdicts = [(Verdict.yes, resources.yesText), (.no, resources.noText), (.maybe, resources.maybeText)]
            .map { verdict, label in
                NoteVerdictUIModel(verdict: verdict, label: label, isSelected: flow.verdict == verdict)
            }
    }
}
