import Core
import Foundation

/// What the player draws, built from the lesson and the drafts.
extension LessonPlayerViewModel {
    static func two(_ number: Int) -> String { String(format: "%02d", number) }

    var cover: LessonCoverUIModel {
        let summary = lesson.summary
        return LessonCoverUIModel(
            eyebrow: course.title,
            number: Self.two(summary.order),
            title: summary.title,
            subtitle: summary.subtitle,
            minutes: "\(summary.minutes)",
            xp: "\(summary.xp)",
            steps: "\(lesson.steps.count)",
            objectives: summary.objectives,
            showsReviewPrevious: course.lesson(before: summary) != nil
        )
    }

    var header: StepHeaderUIModel {
        let total = lesson.steps.count
        let isSummary = if case .summary = step { true } else { false }
        let current = stepIndex.flatMap { isSummary ? nil : $0 }
        return StepHeaderUIModel(
            brand: current == nil ? "UVVA" : String(localized: "Lesson \(lesson.summary.order)", bundle: .module),
            title: lesson.summary.title,
            current: current,
            total: total,
            counter: current.map { "\(Self.two($0 + 1)) / \(Self.two(total))" } ?? "",
            backLeaves: phase == entry && isFirst
        )
    }

    var stepModel: StepUIModel? {
        guard let index = stepIndex, let step else { return nil }
        let draft = draft(index)
        switch step {
        case let .concept(title, body, highlight):
            return .concept(title: title, body: body, highlight: highlight)
        case let .tip(body):
            return .tip(body: body)
        case let .multipleChoice(prompt, options, answer, _):
            return .choice(ChoiceUIModel(kind: .single, prompt: prompt,
                                         options: choices(options, right: [answer], draft: draft, numbered: true)))
        case let .selectMultiple(prompt, options, answers, _):
            return .choice(ChoiceUIModel(kind: .multiple, prompt: prompt, options: choices(options, right: answers, draft: draft, numbered: false)))
        case let .trueFalse(prompt, answer, _):
            let labels = [String(localized: "True", bundle: .module), String(localized: "False", bundle: .module)]
            return .choice(ChoiceUIModel(kind: .trueFalse, prompt: prompt, options: choices(labels, right: [answer ? 0 : 1], draft: draft, numbered: false)))
        case let .fillBlank(prompt, options, answer, _):
            let parts = prompt.components(separatedBy: "____")
            let wordState: OptionState = draft.isChecked ? (draft.word == answer ? .correct : .wrong)
                : draft.word == nil ? .idle : .selected
            return .fillBlank(FillBlankUIModel(
                before: parts.first ?? prompt,
                after: parts.dropFirst().joined(separator: "____"),
                word: draft.word,
                wordState: wordState,
                options: options.enumerated().map { index, word in
                    let state: OptionState = draft.isChecked
                        ? (word == answer ? .correct : word == draft.word ? .wrong : .idle)
                        : (word == draft.word ? .selected : .idle)
                    return OptionUIModel(id: index, number: "", label: word, state: state)
                }))
        case let .ordering(prompt, items, _):
            return .ordering(OrderingUIModel(
                prompt: prompt,
                hint: draft.pickedRow == nil
                    ? String(localized: "Tap two items to swap them.", bundle: .module)
                    : String(localized: "Now tap where it should go.", bundle: .module),
                rows: draft.order.enumerated().map { position, item in
                    let state: OptionState = draft.isChecked ? (item == position ? .correct : .wrong)
                        : draft.pickedRow == position ? .selected : .idle
                    return OptionUIModel(id: position, number: Self.two(position + 1), label: items[item], state: state)
                }))
        case let .matchPairs(prompt, pairs, _):
            let shuffled = SeededShuffle.order(count: pairs.count, seed: SeededShuffle.seed(lessonID: lesson.id, step: index))
            func state(_ pair: Int, isLeft: Bool) -> OptionState {
                if draft.links.contains(pair) { return .correct }
                if let miss = draft.miss, (isLeft ? miss.left : miss.right) == pair { return .wrong }
                return isLeft && draft.pickedLeft == pair ? .selected : .idle
            }
            return .matchPairs(MatchPairsUIModel(
                prompt: prompt,
                left: pairs.enumerated().map { OptionUIModel(id: $0.offset, number: "", label: $0.element.left, state: state($0.offset, isLeft: true)) },
                right: shuffled.map { OptionUIModel(id: $0, number: "", label: pairs[$0].right, state: state($0, isLeft: false)) },
                status: draft.miss != nil
                    ? String(localized: "Not a pair. Try again.", bundle: .module)
                    : String(localized: "\(draft.links.count) of \(pairs.count) matched", bundle: .module),
                isMiss: draft.miss != nil))
        case let .summary(_, points):
            return .summary(summary(points: points))
        }
    }

    private func choices(_ labels: [String], right: Set<Int>, draft: StepDraft, numbered: Bool) -> [OptionUIModel] {
        labels.enumerated().map { index, label in
            let state: OptionState = draft.isChecked
                ? (right.contains(index) ? .correct : draft.selection.contains(index) ? .wrong : .idle)
                : (draft.selection.contains(index) ? .selected : .idle)
            return OptionUIModel(id: index, number: numbered ? Self.two(index + 1) : "", label: label, state: state)
        }
    }

    /// LEARN-R19
    private func summary(points: [String]) -> LessonSummaryUIModel {
        let next = course.lesson(after: lesson.summary)
        return LessonSummaryUIModel(
            toast: toast.word,
            toastMeaning: String(localized: "means “cheers” in \(toast.language)", bundle: .module),
            completion: isReview ? String(localized: "Lesson complete", bundle: .module)
                : String(localized: "Lesson complete +\(lesson.summary.xp) XP", bundle: .module),
            points: points,
            nextEyebrow: next == nil ? String(localized: "Module complete", bundle: .module) : String(localized: "Next lesson", bundle: .module),
            nextTitle: next?.title ?? course.title
        )
    }

    var footer: PlayerFooterUIModel {
        guard let index = stepIndex, let step else {
            return .button(title: String(localized: "Begin lesson", bundle: .module), isEnabled: true)
        }
        let draft = draft(index)
        switch step {
        case .concept:
            return .button(title: String(localized: "Continue", bundle: .module), isEnabled: true)
        case .tip:
            return .button(title: String(localized: "Got it", bundle: .module), isEnabled: true)
        case .summary:
            return .button(title: course.lesson(after: lesson.summary) == nil
                           ? String(localized: "Finish module", bundle: .module)
                           : String(localized: "Next lesson", bundle: .module), isEnabled: true)
        case let .matchPairs(_, pairs, _) where !draft.isChecked:
            return .button(title: "\(draft.links.count) / \(pairs.count)", isEnabled: false)
        default:
            guard draft.isChecked, let answer = LessonGrader.answer(step, draft) else {
                return .button(title: String(localized: "Check", bundle: .module), isEnabled: LessonGrader.canCheck(step, draft))
            }
            let isCorrect = LessonGrader.isCorrect(step, answer)
            return .feedback(FeedbackUIModel(
                isCorrect: isCorrect,
                title: isCorrect ? String(localized: "Correct", bundle: .module) : String(localized: "Not quite", bundle: .module),
                text: LessonGrader.explanation(step, answer)))
        }
    }
}
