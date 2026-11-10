import Core
import Foundation
import Match

/// Builds the Home cards from the model. Pure: no UI, no clock or randomness of its own (SHARED-R04). Sendable, as
/// it reads the whole catalog and is run off the main actor.
struct HomeCardsBuilder: Sendable {
    var calendar: Calendar = .current
    /// Picks an index in 0..<count for the word of the day; injected so tests can fix it (HOME-R19).
    var pickWordIndex: @Sendable (Int) -> Int = { Int.random(in: 0..<$0) }

    func build(from model: HomeContentModel, now: Date) -> [HomeCardModel] {
        var cards: [HomeCardModel] = [header(model)]
        if let wine = topMatch(model) { cards.append(.topMatch(wine)) }
        cards.append(.friends(friendsCardState(model.friends, map: model.palateMap)))
        if let course = continueLesson(model.courses) { cards.append(.continueLesson(course)) }
        if let changed = axisChanged(model.lastRating) { cards.append(.changedMapCard(axis: changed.axis, delta: changed.delta)) }
        let lessons = dailyLessons(model, now: now)
        if !lessons.isEmpty { cards.append(.learnShortcuts(lessons)) }
        if !model.glossary.isEmpty { cards.append(.wordOfTheDay(model.glossary[pickWordIndex(model.glossary.count)])) }
        let wines = winesForPalate(model)
        if !wines.isEmpty { cards.append(.winesForPalate(wines)) }
        cards.append(.chooseYourWine(model.catalog))
        return cards
    }

    // HOME-R02, HOME-R04
    func header(_ model: HomeContentModel) -> HomeCardModel {
        .header(greeting: "Welcome back, \(model.firstName)",
                hasUnread: model.notifications.contains { !$0.isRead })
    }

    // HOME-R06, R07, R08, R10: the top of the match list, the wine with a dish closest to the map. It follows the
    // map and not the day, so it only changes when the map does; wines equally close keep the catalog's order.
    func topMatch(_ model: HomeContentModel) -> Wine? {
        var best: (wine: Wine, similarity: Double)?
        for wine in model.catalog where wine.dish != nil {
            let similarity = Similarity.between(wine.profile, model.palateMap)
            if similarity > (best?.similarity ?? -.infinity) { best = (wine, similarity) }
        }
        return best?.wine
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
    func friendsCardState(_ friends: [Friend], map: PalateMap) -> HomeCardModel.FriendsCardState {
        switch friends.count {
        case 0: .noFriends
        case 1: .hasMatch(name: friends[0].name, compatibility: TableMatch.compatibility(map, friends[0].map))
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
    func winesForPalate(_ model: HomeContentModel) -> [PalateWineSuggestion] {
        let candidates = model.catalog.filter { !model.ratedWineIDs.contains($0.id) }
        return PalateAxis.allCases.compactMap { axis in
            let target = model.palateMap[axis]
            guard let level = PalateWineSuggestion.Level(target) else { return nil }
            let matches = candidates.lazy.filter { level.matches($0.profile[axis], target: target) }
            let wine = matches.min { lhs, rhs in
                let left = abs(lhs.profile[axis] - target)
                let right = abs(rhs.profile[axis] - target)
                if left != right { return left < right }
                let leftSimilarity = Similarity.between(lhs.profile, model.palateMap)
                let rightSimilarity = Similarity.between(rhs.profile, model.palateMap)
                return leftSimilarity == rightSimilarity ? lhs.id < rhs.id : leftSimilarity > rightSimilarity
            }
            return wine.map { PalateWineSuggestion(wine: $0, axis: axis, level: level) }
        }
    }
}
