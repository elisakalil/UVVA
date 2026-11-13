import Core
import DesignSystem
import SwiftUI

struct WineMapPager: View {
    var resources = HomeResourcesUIModel()
    var wine: PalateMap
    var palate: PalateMap
    var active = true
    var tint: Color = Color.white
    var showsOverlapLegend = false

    var body: some View {
        WineMapCarousel(copy: .init(wineTitle: resources.wineMapPagerWineMapTitle,
                                    comparisonTitle: resources.wineMapPagerComparisonTitle,
                                    wineLegend: resources.wineMapPagerWineLegend,
                                    palateLegend: resources.wineMapPagerPalateLegend,
                                    overlapLegend: showsOverlapLegend ? resources.wineMapPagerOverlapLegend : nil),
                        labels: PalateAxis.allCases.map(\.label), wine: wine.chartValues,
                        palate: palate.chartValues, active: active, tint: tint)
    }
}
