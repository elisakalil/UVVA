import Foundation
import Testing
@testable import UVVA

@MainActor
struct HomeCardsBuilderTests {
    let now = Date(timeIntervalSince1970: 1_793_000_000)
    var builder: HomeCardsBuilder {
        var b = HomeCardsBuilder()
        b.calendar = Calendar(identifier: .gregorian)
        b.pickWordIndex = { _ in 0 }
        return b
    }

    // MARK: HOME-R01 · Ordem fixa

    @Test func HOME_R01_fullState_showsNineCardsInOrder() {
        let kinds = builder.build(from: .full, now: now).map(\.kind)
        #expect(kinds == ["header", "dailySuggestion", "friends", "continueLesson", "changedMapCard",
                          "learnShortcuts", "wordOfTheDay", "winesForPalate", "chooseYourWine"])
    }

    @Test func HOME_R01_noLessonNoRating_hidesThoseCardsAndKeepsOrder() {
        var state = HomeState.full
        state.courses = []
        state.lastRating = nil
        let kinds = builder.build(from: state, now: now).map(\.kind)
        #expect(kinds == ["header", "dailySuggestion", "friends", "learnShortcuts",
                          "wordOfTheDay", "winesForPalate", "chooseYourWine"])
    }

    // MARK: HOME-R04 · Sino

    @Test func HOME_R04_unreadNotification_showsDot() {
        var state = HomeState.full
        state.notifications = [.init(id: "1", text: "a", isRead: true), .init(id: "2", text: "b", isRead: false)]
        #expect(builder.header(state) == .header(greeting: "Welcome back, Elisa", hasUnread: true))
    }

    @Test func HOME_R04_allRead_hidesDot() {
        var state = HomeState.full
        state.notifications = [.init(id: "1", text: "a", isRead: true)]
        #expect(builder.header(state) == .header(greeting: "Welcome back, Elisa", hasUnread: false))
    }

    // MARK: HOME-R07 · Troca diária

    @Test func HOME_R07_sameDay_sameSuggestion() {
        let morning = builder.dailySuggestion(.full, now: now)
        let evening = builder.dailySuggestion(.full, now: now.addingTimeInterval(60 * 60 * 6))
        #expect(morning == evening)
    }

    @Test func HOME_R07_nextDay_newSuggestion() {
        let today = builder.dailySuggestion(.full, now: now)
        let tomorrow = builder.dailySuggestion(.full, now: now.addingTimeInterval(60 * 60 * 24))
        #expect(today != tomorrow)
    }

    @Test func HOME_R10_noWineWithDish_hidesSuggestion() {
        var state = HomeState.full
        state.catalog = state.catalog.map { var w = $0; w.dish = nil; return w }
        #expect(builder.dailySuggestion(state, now: now) == nil)
    }

    // MARK: HOME-R11 · Amigos

    @Test func HOME_R11_noFriends_showsInvite() {
        #expect(builder.friendsVariant([]) == .invite)
    }

    @Test func HOME_R11_oneFriend_showsMatch() {
        let marina = Friend(id: "m", name: "Marina", compatibility: 82)
        #expect(builder.friendsVariant([marina]) == .match(marina))
    }

    @Test func HOME_R11_twoFriends_showsSetTable() {
        let friends = [Friend(id: "a", name: "A", compatibility: 50), Friend(id: "b", name: "B", compatibility: 60)]
        #expect(builder.friendsVariant(friends) == .setTable(count: 2))
    }

    // MARK: HOME-R12, R13 · Continuar lição

    @Test func HOME_R12_halfDoneModule_showsContinue() {
        let course = CourseProgress.sample(id: "m1", completed: 2, total: 5, openedDaysAgo: 0)
        #expect(builder.continueLesson([course])?.id == "m1")
    }

    @Test func HOME_R12_startedWithNoLessonDone_showsContinue() {
        var course = CourseProgress.sample(id: "m1", completed: 0, total: 5, openedDaysAgo: 0)
        course.current = LessonRef(number: 1, title: "What is wine?", step: 2)
        #expect(builder.continueLesson([course])?.current?.step == 2)
    }

    @Test func HOME_R12_finishedOrNotStarted_hidesContinue() {
        let done = CourseProgress.sample(id: "done", completed: 5, total: 5, openedDaysAgo: 0)
        var fresh = CourseProgress.sample(id: "fresh", completed: 0, total: 5, openedDaysAgo: 0)
        fresh.hasStarted = false
        #expect(builder.continueLesson([done, fresh]) == nil)
    }

    @Test func HOME_R13_twoInProgress_showsLastOpened() {
        let yesterday = CourseProgress.sample(id: "a", completed: 1, total: 5, openedDaysAgo: 1)
        let today = CourseProgress.sample(id: "b", completed: 1, total: 5, openedDaysAgo: 0)
        #expect(builder.continueLesson([yesterday, today])?.id == "b")
    }

    // MARK: HOME-R15, R16 · O eixo que mudou

    @Test func HOME_R15_noRating_hidesCard() {
        #expect(builder.axisChanged(nil) == nil)
    }

    @Test func HOME_R16_showsAxisThatMovedMost() {
        let rating = Rating(wineID: "w", verdict: .yes, date: now, deltas: [.tannin: 0.3, .acidity: 0.1])
        #expect(builder.axisChanged(rating)?.axis == .tannin)
    }

    @Test func HOME_R16_tie_followsCanonicalOrder() {
        let rating = Rating(wineID: "w", verdict: .yes, date: now, deltas: [.fruit: 0.2, .body: -0.2])
        #expect(builder.axisChanged(rating)?.axis == .body)
    }

    // MARK: HOME-R19, R21 · Palavra do dia

    @Test func HOME_R21_emptyGlossary_hidesCard() {
        var state = HomeState.full
        state.glossary = []
        #expect(!builder.build(from: state, now: now).map(\.kind).contains("wordOfTheDay"))
    }

    // MARK: HOME-R22, R23, R25 · Vinhos para o seu paladar

    @Test func HOME_R22_showsThreeMostSimilar_descending() {
        let wines = builder.winesForPalate(.full)
        #expect(wines.count == 3)
        let scores = wines.map { Similarity.between($0.profile, HomeState.full.palateMap) }
        #expect(scores == scores.sorted(by: >))
    }

    @Test func HOME_R23_ratedWine_leavesAndNextEnters() {
        var state = HomeState.full
        let before = builder.winesForPalate(state)
        state.ratedWineIDs.insert(before[0].id)
        let after = builder.winesForPalate(state)
        #expect(!after.contains(before[0]))
        #expect(Array(after.prefix(2)) == Array(before.dropFirst()))
    }

    @Test func HOME_R25_noUnratedWines_hidesCard() {
        var state = HomeState.full
        state.ratedWineIDs = Set(state.catalog.map(\.id))
        #expect(!builder.build(from: state, now: now).map(\.kind).contains("winesForPalate"))
    }
}

private extension CourseProgress {
    static func sample(id: String, completed: Int, total: Int, openedDaysAgo: Double) -> CourseProgress {
        CourseProgress(id: id, title: id, totalLessons: total, completedLessons: completed, hasStarted: true,
                       lastOpenedAt: Date(timeIntervalSince1970: 1_793_000_000 - openedDaysAgo * 86_400),
                       current: LessonRef(number: completed + 1, title: "Lesson", step: 1))
    }
}
