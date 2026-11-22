import Foundation
import Testing
@testable import Core

struct TasteHistoryTests {
    private func entry(_ id: String, grapes: [String] = [], region: String? = nil,
                       verdict: Verdict?) -> CellarEntry {
        CellarEntry(id: id, name: id, region: region, grapes: grapes, status: verdict == nil ? .wantToTry : .tasted,
                    verdict: verdict, createdAt: Date(timeIntervalSince1970: 0))
    }

    private func history(_ grape: String, _ verdicts: [Verdict?]) -> TasteHistory {
        TasteHistory(entries: verdicts.enumerated().map { entry("w\($0.offset)", grapes: [grape], verdict: $0.element) })
    }

    @Test func moreThanTwoYes_likes() {
        #expect(history("Syrah", [.yes, .yes, .yes]).grape("Syrah") == .likes)
        #expect(history("Syrah", [.yes, .yes, .yes, .no]).grape("Syrah") == .likes)
    }

    @Test func twoYes_isNotEnough() {
        #expect(history("Syrah", [.yes, .yes]).grape("Syrah") == .knowsLittle)
    }

    @Test func moreThanTwoNo_dislikes() {
        #expect(history("Syrah", [.no, .no, .no, .maybe]).grape("Syrah") == .dislikes)
    }

    @Test func asManyYesAsNo_knowsLittle() {
        #expect(history("Syrah", [.yes, .yes, .yes, .no, .no, .no]).grape("Syrah") == .knowsLittle)
    }

    @Test func neverRated_isUnknown_wantToTryDoesNotCount() {
        #expect(history("Syrah", [nil, nil, nil]).grape("Syrah") == .unknown)
        #expect(history("Syrah", [.yes]).grape("Merlot") == .unknown)
    }

    @Test func namesAreComparedFolded() {
        #expect(history("Touriga-Nacional", [.yes, .yes, .yes]).grape("touriga nacional") == .likes)
        let regions = TasteHistory(entries: (0..<3).map { entry("w\($0)", region: "Dão", verdict: .no) })
        #expect(regions.region("DAO") == .dislikes)
        #expect(regions.region("Douro") == .unknown)
    }

    @Test func blend_tellsTheGrapeTheUserIsSureOf() {
        let history = TasteHistory(entries: [
            entry("a", grapes: ["Syrah"], verdict: .maybe),
            entry("b", grapes: ["Alicante Bouschet"], verdict: .yes),
            entry("c", grapes: ["Alicante Bouschet"], verdict: .yes),
            entry("d", grapes: ["Alicante Bouschet"], verdict: .yes)
        ])
        #expect(history.telling(["Syrah", "Alicante Bouschet"])?.grape == "Alicante Bouschet")
        #expect(history.telling(["Merlot", "Syrah"])?.grape == "Syrah")
        #expect(history.telling(["Merlot", "Petit Verdot"])?.grape == "Merlot")
        #expect(history.telling([]) == nil)
    }
}
