import Core
import Testing
@testable import Match

struct WineOutlookTests {
    private func map(_ value: Double, except: [PalateAxis: Double] = [:]) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map {
            ($0, WineRuler.value(atPosition: except[$0] ?? value, on: $0))
        }))
    }

    @Test func closeToTheMap_isLikely_withWhatTheyShare() {
        let outlook = WineOutlook(wine: map(4, except: [.body: 8, .fruit: 7]), map: map(4, except: [.body: 7, .fruit: 7]))
        #expect(outlook.lean == .likely)
        #expect(outlook.shared == [.body, .fruit])
    }

    @Test func farFromTheMap_isUnlikely_withWhereItIsApart() {
        let outlook = WineOutlook(wine: map(2, except: [.tannin: 9, .oak: 8]), map: map(6, except: [.tannin: 2]))
        #expect(outlook.lean == .unlikely)
        #expect(outlook.apart == .tannin)
        #expect(outlook.hasMore)
    }

    @Test func inBetween_isMixed() {
        // 3.5 apart in value on one axis: 73%.
        let wine = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, $0 == .oak ? 8.5 : 5) }))
        let palate = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 5.0) }))
        #expect(Similarity.percent(wine, palate) == 73)
        #expect(WineOutlook(wine: wine, map: palate).lean == .mixed)
    }
}
