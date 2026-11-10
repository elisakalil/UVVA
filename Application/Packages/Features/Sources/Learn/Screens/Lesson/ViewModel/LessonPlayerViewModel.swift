import Core
import DesignSystem
import Foundation
import Combine

/// The lesson player (LEARN.md §4): the cover, the steps, Check and feedback, the Summary and the certificate the
/// lesson may earn. Progress stays in memory during play and is persisted at the exit barrier.
@MainActor
public final class LessonPlayerViewModel: LessonPlayerViewModelProtocol {
    @Published public private(set) var uiModel = LessonPlayerUIModel()
    private var presentationReady = false
    enum LessonPlayerState: Equatable {
        case cover
        case step(Int)
    }

    enum Exit: Equatable {
        case close
        case finish
        case checkpoint
        /// Back from the first screen this lesson showed: to the lesson it was opened from.
        case back
        case open(LessonSummary)
    }

    public let id = UUID()
    let course: Course
    let lesson: Lesson
    /// Drawn once per opening so selections and feedback stay in place while navigating.
    let choiceOrders: [[Int]?]
    private(set) var playerState: LessonPlayerState { didSet { refresh() } }
    /// The first screen this lesson showed: back stops here.
    let entry: LessonPlayerState
    /// Opened from the list, not from another lesson: back from its first screen leaves the lessons.
    let isFirst: Bool
    private(set) var drafts: [Int: StepDraft] = [:] { didSet { refresh() } }
    /// The certificate on screen, over the Summary (LEARN-R22).
    private(set) var certificate: CertificateUIModel? { didSet { refresh() } }
    /// A completed lesson keeps its cursor, without awarding XP or a certificate again.
    let isReview: Bool

    var progressSnapshot: LessonProgress? { progress }
    /// The Summary already has a durable completion; leaving it requires no second save.
    var hasSavedSummary: Bool { isSummary && saving == nil && (isReview || completionHandled) }
    private var progress: LessonProgress?
    private var earnedCertificate: CertificateUIModel?
    private var saving: Task<Void, Error>?
    /// Completing the lesson: its save, then the certificate it may earn.
    private var completionHandled = false
    let toast: Toast
    /// The last moment to feel; the view turns it into haptics.
    private(set) var sensory: SensoryEvent?
    private let saveProgressUseCase: any SaveLessonProgressUseCaseProtocol
    private let now: () -> Date
    private let onCompleted: () async -> CertificateUIModel?
    private let onExit: (Exit) -> Void

    /// The persisted progress alone chooses the initial screen. `pickToast` picks an index in 0..<count.
    init(course: Course, lesson: Lesson, progress: LessonProgress?, isFirst: Bool = true,
         saveProgressUseCase: any SaveLessonProgressUseCaseProtocol,
         now: @escaping () -> Date = Date.init, pickToast: (Int) -> Int = { Int.random(in: 0..<$0) },
         onCompleted: @escaping () async -> CertificateUIModel?, onExit: @escaping (Exit) -> Void) {
        self.course = course
        self.lesson = lesson
        self.choiceOrders = lesson.steps.map { step in
            switch step {
            case let .multipleChoice(_, options, _, _), let .selectMultiple(_, options, _, _):
                return options.indices.shuffled()
            default:
                return nil
            }
        }
        self.progress = progress
        self.isReview = progress?.isCompleted ?? false
        self.isFirst = isFirst
        self.saveProgressUseCase = saveProgressUseCase
        self.now = now
        self.toast = Toast.all[pickToast(Toast.all.count)]
        self.onCompleted = onCompleted
        self.onExit = onExit
        let first: LessonPlayerState = if let startStep = progress?.currentStep, startStep >= 0, !lesson.steps.isEmpty {
            .step(min(max(startStep, 0), lesson.steps.count - 1))
        } else {
            .cover
        }
        playerState = first
        entry = first
        if let answers = progress?.answers { restore(answers) }
        presentationReady = true
        refresh()
        // A lesson left on its Summary before it was saved as completed completes now.
        if case let .step(index) = playerState, case .summary = lesson.steps[index], !isReview { updateProgress(markingCompleted: true) }
    }

    var stepIndex: Int? {
        if case let .step(index) = playerState { index } else { nil }
    }

    var step: LessonStep? { stepIndex.map { lesson.steps[$0] } }

    var isTip: Bool {
        if case .tip = step { true } else { false }
    }

    var isSummary: Bool {
        if case .summary = step { true } else { false }
    }

    // MARK: Cover (LEARN-R12)

    public func begin() {
        guard !lesson.steps.isEmpty else { return }
        playerState = .step(0)
        updateProgress()
    }

    /// The back chevron: always the screen before. From the first screen this lesson showed it returns to the lesson
    /// it was opened from, or leaves when there is none. Departure saves the displayed screen (LEARN-R14).
    public func back() {
        guard playerState != entry else {
            if isFirst { close() } else { onExit(.back) }
            return
        }
        switch playerState {
        case .cover: close()
        case .step(0): playerState = .cover
        case let .step(index): playerState = .step(index - 1)
        }
        updateProgress()
    }

    /// Requests departure. The coordinator persists the step and answers before dismissing.
    public func close() { onExit(.close) }

    // MARK: Answering (LEARN-R17, R18)

    func draft(_ index: Int) -> StepDraft {
        if let draft = drafts[index] { return draft }
        var draft = StepDraft()
        if case let .ordering(_, items, _) = lesson.steps[index] {
            draft.order = SeededShuffle.order(count: items.count, seed: SeededShuffle.seed(lessonID: lesson.id, step: index))
        }
        return draft
    }

