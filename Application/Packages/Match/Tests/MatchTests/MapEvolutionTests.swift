import Core
import Foundation
import Testing
@testable import Match

struct MapEvolutionTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Lisbon")!
        return calendar
    }

    private func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    private func change(_ month: Int, _ day: Int, fruit: Double, rating: Bool = true) -> MapChange {
        MapChange(date: date(month, day), cause: rating ? .rating(wineKey: "w", verdict: .yes) : .quiz, values: [.fruit: fruit])
    }

    // MARK: YOU-R10 · Over time

    @Test func YOU_R10_onlyTheQuiz_givesTheFirstMap() {
        let snapshots = MapEvolution.snapshots(history: [change(7, 30, fruit: 5, rating: false)], now: date(9, 15), calendar: calendar)
        #expect(snapshots.map(\.kind) == [.first])
        #expect(snapshots.first?.winesRated == 0)
    }

    @Test func YOU_R10_quizInJuly_eightRatingsInAugust_givesFirstAugustAndToday() {
        var history = [change(7, 30, fruit: 5, rating: false)]
        for day in 1...8 { history.append(change(8, day, fruit: 5 + Double(day) / 10)) }
        let snapshots = MapEvolution.snapshots(history: history, now: date(9, 15), calendar: calendar)
        #expect(snapshots.map(\.kind) == [.first, .endOfMonth, .today])
        #expect(snapshots[1].winesRated == 8)
        #expect(calendar.component(.day, from: snapshots[1].date) == 31)
        #expect(snapshots[2].winesRated == 8)
    }

    @Test func YOU_R10_ratingsThisMonth_onlyCountInToday() {
        let history = [change(7, 30, fruit: 5, rating: false), change(9, 2, fruit: 6)]
        let snapshots = MapEvolution.snapshots(history: history, now: date(9, 15), calendar: calendar)
        #expect(snapshots.map(\.kind) == [.first, .today])
    }

    @Test func YOU_R10_deltas_areTodayMinusTheSnapshot() {
        let deltas = MapEvolution.deltas(from: PalateMap([.fruit: 5]), to: PalateMap([.fruit: 6]))
        #expect(deltas[.fruit] == 1)
        #expect(deltas[.oak] == 0)
    }
}
