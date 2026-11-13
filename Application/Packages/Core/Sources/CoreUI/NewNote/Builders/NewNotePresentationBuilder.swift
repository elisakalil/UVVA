import Core
import Foundation
import Match

/// What the new note shows at each step (CELLAR.md §4). Pure: the flow in, the UI model out.
struct NewNotePresentationBuilder {
    var flow: NewNoteFlow
    var palate: PalateMap?
    var resources = NewNoteResourcesUIModel()

    func build(into model: inout NewNoteUIModel) {
        model.step = flow.step
        buildCapture(into: &model)
        buildManual(into: &model)
        buildNote(into: &model)
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
        model.wine = flow.wine
        model.palate = palate
        model.tasting = flow.tasting
        model.isRatedBefore = flow.ratedVerdict != nil
        model.draftNote = flow.note
        model.canSave = flow.canSave
        model.photo = flow.photoFront
        guard let wine = flow.wine else { return }
        let content = NotePaperContent(wine: wine, palate: palate, resources: resources.paper)
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
