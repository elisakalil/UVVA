import Core
import Foundation
import Observation

/// Runs the Quiz: the flow, the questions, saving the map and the way out (QUIZZ.md).
@MainActor @Observable
public final class QuizViewModel {
    private(set) var flow = QuizFlow()
    private(set) var bank: QuizQuestionBank?
    private(set) var isSharing = false
    private(set) var isSaving = false
    private(set) var failedToSave = false

    private let entry: QuizEntry
    private let firstName: String?
    private let questions: any QuizQuestionRepository
    private let maps: any PalateMapRepository
    private let now: () -> Date
    private let onExit: (QuizExit) -> Void

    public init(entry: QuizEntry, firstName: String?, questions: any QuizQuestionRepository,
                maps: any PalateMapRepository, now: @escaping () -> Date = Date.init,
                onExit: @escaping (QuizExit) -> Void) {
        self.entry = entry
        self.firstName = firstName
        self.questions = questions
        self.maps = maps
        self.now = now
        self.onExit = onExit
    }

    /// Loads the questions. They are the first thing the content import writes, so they are there
    /// a moment after the very first launch; until then the Intro button waits.
    func load() async {
        while bank == nil {
            if let list = try? await questions.questions() {
                let loaded = QuizQuestionBank(list)
                if loaded.isComplete { bank = loaded; return }
            }
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
        }
    }

    // MARK: Actions

    func start() { flow.start() }
    func select(_ position: Int) { flow.select(position) }
    func changeQuestion() { flow.changeQuestion() }
    func next() { flow.next() }
    func back() { flow.back() }
    func readAgain() { flow.readAgain() }

    /// "Keep this map" (QUIZ-R18): saves it, then opens the share sheet.
    func keep() async {
        guard let map = flow.map, !isSaving else { return }
        isSaving = true
        failedToSave = false
        do {
            try await maps.saveQuizMap(map, at: now())
            isSharing = true
        } catch {
            failedToSave = true
        }
        isSaving = false
    }

    /// Any action of the share sheet, "Not now" included (QUIZ-R25).
    func finish() { onExit(QuizExit(for: entry)) }

    /// Leaving a redo from the Intro: the map stays as it was (QUIZ-R26).
    func leave() {
        guard entry == .redo else { return }
        onExit(.youMap)
    }

    // MARK: Screens

    var screen: QuizScreen {
        if isSharing, let map = flow.map { return .share(shareModel(map)) }
        switch flow.step {
        case .intro: return .intro(introModel)
        case let .reading(index):
            guard let bank else { return .loading }
            return .reading(readingModel(index, bank: bank))
        case .result:
            guard let map = flow.map else { return .loading }
            return .result(resultModel(map))
        }
    }

    private var introModel: QuizIntroUIModel {
        QuizIntroUIModel(
            greeting: firstName.map { String(localized: "Welcome, \($0)", bundle: .module) }
                ?? String(localized: "Welcome", bundle: .module),
            title: String(localized: "Discover your taste in wine", bundle: .module),
            body: String(localized: "Answer eight questions about the food you love. We turn your answers into a taste map and use it to find wines you'll enjoy.", bundle: .module),
            steps: [
                QuizIntroStepUIModel(number: "01", title: String(localized: "Your palate", bundle: .module),
                                     body: String(localized: "Your answers give each of the eight axes an intensity, from sweetness to spice. That shape is your taste map.", bundle: .module)),
                QuizIntroStepUIModel(number: "02", title: String(localized: "Every wine", bundle: .module),
                                     body: String(localized: "We map each wine on the same eight axes, using its grape, how it was made, time in oak, residual sugar and region.", bundle: .module)),
                QuizIntroStepUIModel(number: "03", title: String(localized: "The match", bundle: .module),
                                     body: String(localized: "We compare the two maps to find the wines closest to your taste, and the recipes that go with them.", bundle: .module))
            ],
            length: String(localized: "Eight readings · two minutes", bundle: .module),
            button: String(localized: "Read my palate", bundle: .module),
            canLeave: entry == .redo
        )
    }

    private func readingModel(_ index: Int, bank: QuizQuestionBank) -> QuizReadingUIModel {
        let axis = QuizFlow.order[index]
        let question = bank.question(axis, version: flow.version(of: axis))
        let selection = flow.selection
        return QuizReadingUIModel(
            index: index,
            count: QuizFlow.order.count,
            counter: String(localized: "\(index + 1) of \(QuizFlow.order.count)", bundle: .module),
            title: String(localized: "Reading \(index + 1) · \(axis.label)", bundle: .module),
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

    private func resultModel(_ map: PalateMap) -> QuizResultUIModel {
        let reading = MapReading(map: map)
        return QuizResultUIModel(
            dominantPhrase: reading.dominantPhrase,
            map: map,
            top3: reading.top3,
            caption: reading.caption,
            readings: PalateAxis.allCases.map { axis in
                let level = MapReading.level(map[axis])
                return QuizReadingRowUIModel(name: axis.label, level: level, word: MapReading.levelWord(level),
                                             isStrong: reading.top3.contains(axis))
            },
            narrative: reading.narrative,
            isSaving: isSaving,
            failedToSave: failedToSave
        )
    }

    private func shareModel(_ map: PalateMap) -> QuizShareUIModel {
        let reading = MapReading(map: map)
        return QuizShareUIModel(
            // Without a name (no Onboarding yet), the card speaks in the second person.
            heading: firstName.map { String(localized: "\($0) taste in wine is", bundle: .module) }
                ?? String(localized: "Your taste in wine is", bundle: .module),
            dominantPhrase: reading.dominantPhrase,
            map: map,
            top3: reading.top3,
            loves: firstName.map(reading.loves) ?? reading.lovesWithoutName,
            never: reading.never,
            message: String(localized: "My taste in wine is \(reading.dominantPhrase). Map yours on uvva.app", bundle: .module)
        )
    }
}
