import Core
import Foundation
import Match

/// Builds the Home cards from the state. Pure: no UI, no clock or randomness of its own (SHARED-R04).
struct HomeCardsBuilder {
    var calendar: Calendar = .current
    /// Picks an index in 0..<count for the word of the day; injected so tests can fix it (HOME-R19).
    var pickWordIndex: (Int) -> Int = { Int.random(in: 0..<$0) }

    static let winesForPalateCount = 3
    static let dailySuggestionPool = 5

    func build(from state: HomeState, now: Date) -> [HomeCard] {
        var cards: [HomeCard] = [header(state)]
        if let wine = dailySuggestion(state, now: now) { cards.append(.dailySuggestion(wine)) }
        cards.append(.friends(friendsVariant(state.friends)))
        if let course = continueLesson(state.courses) { cards.append(.continueLesson(course)) }
        if let changed = axisChanged(state.lastRating) { cards.append(.changedMapCard(axis: changed.axis, delta: changed.delta)) }
        cards.append(.learnShortcuts)
        if !state.glossary.isEmpty { cards.append(.wordOfTheDay(state.glossary[pickWordIndex(state.glossary.count)])) }
        let wines = winesForPalate(state)
        if !wines.isEmpty { cards.append(.winesForPalate(wines)) }
        cards.append(.chooseYourWine)
        return cards
    }

    // HOME-R02, HOME-R04
    func header(_ state: HomeState) -> HomeCard {
        .header(greeting: "Welcome back, \(state.firstName)",
                hasUnread: state.notifications.contains { !$0.isRead })
    }

    // HOME-R06, R07, R08, R10: same wine all day, a new pick each day.
    func dailySuggestion(_ state: HomeState, now: Date) -> Wine? {
        let pool = state.catalog
            .filter { $0.dish != nil }
            .sorted { Similarity.between($0.profile, state.palateMap) > Similarity.between($1.profile, state.palateMap) }
            .prefix(Self.dailySuggestionPool)
        guard !pool.isEmpty else { return nil }
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        return Array(pool)[day % pool.count]
    }

    // HOME-R11
    func friendsVariant(_ friends: [Friend]) -> HomeCard.FriendsVariant {
        switch friends.count {
        case 0: .invite
        case 1: .match(friends[0])
        default: .setTable(count: friends.count)
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
    func winesForPalate(_ state: HomeState) -> [Wine] {
        Array(
            state.catalog
                .filter { !state.ratedWineIDs.contains($0.id) }
                .sorted { Similarity.between($0.profile, state.palateMap) > Similarity.between($1.profile, state.palateMap) }
                .prefix(Self.winesForPalateCount)
        )
    }
}
