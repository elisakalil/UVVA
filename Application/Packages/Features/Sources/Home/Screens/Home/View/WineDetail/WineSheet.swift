import Core
import DesignSystem
import SwiftUI

/// The wine sheet over the Home (HOME-R28a), for a wine of "Wines for your palate" or the results of "Choose your
/// wine". The wine scrolls; the question stays at the foot, one step at a time (HOME-R24):
/// "Have you had this wine?" → Yes → the verdict → "Add it to your cellar?";
/// Not yet → straight to "Add it to your cellar?", the one cellar step of the sheet. The answer there is met with a
/// light line, and then the question fades away, leaving the wine on its own; the sheet stays open.
struct WineSheet: View {
    var resources = HomeResourcesUIModel()
    var sheet: WineSheetModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    /// The verdict, and whether the wine goes to the Cellar as Tasted with it.
    var onRate: (Wine, Verdict, _ keep: Bool) -> Void = { _, _, _ in }
    /// Not tasted yet: saved to the Cellar as Not yet (CELLAR-R13c).
    var onSaveToCellar: (Wine) -> Void = { _ in }

    @State private var resultIndex = 0
    @State private var step = WineSheetStep.askTasted
    @State private var search: URL?
    @State private var fadeOut: Task<Void, Never>?

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
                    if step != .done {
                        footer(model.wine).transition(.opacity)
                    }
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
        fadeOut?.cancel()
        withAnimation(.smooth) {
            resultIndex += 1
            step = .askTasted
        }
    }

    // MARK: The question at the foot

    private func footer(_ wine: Wine) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            switch step {
            case .askTasted:
                question(resources.wineDetailTastedQuestion)
                HStack(spacing: 10) {
                    choice(resources.verdictLabel(.yes)) { go(.askVerdict) }
                    choice(resources.wineDetailNotYetTitle) { go(.askKeep(nil)) }
                }
            case .askVerdict:
                question(resources.wineDetailVerdictQuestion)
                HStack(spacing: 10) {
                    ForEach([Verdict.yes, .maybe, .no], id: \.self) { verdict in
                        choice(resources.verdictLabel(verdict)) { go(.askKeep(verdict)) }
                    }
                }
            case let .askKeep(verdict):
                question(resources.wineDetailKeepQuestion)
                HStack(spacing: 10) {
                    if let verdict {
                        // Tasted: the verdict moves the map either way; Add to cellar keeps it as Tasted too.
                        action(resources.dailySuggestionCardAddTitle, filled: true) {
                            finish(verdict: verdict, kept: true) { onRate(wine, verdict, true) }
                        }
                        action(resources.wineDetailNotNowTitle, filled: false) {
                            finish(verdict: verdict, kept: false) { onRate(wine, verdict, false) }
                        }
                    } else {
                        // Not yet: it goes to the Cellar as Not yet, or nothing happens.
                        if cellarWineKeys.contains(wine.id) {
                            action(resources.dailySuggestionCardSavedTitle, filled: true) {}.disabled(true)
                        } else {
                            action(resources.dailySuggestionCardAddTitle, filled: true) {
                                finish(verdict: nil, kept: true) { onSaveToCellar(wine) }
                            }
                        }
                        action(resources.wineDetailNotNowTitle, filled: false) { finish(verdict: nil, kept: false) {} }
                    }
                }
            case let .feedback(text):
                question(text)
            case .done:
                EmptyView()
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func go(_ next: WineSheetStep) {
        withAnimation(.smooth(duration: 0.25)) { step = next }
    }

    /// The answer is saved, a light line takes the question's place, and after a moment the section fades away.
    private func finish(verdict: Verdict?, kept: Bool, save: () -> Void) {
        save()
        go(.feedback(resources.wineSheetFeedback(verdict: verdict, kept: kept)))
        fadeOut?.cancel()
        fadeOut = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.6)) { step = .done }
        }
    }

    private func question(_ text: String) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(UVVAFont.sans(17))
                .tracking(-0.17)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// An answer to the question: outlined, in the hand-drawn capitals.
    private func choice(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.redGrapes(17))
                .tracking(0.7)
                .frame(maxWidth: .infinity, minHeight: 47)
                .overlay(Capsule().strokeBorder(ink.opacity(0.5), lineWidth: 0.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// What to do with the wine: the first filled in ink, the other outlined.
    private func action(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(UVVAFont.sans(12.5, .medium))
                .foregroundStyle(filled ? UVVAColor.creamFill : ink)
                .frame(maxWidth: .infinity, minHeight: 45)
                .background { if filled { Capsule().fill(ink) } }
                .overlay { if !filled { Capsule().strokeBorder(ink.opacity(0.5), lineWidth: 0.5) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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
