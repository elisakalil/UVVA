import Foundation
import Testing
@testable import Core

struct MapChangeTests {
    @Test func mapChange_roundTripsThroughJSON_withAxesAsKeys() throws {
        let change = MapChange(date: Date(timeIntervalSince1970: 0), cause: .rating(wineKey: "w", verdict: .yes),
                               values: [.acidity: 6.4])
        let data = try JSONEncoder().encode(change)
        #expect(String(decoding: data, as: UTF8.self).contains("\"acidity\":6.4"))
        #expect(try JSONDecoder().decode(MapChange.self, from: data) == change)
    }

    // MARK: SHARED-R10 · The last rating

    @Test func SHARED_R10_lastRating_isTheMoveFromTheEntryBeforeIt() {
        let history = [
            MapChange(date: Date(timeIntervalSince1970: 0), cause: .quiz, values: [.acidity: 5, .oak: 5]),
            MapChange(date: Date(timeIntervalSince1970: 1), cause: .rating(wineKey: "a", verdict: .no), values: [.acidity: 4.5, .oak: 5]),
            MapChange(date: Date(timeIntervalSince1970: 2), cause: .rating(wineKey: "b", verdict: .yes), values: [.acidity: 5.5, .oak: 4.8])
        ]
        let rating = Rating.last(in: history)
        #expect(rating?.wineKey == "b")
        #expect(rating?.verdict == .yes)
        #expect(rating?.deltas[.acidity] == 1)
        #expect(abs((rating?.deltas[.oak] ?? 0) + 0.2) < 0.0001)
    }

    @Test func SHARED_R11_ratedWines_areEveryRatingInTheHistory() {
        let history = [
            MapChange(date: .now, cause: .quiz, values: [:]),
            MapChange(date: .now, cause: .rating(wineKey: "a", verdict: .no), values: [:]),
            MapChange(date: .now, cause: .rating(wineKey: "b", verdict: .yes), values: [:])
        ]
        #expect(Rating.wineKeys(in: history) == ["a", "b"])
    }

    @Test func ratedVerdicts_keepTheLastOneOfEachWine() {
        let history = [
            MapChange(date: .now, cause: .quiz, values: [:]),
            MapChange(date: .now, cause: .rating(wineKey: "a", verdict: .no), values: [:]),
            MapChange(date: .now, cause: .rating(wineKey: "b", verdict: .yes), values: [:]),
            MapChange(date: .now, cause: .rating(wineKey: "a", verdict: .maybe), values: [:])
        ]
        #expect(Rating.verdicts(in: history) == ["a": .maybe, "b": .yes])
    }

    @Test func lastRating_isNil_withOnlyTheQuiz() {
        #expect(Rating.last(in: [MapChange(date: .now, cause: .quiz, values: [:])]) == nil)
    }
}
