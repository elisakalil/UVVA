import Core
import Foundation
import Match

/// Pure presentation mapping. Data operations and navigation belong to separate components.
struct QuizPresentationBuilder {
    let entry: QuizEntry
    let firstName: String?
    let flow: QuizFlow
    let isSaving: Bool
    let failedToSave: Bool

    var introModel: QuizIntroUIModel {
        QuizIntroUIModel(
            greeting: firstName.map { String(localized: "Welcome, \($0)", bundle: .module) }
                ?? String(localized: "Welcome", bundle: .module),
            title: String(localized: "Discover your taste in wine", bundle: .module),
            body: String(localized: "Answer eight questions about the food you love. We turn your answers into a taste map and use it to find wines you'll enjoy.", bundle: .module),
            steps: [
                QuizIntroStepUIModel(number: "01", title: String(localized: "Your palate", bundle: .module),
                                     body: String(localized: "Your answers give each of the eight axes an intensity. That shape is your taste map.", bundle: .module)),
                QuizIntroStepUIModel(number: "02", title: String(localized: "Every wine", bundle: .module),
                                     body: String(localized: "We map each wine on the same eight axes, using its grape, how it was made, time in oak, residual sugar and more.", bundle: .module)),
                QuizIntroStepUIModel(number: "03", title: String(localized: "The match", bundle: .module),
                                     body: String(localized: "We compare the two maps to find the wines closest to your taste, and the recipes that go with them.", bundle: .module))
            ],
            length: String(localized: "Eight readings · two minutes", bundle: .module),
            button: String(localized: "Read my palate", bundle: .module),
            canLeave: entry == .redo
        )
    }

    func readingModel(_ index: Int, bank: QuizQuestionBank) -> QuizReadingUIModel {
        let axis = QuizFlow.order[index]
        let question = bank.question(axis, version: flow.version(of: axis))
        let selection = flow.selection
        return QuizReadingUIModel(
            index: index,
            count: QuizFlow.order.count,
            counter: String(localized: "\(index + 1) of \(QuizFlow.order.count)", bundle: .module),
            prompt: question?.prompt ?? "",
            answer: selection.flatMap { question?.answers[$0] },
            axisName: axis.label,
            selection: selection,
            button: flow.isLastReading ? String(localized: "Draw the map", bundle: .module)
                                       : String(localized: "Next", bundle: .module),
            canAdvance: flow.canAdvance,
            footnote: String(localized: "Answer for the food, not the bottle.", bundle: .module)
        )
    }

    func resultModel(_ map: PalateMap) -> QuizResultUIModel {
        let reading = MapReading(map: map)
        return QuizResultUIModel(
            dominantPhrase: reading.dominantPhrase,
            map: map,
            highlighted: reading.highlighted,
            caption: reading.caption,
            readings: PalateAxis.allCases.map { axis in
                let level = MapReading.level(map[axis])
                return QuizReadingRowUIModel(name: axis.label, level: level, word: MapReading.levelWord(level),
                                             isStrong: reading.leaders(3).contains(axis))
            },
            narrative: reading.narrative,
            isSaving: isSaving,
            failedToSave: failedToSave
        )
    }

    func shareModel(_ map: PalateMap) -> QuizShareUIModel {
        let reading = MapReading(map: map)
        return QuizShareUIModel(
            // Without a name (no Onboarding yet), the card speaks in the second person.
            heading: firstName.map { String(localized: "\($0) taste in wine is", bundle: .module) }
                ?? String(localized: "Your taste in wine is", bundle: .module),
            dominantPhrase: reading.dominantPhrase,
            map: map,
            highlighted: reading.highlighted,
            loves: firstName.map(reading.loves) ?? reading.lovesWithoutName,
            never: reading.never,
            message: String(localized: "My taste in wine is \(reading.dominantPhrase). Map yours on uvva.app", bundle: .module)
        )
    }
}
