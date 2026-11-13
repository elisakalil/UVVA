import Core
import CoreUI
import DesignSystem
import SwiftUI

/// The body of the wine sheet (HOME-R28a), ink on parchment: the wine and the axis it stands for, how it sits with
/// the map, its facts, how to serve it, its axes in dots and its two maps. The same body shows a saved note of the
/// Cellar. "Find the wine" and "Add to cellar" are at the sheet's foot.
struct WineDetailView: View {
    var resources = HomeResourcesUIModel()
    var model: WineDetailUIModel
    /// "Show another ›", for a result of the form.
    var onShowAnother: () -> Void = {}

    private let ink = UVVAColor.mossDeep

    var body: some View {
        WineSheetBody(content: content, strings: strings, onFindWine: nil,
                      headerAccessory: { resultCount })
        .id(model.wine.id)
    }

    private var content: WineSheetContent {
        WineSheetContent(title: model.title, eyebrow: model.eyebrow, percentage: model.percentage,
                         percentageCaption: model.percentageCaption, sharedLine: model.sharedLine,
                         apartLine: model.apartLine,
                         facts: model.facts.map { .init(label: $0.label, value: $0.value) },
                         pairings: model.pairings, servingTemperature: model.servingTemperature,
                         howToServe: model.howToServe, profile: model.wine.profile, palate: model.palateMap,
                         appellation: model.wine.appellation)
    }

    private var strings: WineSheetStrings {
        WineSheetStrings(findWine: resources.dailySuggestionCardFindWineTitle, pairings: resources.wineDetailPairingsTitle,
                         serve: resources.wineDetailServeTitle, wineMap: resources.wineMapPagerWineMapTitle,
                         comparison: resources.wineMapPagerComparisonTitle,
                         wineLegend: resources.wineMapPagerWineLegend, palateLegend: resources.wineMapPagerPalateLegend,
                         overlapLegend: resources.wineMapPagerOverlapLegend)
    }

    /// "2 of 5 red wines for your choices" and "Show another ›", under a result of the form.
    @ViewBuilder private var resultCount: some View {
        if let count = model.resultCount {
            HStack(spacing: 12) {
                Text(count)
                    .font(UVVAFont.sans(11))
                    .foregroundStyle(ink.opacity(0.62))
                Spacer(minLength: 0)
                if model.hasAnotherResult {
                    Button(action: onShowAnother) {
                        Text(resources.wineDetailShowAnother)
                            .font(UVVAFont.sans(11, .medium))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
    }
}
