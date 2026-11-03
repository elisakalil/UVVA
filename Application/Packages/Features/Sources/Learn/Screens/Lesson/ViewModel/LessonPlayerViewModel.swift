import Core
import DesignSystem
import Foundation
import Observation

/// The lesson player (LEARN.md §4): the cover, the steps, Check and feedback, the Summary and the certificate the
/// lesson may earn. Progress is saved as the learner goes, so leaving at any point resumes there (LEARN-R14).
@MainActor @Observable
final class LessonPlayerViewModel: Identifiable {
    enum Phase: Equatable {
        case cover
        case step(Int)
    }

    enum Exit: Equatable {
        case close
        /// Back from the first screen this lesson showed: to the lesson it was opened from.
        case back
        case open(LessonSummary)
    }

    let id = UUID()
    let course: Course
    let lesson: Lesson
    private(set) var phase: Phase
    /// The first screen this lesson showed: back stops here.
    let entry: Phase
    /// Opened from the list, not from another lesson: back from its first screen leaves the lessons.
    let isFirst: Bool
    private(set) var drafts: [Int: StepDraft] = [:]
    /// The certificate on screen, over the Summary (LEARN-R22).
    private(set) var certificate: CertificateUIModel?
    /// The lesson was completed before it opened: it plays again, without XP and without saving (LEARN-R19a).
    let isReview: Bool

    private var progress: LessonProgress?
    private var earnedCertificate: CertificateUIModel?
    private var saving: Task<Void, Never>?
    /// Completing the lesson: its save, then the certificate it may earn.
    private var completing: Task<Void, Never>?
    let toast: Toast
    private let learning: any LearningRepository
    private let now: () -> Date
    private let onCompleted: () async -> CertificateUIModel?
    private let onExit: (Exit) -> Void

    /// `startStep` resumes at a saved step; nil opens the cover. `pickToast` picks an index in 0..<count.
    init(course: Course, lesson: Lesson, progress: LessonProgress?, startStep: Int?, isFirst: Bool = true,
         learning: any LearningRepository,
         now: @escaping () -> Date = Date.init, pickToast: (Int) -> Int = { Int.random(in: 0..<$0) },
         onCompleted: @escaping () async -> CertificateUIModel?, onExit: @escaping (Exit) -> Void) {
        self.course = course
        self.lesson = lesson
        self.progress = progress
        self.isReview = progress?.isCompleted ?? false
        self.isFirst = isFirst
        self.learning = learning
        self.now = now
        self.toast = Toast.all[pickToast(Toast.all.count)]
        self.onCompleted = onCompleted
        self.onExit = onExit
        let first: Phase = if let startStep, !lesson.steps.isEmpty {
            .step(min(max(startStep, 0), lesson.steps.count - 1))
        } else {
            .cover
        }
        phase = first
        entry = first
        if !isReview, let answers = progress?.answers { restore(answers) }
        // A lesson left on its Summary before it was saved as completed completes now.
        if case let .step(index) = phase, case .summary = lesson.steps[index] { complete() }
    }

    var stepIndex: Int? {
        if case let .step(index) = phase { index } else { nil }
    }

    var step: LessonStep? { stepIndex.map { lesson.steps[$0] } }

    var isTip: Bool {
        if case .tip = step { true } else { false }
    }

    var isSummary: Bool {
        if case .summary = step { true } else { false }
    }

    // MARK: Cover (LEARN-R12)

    func begin() {
        guard !lesson.steps.isEmpty else { return }
        phase = .step(0)
        save()
    }

    /// "Review previous lesson".
    func reviewPrevious() {
        guard let previous = course.lesson(before: lesson.summary) else { return }
        onExit(.open(previous))
    }

    /// The back chevron: always the screen before. From the first screen this lesson showed it returns to the lesson
    /// it was opened from, or leaves when there is none. The farthest step stays saved, so the lesson still resumes
    /// there (LEARN-R14).
    func back() {
        guard phase != entry else {
            if isFirst { close() } else { onExit(.back) }
            return
        }
        switch phase {
        case .cover: close()
        case .step(0): phase = .cover
        case let .step(index): phase = .step(index - 1)
        }
    }

    /// Leaves the lessons, from the back chevron or a drag down: the step and the answers are already saved (LEARN-R14).
    func close() { onExit(.close) }

    // MARK: Answering (LEARN-R17, R18)

    func draft(_ index: Int) -> StepDraft {
        if let draft = drafts[index] { return draft }
        var draft = StepDraft()
        if case let .ordering(_, items, _) = lesson.steps[index] {
            draft.order = SeededShuffle.order(count: items.count, seed: SeededShuffle.seed(lessonID: lesson.id, step: index))
        }
        return draft
    }

    private func edit(_ change: (inout StepDraft) -> Void) {
        guard let index = stepIndex else { return }
        var draft = draft(index)
        guard !draft.isChecked else { return }
        change(&draft)
        drafts[index] = draft
    }