    /// Changes the draft on screen; false when it is checked or nothing changed.
    @discardableResult private func edit(_ change: (inout StepDraft) -> Void) -> Bool {
        guard let index = stepIndex else { return false }
        let before = draft(index)
        var draft = before
        guard !draft.isChecked else { return false }
        change(&draft)
        guard draft != before else { return false }
        drafts[index] = draft
        return true
    }

    private func emit(_ cue: SensoryCue) {
        sensory = SensoryEvent(cue: cue, id: (sensory?.id ?? 0) + 1)
        refresh()
    }

    public func tapOption(_ option: Int) {
        let isMultiple = if case .selectMultiple = step { true } else { false }
        let changed = edit { draft in
            if isMultiple {
                if draft.selection.contains(option) { draft.selection.remove(option) } else { draft.selection.insert(option) }
            } else {
                draft.selection = [option]
            }
        }
        if changed { emit(.select) }
    }

    public func tapWord(_ word: String) {
        if edit({ $0.word = word }) { emit(.select) }
    }

    /// ordering: tap one row, then the row to swap it with; tapping the same row again lets it go.
    public func tapRow(_ position: Int) {
        let swaps = stepIndex.flatMap { drafts[$0]?.pickedRow }.map { $0 != position } ?? false
        let changed = edit { draft in
            guard let picked = draft.pickedRow else {
                draft.pickedRow = position
                return
            }
            if picked != position { draft.order.swapAt(picked, position) }
            draft.pickedRow = nil
        }
        if changed { emit(swaps ? .swap : .select) }
    }

    /// matchPairs: a linked term comes undone; another picks it, or lets it go.
    public func tapLeft(_ pair: Int) {
        let changed = edit { draft in
            draft.miss = nil
            if draft.links.contains(pair) {
                draft.links.remove(pair)
                draft.pickedLeft = nil
            } else {
                draft.pickedLeft = draft.pickedLeft == pair ? nil : pair
            }
        }
        if changed { emit(.select) }
        if let index = stepIndex, drafts[index]?.isChecked == true { updateProgress() }
    }

    public func tapRight(_ pair: Int) {
        guard case let .matchPairs(_, pairs, _) = step, let index = stepIndex else { return }
        let misses = draft(index).misses
        let changed = edit { draft in
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
        if changed, let after = drafts[index] {
            emit(after.isChecked ? .correct : after.misses > misses ? .miss : .pair)
        }
        if drafts[index]?.isChecked == true { updateProgress() }
    }

    /// The button at the foot of the step.
    public func primary() {
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
            updateProgress()
            let isRight = LessonGrader.answer(step, checked).map { LessonGrader.isCorrect(step, $0) } ?? false
            emit(isRight ? .correct : .wrong)
        default:
            // Concept, tip, or a question already checked: wrong answers move on too (LEARN-R17).
            advance(from: index)
        }
    }

    private func advance(from index: Int) {
        guard index + 1 < lesson.steps.count else { return }
        playerState = .step(index + 1)
        updateProgress()
        if case .summary = lesson.steps[index + 1] {
            emit(.toast)
            complete()
        }
    }

    // MARK: Summary, XP and certificate (LEARN-R19 to R22)

    /// Reaching the Summary completes the lesson, once (SHARED-R15, LEARN-R21).
    private func complete() {
        guard !isReview, progress?.completedAt == nil else { return }
        updateProgress(markingCompleted: true)
        onExit(.checkpoint)
    }

    /// Called after installation in the coordinator, never from init.
    func savePendingCompletion() {
        if !isReview, progress?.isCompleted == true, !completionHandled { onExit(.checkpoint) }
    }

    /// Waits for the certificate, so a quick tap on the Summary button never skips it.
    private func finish() {
        // The coordinator owns every departure, including Summary -> certificate/next lesson.
        onExit(.finish)
    }

    func finishAfterSaving() -> Exit? {
        if let earned = earnedCertificate {
            earnedCertificate = nil
            certificate = earned
            return nil
        }
        return nextExit
    }

    /// The certificate closed ("Share", "Save image" or "Not now").
    public func closeCertificate() {
        certificate = nil
        proceed()
    }

    private var nextExit: Exit {
        if let next = course.lesson(after: lesson.summary) { .open(next) } else { .close }
    }

    private func proceed() { onExit(nextExit) }

    // MARK: Saving (LEARN-R14)

    private func updateProgress(markingCompleted: Bool = false) {
        var record = progress ?? LessonProgress(lessonID: lesson.id, courseID: course.id, lastOpenedAt: now())
        record.currentStep = stepIndex ?? -1
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
    }

    /// The only persistence entry point. Called by the coordinator when leaving a lesson.
    /// A failed save keeps the player alive; the same snapshot can be retried.
    func saveOnExit() async throws {
        if let saving { try await saving.value; return }
        // A lesson is recorded only once "Begin lesson" is tapped: opening its cover and leaving keeps no trace.
        // `progress` is nil until then, unless the lesson was already begun before.
        guard progress != nil else { return }
        updateProgress()
        guard var snapshot = progress else { return }
        snapshot.revision += 1
        let useCase = saveProgressUseCase
        let record = snapshot
        let course = course
        let task = Task.detached(priority: .utility) { try await useCase.execute(record, in: course) }
        saving = task
        defer { saving = nil }
        try await task.value
        progress = snapshot
        if snapshot.isCompleted, !isReview, !completionHandled {
            completionHandled = true
            earnedCertificate = await onCompleted()
        }
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
    private func refresh() {
        guard presentationReady else { return }
        uiModel = LessonPlayerUIModel(cover: cover, header: header, stepModel: stepModel, footer: footer,
                                      certificate: certificate, stepIndex: stepIndex, isTip: isTip,
                                      isSummary: isSummary, isCover: playerState == .cover, sensory: sensory)
    }
}
