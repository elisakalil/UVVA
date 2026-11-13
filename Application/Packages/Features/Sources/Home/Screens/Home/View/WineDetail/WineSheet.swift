import Core
import DesignSystem
import SwiftUI

/// The wine sheet over the Home (HOME-R28a), for a wine of "Wines for your palate" or the results of "Choose your
/// wine". The wine scrolls; "Find the wine" and "Add to cellar" stay at the foot (HOME-R24). The sheet asks nothing:
/// "Add to cellar" leaves it for the Cellar's new note, which asks whether the wine was had and how it was
/// (CELLAR-R14a).
struct WineSheet: View {
    var resources = HomeResourcesUIModel()
    var sheet: WineSheetModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    /// "Add to cellar": the Cellar's new note for the wine shown.
    var onAddToCellar: (Wine) -> Void = { _ in }

    @State private var resultIndex = 0
    @State private var search: URL?

    private let ink = UVVAColor.mossDeep

    var body: some View {
        Group {
            if let model {
                VStack(spacing: 0) {
                    ScrollView {
                        WineDetailView(resources: resources, model: model, onShowAnother: showAnother)
                            .padding(.horizontal, 26)
                            .padding(.top, 42)
                            .padding(.bottom, 44)
                    }
                    .scrollIndicators(.hidden)
                    footer(model.wine)
                }
            } else {
                noMatch
            }
        }
        .background(UVVAColor.parchment.ignoresSafeArea())
        .presentationDetents([.fraction(0.86), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(UVVAColor.parchment)
        .sheet(item: $search) { url in SafariSheet(url: url).ignoresSafeArea() }
    }

    private var model: WineDetailUIModel? {
        switch sheet {
        case let .palate(suggestion):
            return WineDetailUIModel(wine: suggestion.wine, source: .palate(suggestion), palateMap: palateMap, resources: resources)
        case let .discovery(suggestions, direction):
            guard !suggestions.isEmpty else { return nil }
            let index = resultIndex % suggestions.count
            return WineDetailUIModel(wine: suggestions[index], source: .discovery(direction, index: index, count: suggestions.count),
                                     palateMap: palateMap, resources: resources)
        }
    }

    private func showAnother() {
        withAnimation(.smooth) { resultIndex += 1 }
    }

    // MARK: The foot

    /// "Find the wine" (HOME-R09a) over "Add to cellar", which a wine already in the Cellar shows done.
    private func footer(_ wine: Wine) -> some View {
        let isInCellar = cellarWineKeys.contains(wine.id)
        return VStack(spacing: 12) {
            WineSheetButton(title: resources.dailySuggestionCardFindWineTitle, style: .outlined) {
                search = WineSearch.url(for: wine)
            }
            WineTastingActions(
                question: nil,
                primaryTitle: isInCellar ? resources.dailySuggestionCardSavedTitle : resources.dailySuggestionCardAddTitle,
                isPrimaryEnabled: !isInCellar,
                // The Cellar's new note takes it from here (CELLAR-R14a).
                onPrimary: { onAddToCellar(wine) })
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(alignment: .top) {
            // The wine fades out under the buttons instead of being cut by them.
            LinearGradient(colors: [UVVAColor.parchment.opacity(0), UVVAColor.parchment], startPoint: .top, endPoint: .bottom)
                .frame(height: 36)
                .offset(y: -36)
                .allowsHitTesting(false)
        }
        .background(UVVAColor.parchment)
        .foregroundStyle(ink)
    }

    private var noMatch: some View {
        VStack(alignment: .leading, spacing: 20) {
            if case let .discovery(_, direction) = sheet {
                Text((direction == .familiar ? resources.chooseYourWineFamiliarTitle : resources.chooseYourWineSurpriseTitle).uppercased())
                    .font(UVVAFont.sans(9, .medium))
                    .tracking(3.1)
                    .foregroundStyle(ink.opacity(0.62))
            }
            Text(resources.chooseYourWineNoMatch).font(UVVAFont.sans(17))
            Spacer(minLength: 0)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(26)
        .padding(.top, 20)
    }
}

#if DEBUG
#Preview("Wines for your palate") {
    Color.clear.sheet(isPresented: .constant(true)) {
        let model = HomeContentModel.full
        if let suggestion = HomeCardsBuilder().winesForPalate(model).first {
            WineSheet(sheet: .palate(suggestion), palateMap: model.palateMap)
        }
    }
}

#Preview("Choose your wine") {
    Color.clear.sheet(isPresented: .constant(true)) {
        let model = HomeContentModel.full
        WineSheet(sheet: .discovery(suggestions: WineList(Array(model.catalog.prefix(3))), direction: .familiar),
                  palateMap: model.palateMap)
    }
}
#endif
