import Core
import Foundation
import Match
import Testing
@testable import Home

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

    @Test func HOME_R01_withoutLessonCatalog_omitsSuggestions() {
        let kinds = builder.build(from: .full, now: now).map(\.kind)
        #expect(kinds == ["header", "topMatch", "friends", "continueLesson", "changedMapCard",
                          "wordOfTheDay", "winesForPalate", "chooseYourWine"])
    }

    @Test func HOME_R01_noLessonNoRating_hidesThoseCardsAndKeepsOrder() {
        var model = HomeContentModel.full
        model.courses = []
        model.lastRating = nil
        let kinds = builder.build(from: model, now: now).map(\.kind)
        #expect(kinds == ["header", "topMatch", "friends",
                          "wordOfTheDay", "winesForPalate", "chooseYourWine"])
    }

    // MARK: HOME-R04 · Sino

    @Test func HOME_R04_unreadNotification_showsDot() {
        var model = HomeContentModel.full
        model.notifications = [.init(id: "1", text: "a", isRead: true), .init(id: "2", text: "b", isRead: false)]
        #expect(builder.header(model) == .header(greeting: "Welcome back, Elisa", hasUnread: true))
    }

    @Test func HOME_R04_allRead_hidesDot() {
        var model = HomeContentModel.full
        model.notifications = [.init(id: "1", text: "a", isRead: true)]
        #expect(builder.header(model) == .header(greeting: "Welcome back, Elisa", hasUnread: false))
    }

    // MARK: HOME-R07 · Topo do match

    @Test func HOME_R07_showsTheWineWithADishClosestToTheMap() throws {
        let model = HomeContentModel.full
        let paired = model.catalog.filter { $0.dish != nil }
        let closest = try #require(paired.max { Similarity.between($0.profile, model.palateMap) < Similarity.between($1.profile, model.palateMap) })
        #expect(builder.topMatch(model) == closest)
    }

    @Test func HOME_R07_anotherDay_sameWine() {
        func top(at date: Date) -> HomeCardModel? { builder.build(from: .full, now: date).first { $0.kind == "topMatch" } }
        #expect(top(at: now) != nil)
        for days in 1...30 {
            #expect(top(at: now.addingTimeInterval(Double(days) * 60 * 60 * 24)) == top(at: now))
        }
    }

    @Test func HOME_R07_theMapMoves_theTopFollows() throws {
        var model = HomeContentModel.full
        let before = try #require(builder.topMatch(model))
        let other = try #require(model.catalog.first { $0.dish != nil && $0.id != before.id })
        model.palateMap = other.profile
        #expect(builder.topMatch(model) == other)
    }

    @Test func HOME_R07_equallyClose_keepsTheCatalogOrder() throws {
        var model = HomeContentModel.full
        let first = try #require(model.catalog.first { $0.dish != nil })
        var twin = first
        twin.id = "twin"
        model.palateMap = first.profile
        model.catalog = [first, twin]
        #expect(builder.topMatch(model) == first)
        model.catalog = [twin, first]
        #expect(builder.topMatch(model) == twin)
    }

    @Test func HOME_R10_noWineWithDish_hidesSuggestion() {
        var model = HomeContentModel.full
        model.catalog = model.catalog.map { var w = $0; w.dish = nil; return w }
        #expect(builder.topMatch(model) == nil)
    }

    @Test func HOME_R10_farFromTheMap_stillShowsTheTop() {
        var model = HomeContentModel.full
        model.palateMap = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 0.0) }))
        model.catalog = model.catalog.map { var w = $0; w.profile = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 9.0) })); return w }
        #expect(builder.topMatch(model) != nil)
    }

    // MARK: HOME-R11 · Amigos

    @Test func HOME_R11_noFriends_showsInvite() {
        #expect(builder.friendsCardState([], map: PalateMap([:])) == .noFriends)
    }

    @Test func HOME_R11_oneFriend_showsMatch() {
        let map = PalateMap([.acidity: 7, .fruit: 6])
        let marina = Friend(id: "m", name: "Marina", map: map, addedAt: .now)
        #expect(builder.friendsCardState([marina], map: map) == .hasMatch(name: "Marina", compatibility: 100))
    }

    @Test func HOME_R11_twoFriends_showsSetTable() {
        let friends = [Friend(id: "a", name: "A", map: PalateMap([:]), addedAt: .now),
                       Friend(id: "b", name: "B", map: PalateMap([:]), addedAt: .now)]
        #expect(builder.friendsCardState(friends, map: PalateMap([:])) == .hasFriends(count: 2))
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
        let rating = Rating(wineKey: "w", verdict: .yes, date: now, deltas: [.tannin: 0.3, .acidity: 0.1])
        #expect(builder.axisChanged(rating)?.axis == .tannin)
    }

    @Test func HOME_R16_tie_followsCanonicalOrder() {
        let rating = Rating(wineKey: "w", verdict: .yes, date: now, deltas: [.fruit: 0.2, .body: -0.2])
        #expect(builder.axisChanged(rating)?.axis == .body)
    }

    // MARK: HOME-R19, R21 · Palavra do dia

    @Test func HOME_R21_emptyGlossary_hidesCard() {
        var model = HomeContentModel.full
        model.glossary = []
        #expect(!builder.build(from: model, now: now).map(\.kind).contains("wordOfTheDay"))
    }

    // MARK: HOME-R22, R23, R25 · Vinhos para o seu paladar

    @Test func HOME_R22_matchesEachExtremeAxis_includingBoundaryScores() {
        var model = HomeContentModel.full
        let scores = Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 5.0) })
        model.palateMap = PalateMap(scores.merging([.floral: 7, .tannin: 4, .oak: 3]) { _, score in score })
        model.catalog = [
            Wine(id: "boundary", name: "Boundary", origin: "", profile: PalateMap([.floral: 7, .tannin: 4, .oak: 4])),
            Wine(id: "near", name: "Near", origin: "", profile: PalateMap([.floral: 8, .tannin: 3, .oak: 5])),
            Wine(id: "neutral", name: "Neutral", origin: "", profile: PalateMap([.floral: 6.9, .tannin: 4.1, .oak: 4.1]))
        ]

        let suggestions = builder.winesForPalate(model)
        #expect(suggestions.map(\.axis) == [.floral, .tannin])
        #expect(suggestions.map(\.level) == [.high, .low])
        #expect(suggestions.map(\.wine.id) == ["boundary", "boundary"])
    }

    @Test func HOME_R23_wineInTheCellar_leavesAndNextEnters() throws {
        var model = HomeContentModel.full
        let before = try #require(builder.winesForPalate(model).first { $0.axis == .acidity })
        model.cellarWineKeys.insert(before.wine.id)
        let after = builder.winesForPalate(model)
        #expect(after.allSatisfy { $0.wine.id != before.wine.id })
        #expect(after.contains { $0.axis == .acidity })
    }

    @Test func HOME_R23_ratedWine_notInTheCellar_stays() throws {
        var model = HomeContentModel.full
        let before = builder.winesForPalate(model)
        model.ratedVerdicts[try #require(before.first).wine.id] = .no
        #expect(builder.winesForPalate(model) == before)
    }

    @Test func HOME_R25_noExtremeAxes_hidesCard() {
        var model = HomeContentModel.full
        model.palateMap = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 5) }))
        #expect(!builder.build(from: model, now: now).map(\.kind).contains("winesForPalate"))
    }

    @Test func HOME_R25_everyWineInTheCellar_hidesCard() {
        var model = HomeContentModel.full
        model.cellarWineKeys = Set(model.catalog.map(\.id))
        #expect(!builder.build(from: model, now: now).map(\.kind).contains("winesForPalate"))
    }
}

private extension CourseProgress {
    static func sample(id: String, completed: Int, total: Int, openedDaysAgo: Double) -> CourseProgress {
        CourseProgress(id: id, title: id, totalLessons: total, completedLessons: completed, hasStarted: true,
                       lastOpenedAt: Date(timeIntervalSince1970: 1_793_000_000 - openedDaysAgo * 86_400),
                       current: LessonRef(number: completed + 1, title: "Lesson", step: 1))
    }
}
