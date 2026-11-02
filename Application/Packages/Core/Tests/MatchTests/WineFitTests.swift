import Core
import Testing
@testable import Match

struct WineFitTests {
    private func map(_ value: Double, except: [PalateAxis: Double] = [:]) -> PalateMap {
        let values = Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) })
        return PalateMap(values.merging(except) { $1 })
    }

    // MARK: HOME-R10a, R10b · Leitura do vinho do dia

    @Test func HOME_R10a_tiedMap_showsWhatTheWineIsHighestOn() {
        let fit = WineFit(wine: map(2, except: [.acidity: 7, .fruit: 8, .spice: 6]), map: map(3))
        #expect(fit.shown == [.fruit, .acidity, .spice])
        #expect(fit.mapHighs.isEmpty)
        #expect(fit.wineHasHigh)
        #expect(fit.shared.isEmpty)
    }

    @Test func HOME_R10a_sharedAxes_areHighOnBoth_tiesByTheWine() {
        let fit = WineFit(wine: map(3, except: [.fruit: 8, .acidity: 7, .oak: 1]), map: map(7, except: [.oak: 2]))
        #expect(fit.shared == [.fruit, .acidity])
    }

    @Test func HOME_R10a_anAxisLowOnTheMap_isNeverShared() {
        let fit = WineFit(wine: map(3, except: [.floral: 8]), map: map(2, except: [.acidity: 7]))
        #expect(fit.shared.isEmpty)
        #expect(fit.mapHighs == [.acidity])
    }

    @Test func HOME_R10a_fiveIsNotHigh() {
        let fit = WineFit(wine: map(5), map: map(5))
        #expect(fit.mapHighs.isEmpty)
        #expect(!fit.wineHasHigh)
    }

    @Test func HOME_R10b_apart_isTheWidestGap_fromCloseUp() {
        #expect(WineFit(wine: map(4, except: [.oak: 8]), map: map(4)).apart == .oak)
        #expect(WineFit(wine: map(4, except: [.oak: 5.5]), map: map(4)).apart == nil)
    }
}
