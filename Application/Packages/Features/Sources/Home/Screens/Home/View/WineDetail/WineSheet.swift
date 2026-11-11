import Core
import DesignSystem
import SwiftUI

/// The wine sheet over the Home (HOME-R28a), for a wine of "Wines for your palate" or the results of "Choose your
/// wine". The wine scrolls; the question stays at the foot, over "Add to cellar", which is always there (HOME-R24):
/// "Have you had this wine?" → Yes → the verdict, which moves the map at once and stays marked; Not yet → the
/// question goes. A wine rated before opens with no question. "Add to cellar" leaves the sheet for the Cellar's new
/// note, with what was answered.
struct WineSheet: View {
    var resources = HomeResourcesUIModel()
    var sheet: WineSheetModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    /// The verdict of each wine rated since the Quiz.
    var ratedVerdicts: [String: Verdict] = [:]
    /// The verdict, as soon as it is given, and whether the wine is in the Cellar, where its entry takes it.
    var onRate: (Wine, Verdict, _ isInCellar: Bool) -> Void = { _, _, _ in }
    /// "Add to cellar": the Cellar's new note, with the verdict given, if any; `asksTasting` when the sheet got no
    /// full answer, so the note asks "Have you had this wine?" itself.
    var onAddToCellar: (Wine, Verdict?, _ asksTasting: Bool) -> Void = { _, _, _ in }

    @State private var resultIndex = 0
    /// Nil until an answer is given: the question starts where the wine stands (`WineSheetStep.first`).
    @State private var answered: WineSheetStep?
    @State private var search: URL?

    private let ink = UVVAColor.mossDeep

    var body: some View {
        Group {
            if let model {
                VStack(spacing: 0) {
                    ScrollView {
                        WineDetailView(resources: resources, model: model, onShowAnother: showAnother,
                                       onFindWine: { search = WineSearch.url(for: model.wine) })
                            .padding(.horizontal, 26)
                            .padding(.top, 42)
                            .padding(.bottom, 44)
                    }
                    .scrollIndicators(.hidden)
                    footer(model.wine, step: currentStep(for: model.wine))
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
        withAnimation(.smooth) {
            resultIndex += 1
            answered = nil
        }
    }

    private func currentStep(for wine: Wine) -> WineSheetStep {
        answered ?? .first(rated: ratedVerdicts[wine.id])
    }

    // MARK: The question at the foot

    private func footer(_ wine: Wine, step: WineSheetStep) -> some View {
        let isInCellar = cellarWineKeys.contains(wine.id)
        return WineTastingActions(
            question: question(wine, step: step),
            primaryTitle: isInCellar ? resources.dailySuggestionCardSavedTitle : resources.dailySuggestionCardAddTitle,
            isPrimaryEnabled: !isInCellar,
            // The Cellar's new note takes it from here, with what was answered (CELLAR-R14a).
            onPrimary: { onAddToCellar(wine, verdict(wine, step: step), step.leavesTastingOpen) })
            .padding(.horizontal, 26)
            .padding(.top, 20)
            .padding(.bottom, 14)
            .background(alignment: .top) {
                // The wine fades out under the question instead of being cut by it.
                LinearGradient(colors: [UVVAColor.parchment.opacity(0), UVVAColor.parchment], startPoint: .top, endPoint: .bottom)
                    .frame(height: 36)
                    .offset(y: -36)
                    .allowsHitTesting(false)
            }
            .background(UVVAColor.parchment)
            .foregroundStyle(ink)
    }

    private func question(_ wine: Wine, step: WineSheetStep) -> WineTastingActions.Question? {
        switch step {
        case .askTasted:
            .init(text: resources.wineDetailTastedQuestion, choices: [
                .init(title: resources.verdictLabel(.yes)) { go(.askVerdict(nil)) },
                .init(title: resources.wineDetailNotYetTitle) { go(.done) }
            ])
        case let .askVerdict(given):
            .init(text: resources.wineDetailVerdictQuestion,
                  choices: [Verdict.yes, .maybe, .no].map { verdict in
                      .init(title: resources.verdictLabel(verdict), isSelected: verdict == given) { rate(wine, verdict) }
                  },
                  // Given once: a second verdict would move the map again.
                  isLocked: given != nil)
        case .done:
            nil
        }
    }

    /// The verdict the new note opens with: the one given here, or the one the wine was rated with before.
    private func verdict(_ wine: Wine, step: WineSheetStep) -> Verdict? {
        if case let .askVerdict(given) = step { given } else { ratedVerdicts[wine.id] }
    }

    private func go(_ next: WineSheetStep) {
        withAnimation(.smooth(duration: 0.25)) { answered = next }
    }

    /// The verdict moves the map now and stays marked. A wine in the Cellar takes it in its entry.
    private func rate(_ wine: Wine, _ verdict: Verdict) {
        onRate(wine, verdict, cellarWineKeys.contains(wine.id))
        go(.askVerdict(verdict))
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
        WineSheet(sheet: .discovery(suggestions: Array(model.catalog.prefix(3)), direction: .familiar),
                  palateMap: model.palateMap)
    }
}
#endif