    func tapOption(_ option: Int) {
        let isMultiple = if case .selectMultiple = step { true } else { false }
        edit { draft in
            if isMultiple {
                if draft.selection.contains(option) { draft.selection.remove(option) } else { draft.selection.insert(option) }
            } else {
                draft.selection = [option]
            }
        }
    }

    func tapWord(_ word: String) {
        edit { $0.word = word }
    }

    /// ordering: tap one row, then the row to swap it with; tapping the same row again lets it go.
    func tapRow(_ position: Int) {
        edit { draft in
            guard let picked = draft.pickedRow else {
                draft.pickedRow = position
                return
            }
            if picked != position { draft.order.swapAt(picked, position) }
            draft.pickedRow = nil
        }
    }

    /// matchPairs: a linked term comes undone; another picks it, or lets it go.
    func tapLeft(_ pair: Int) {
        edit { draft in
            draft.miss = nil
            if draft.links.contains(pair) {
                draft.links.remove(pair)
                draft.pickedLeft = nil
            } else {
                draft.pickedLeft = draft.pickedLeft == pair ? nil : pair
            }
        }
        if let index = stepIndex, drafts[index]?.isChecked == true { save() }
    }

    func tapRight(_ pair: Int) {
        guard case let .matchPairs(_, pairs, _) = step else { return }
        edit { draft in
            guard let left = draft.pickedLeft, !draft.links.contains(pair) else { return }
            draft.pickedLeft = nil
            if left == pair {
                draft.links.insert(pair)
                draft.miss = nil
                // All linked: matchPairs has no Check, the feedback shows now.
                if draft.links.count == pairs.count { draft.isChecked = true }
            } else {
                draft.miss = StepDraft.Miss(left: left, right: pair)
                draft.misses += 1
            }
        }
        if let index = stepIndex, drafts[index]?.isChecked == true { save() }
    }

    /// The button at the foot of the step.
    func primary() {
        guard let index = stepIndex, let step else { return }
        let draft = draft(index)
        switch step {
        case .summary:
            finish()
        case _ where step.isQuestion && !draft.isChecked:
            guard LessonGrader.canCheck(step, draft) else { return }
            var checked = draft
            checked.isChecked = true
            checked.pickedRow = nil
            drafts[index] = checked
            save()
        default:
            // Concept, tip, or a question already checked: wrong answers move on too (LEARN-R17).
            advance(from: index)
        }
    }

    private func advance(from index: Int) {
        guard index + 1 < lesson.steps.count else { return }
        phase = .step(index + 1)
        save()
        if case .summary = lesson.steps[index + 1] { complete() }
    }

    // MARK: Summary, XP and certificate (LEARN-R19 to R22)

    /// Reaching the Summary completes the lesson, once (SHARED-R15, LEARN-R21).
    private func complete() {
        guard !isReview, progress?.completedAt == nil else { return }
        save(markingCompleted: true)
        let pending = saving
        completing = Task {
            await pending?.value
            earnedCertificate = await onCompleted()
        }
    }

    /// Waits for the certificate, so a quick tap on the Summary button never skips it.
    private func finish() {
        let completing = completing
        Task {
            await completing?.value
            showCertificateOrProceed()
        }
    }

    private func showCertificateOrProceed() {
        if let earned = earnedCertificate {
            earnedCertificate = nil
            certificate = earned
            return
        }
        proceed()
    }

    /// The certificate closed ("Share", "Save image" or "Not now").
    func closeCertificate() {
        certificate = nil
        proceed()
    }

    private func proceed() {
        if let next = course.lesson(after: lesson.summary) { onExit(.open(next)) } else { onExit(.close) }
    }

    // MARK: Saving (LEARN-R14)

    private func save(markingCompleted: Bool = false) {
        guard !isReview else { return }
        var record = progress ?? LessonProgress(lessonID: lesson.id, courseID: course.id, lastOpenedAt: now())
        record.currentStep = stepIndex ?? 0
        record.answers = drafts.reduce(into: [:]) { answers, entry in
            guard entry.value.isChecked, let answer = LessonGrader.answer(lesson.steps[entry.key], entry.value) else { return }
            answers[entry.key] = answer
        }
        record.lastOpenedAt = now()
        if markingCompleted, record.completedAt == nil {
            record.completedAt = now()
            record.xp = lesson.summary.xp
        }
        progress = record
        let learning = learning
        let previous = saving
        saving = Task {
            await previous?.value
            try? await learning.save(record)
        }
    }

    /// Waits for the saves in flight, so what opens next reads them.
    func flush() async {
        await saving?.value
        await completing?.value
    }

    private func restore(_ answers: [Int: LessonAnswer]) {
        for (index, answer) in answers where lesson.steps.indices.contains(index) {
            var draft = draft(index)
            switch answer {
            case let .options(selection): draft.selection = selection
            case let .trueFalse(value): draft.selection = [value ? 0 : 1]
            case let .word(word): draft.word = word
            case let .order(order): draft.order = order
            case let .pairs(misses):
                if case let .matchPairs(_, pairs, _) = lesson.steps[index] { draft.links = Set(pairs.indices) }
                draft.misses = misses
            }
            draft.isChecked = true
            drafts[index] = draft
        }
    }
}
