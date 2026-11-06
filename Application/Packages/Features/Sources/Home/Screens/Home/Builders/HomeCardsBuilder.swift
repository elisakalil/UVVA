import Core
import Foundation
import Match

/// Builds the Home cards from the model. Pure: no UI, no clock or randomness of its own (SHARED-R04).
struct HomeCardsBuilder {
    var calendar: Calendar = .current
    /// Picks an index in 0..<count for the word of the day; injected so tests can fix it (HOME-R19).
    var pickWordIndex: (Int) -> Int = { Int.random(in: 0..<$0) }

    static let winesForPalateCount = 3
    /// The day's wine is drawn from the closest wines with a dish (HOME-R06, R07).
    static let dailySuggestionPool = 30

    func build(from model: HomeContentModel, now: Date) -> [HomeCardModel] {
        var cards: [HomeCardModel] = [header(model)]
        if let wine = dailySuggestion(model, now: now) { cards.append(.dailySuggestion(wine)) }
        cards.append(.friends(friendsCardState(model.friends)))
        if let course = continueLesson(model.courses) { cards.append(.continueLesson(course)) }
        if let changed = axisChanged(model.lastRating) { cards.append(.changedMapCard(axis: changed.axis, delta: changed.delta)) }
        let lessons = dailyLessons(model, now: now)
        if !lessons.isEmpty { cards.append(.learnShortcuts(lessons)) }
        if !model.glossary.isEmpty { cards.append(.wordOfTheDay(model.glossary[pickWordIndex(model.glossary.count)])) }
        let wines = winesForPalate(model)
        if !wines.isEmpty { cards.append(.winesForPalate(wines)) }
        cards.append(.chooseYourWine)
        return cards
    }

    // HOME-R02, HOME-R04
    func header(_ model: HomeContentModel) -> HomeCardModel {
        .header(greeting: "Welcome back, \(model.firstName)",
                hasUnread: model.notifications.contains { !$0.isRead })
    }

    // HOME-R06, R07, R08, R10: same wine all day, a new pick each day.
    func dailySuggestion(_ model: HomeContentModel, now: Date) -> Wine? {
        let pool = model.catalog
            .filter { $0.dish != nil }
            .sorted { Similarity.between($0.profile, model.palateMap) > Similarity.between($1.profile, model.palateMap) }
            .prefix(Self.dailySuggestionPool)
        guard !pool.isEmpty else { return nil }
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        return Array(pool)[day % pool.count]
    }

    /// Daily deterministic shuffle of unfinished lessons, one per Learn category.
    func dailyLessons(_ model: HomeContentModel, now: Date) -> [HomeLessonSuggestion] {
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        return [CourseKind.region, .grape, .path].compactMap { kind in
            let candidates = model.lessonCatalog.filter { $0.kind == kind }.flatMap { course -> [HomeLessonSuggestion] in
                let module = model.modules[course.id]
                guard CourseRules.state(of: course, module: module) != .done,
                      let entry = CourseRules.entry(for: course, module: module, progress: model.lessonProgress),
                      let lesson = course.lessons.first(where: { $0.id == entry.lessonID }), !lesson.isReview else { return [] }
                return [HomeLessonSuggestion(course: course, lesson: lesson)]
            }
            return candidates.min { lhs, rhs in
                let a = dailyRank("\(day):\(lhs.course.id)")
                let b = dailyRank("\(day):\(rhs.course.id)")
                return a == b ? lhs.lesson.id < rhs.lesson.id : a < b
            }
        }
    }

    private func dailyRank(_ text: String) -> UInt64 {
        text.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }

    // HOME-R11
    func friendsCardState(_ friends: [Friend]) -> HomeCardModel.FriendsCardState {
        switch friends.count {
        case 0: .noFriends
        case 1: .hasMatch(friends[0])
        default: .hasFriends(count: friends.count)
        }
    }

    // HOME-R12, R13
    func continueLesson(_ courses: [CourseProgress]) -> CourseProgress? {
        courses
            .filter(\.isInProgress)
            .max { ($0.lastOpenedAt ?? .distantPast) < ($1.lastOpenedAt ?? .distantPast) }
    }

    // HOME-R15, R16: the axis that moved most; ties follow the canonical order.
    func axisChanged(_ rating: Rating?) -> (axis: PalateAxis, delta: Double)? {
        guard let rating else { return nil }
        var best: (axis: PalateAxis, delta: Double)?
        for axis in PalateAxis.allCases {
            let delta = rating.deltas[axis] ?? 0
            if abs(delta) > abs(best?.delta ?? 0) { best = (axis, delta) }
        }
        return best ?? (PalateAxis.allCases[0], 0)
    }

    // HOME-R22, R23, R25
    func winesForPalate(_ model: HomeContentModel) -> [Wine] {
        Array(
            model.catalog
                .filter { !model.ratedWineIDs.contains($0.id) }
                .sorted { Similarity.between($0.profile, model.palateMap) > Similarity.between($1.profile, model.palateMap) }
                .prefix(Self.winesForPalateCount)
        )
    }
}
