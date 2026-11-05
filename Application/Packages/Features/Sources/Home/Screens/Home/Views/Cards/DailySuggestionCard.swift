import Core
import DesignSystem
import Match
import SwiftUI

struct DailySuggestionCard: View {
    var resources = HomeResourcesUIModel()
    var wine: Wine
    var palateMap: PalateMap
    var isInCellar = false
    /// resources.dailySuggestionCardCollapseTitle: the Home goes back to the top, then calls back for the card to close. Both at once, the
    /// content got shorter under a moving scroll, which jumped and then slid the cards back down.
    var onShowLess: (_ then: @escaping () -> Void) -> Void = { $0() }
    @State private var open = false
    @State private var search: URL?

    private var uiModel: DailySuggestionUIModel { DailySuggestionUIModel(wine: wine, palateMap: palateMap) }

    var body: some View {
        FrostedCard(radius: UVVARadius.hero, padding: 26) {
            VStack(alignment: .leading, spacing: 0) {
                Text(resources.dailySuggestionCardPickedTitle)
                    .font(UVVAFont.sans(13, .regular))
                    .foregroundStyle(UVVAColor.cream84)

                Text(wine.name)
                    .font(UVVAFont.sans(32))
                    .lineSpacing(-2)
                    .padding(.top, 22)
                if !wine.producer.isEmpty {
                    Caption(text: wine.producer)
                        .padding(.top, 14)
                }

                if let reason = uiModel.reason {
                    Text(reason)
                        .font(UVVAFont.sans(12, .regular))
                        .lineSpacing(6)
                        .lineLimit(open ? nil : 3)
                        .foregroundStyle(UVVAColor.cream84)
                        .padding(.top, 36)
                }

                HStack(alignment: .top, spacing: 0) {
                    ForEach(uiModel.axes, id: \.self) { axis in
                        VStack(alignment: .leading, spacing: 9) {
                            Text(axis.label.uppercased())
                                .font(UVVAFont.sans(8, .medium))
                                .tracking(2.2)
                                .foregroundStyle(UVVAColor.cream84)
                            IntensityDots(value: wine.profile[axis])
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 36)

                // Built with the card and only folded away while closed, so opening it builds nothing (the pager
                // and the charts were made on the tap) and the card simply grows, its content staying in place.
                VStack(alignment: .leading, spacing: 0) {
                    WineFacts(resources: resources, wine: wine)
                    PalateMatch(resources: resources, wine: wine.profile, palate: palateMap).padding(.top, 44)
                    WineMapPager(resources: resources, wine: wine.profile, palate: palateMap, active: open).padding(.top, 44)
                    if let dish = wine.dish {
                        PerfectTable(resources: resources, dish: dish).padding(.top, 44)
                    }
                }
                .padding(.top, 44)
                .frame(height: open ? nil : 0, alignment: .top)
                .clipped()
                .opacity(open ? 1 : 0)
                .allowsHitTesting(open)
                .accessibilityHidden(!open)

                VStack(spacing: 0) {
                    PillButton(style: .outline, action: { search = WineSearch.url(for: wine) }) { Text(resources.dailySuggestionCardFindWineTitle) }
                    // Folded away with the rest of the open card rather than added and removed, so it never fades
                    // out on its own where it stood while the card closes around it.
                    cellarButton
                        .padding(.top, 10)
                        .frame(height: open ? nil : 0, alignment: .top)
                        .clipped()
                        .opacity(open ? 1 : 0)
                        .allowsHitTesting(open)
                        .accessibilityHidden(!open)
                    toggleButton.padding(.top, 10)
                }
                .padding(.top, 36)
            }
        }
        .sheet(item: $search) { url in SafariSheet(url: url).ignoresSafeArea() }
    }

    /// Saving to the Cellar is not wired yet: the button shows but does nothing. A wine already saved says so.
    @ViewBuilder private var cellarButton: some View {
        if isInCellar {
            PillButton(style: .outline, action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: resources.dailySuggestionCardSavedIcon).font(.system(size: 11, weight: .regular))
                    Text(resources.dailySuggestionCardSavedTitle)
                }
            }
            .disabled(true)
        } else {
            PillButton(action: {}) { Text(resources.dailySuggestionCardAddTitle) }
        }
    }

    /// One button open or closed, so it slides down with the card as it opens instead of a new one replacing it
    /// while the old one fades out over the new content. Open, it steps back to a plain line so the recipe ends the card.
    private var toggleButton: some View {
        Button {
            if open {
                onShowLess { withAnimation(.smooth) { open = false } }
            } else {
                withAnimation(.smooth) { open = true }
            }
        } label: {
            // Both labels are always there and only trade places in opacity: a single label whose text changed was
            // swapped on its own, apart from the button, and slid in from where the button had been.
            ZStack {
                toggleLabel(resources.dailySuggestionCardExpandTitle, chevron: resources.dailySuggestionCardExpandIcon)
                    .foregroundStyle(UVVAColor.ink)
                    .opacity(open ? 0 : 1)
                toggleLabel(resources.dailySuggestionCardCollapseTitle, chevron: resources.dailySuggestionCardCollapseIcon)
                    .foregroundStyle(UVVAColor.cream)
                    .opacity(open ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background { Capsule().fill(UVVAColor.creamFill).opacity(open ? 0 : 1) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggleLabel(_ title: String, chevron: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(UVVAFont.sans(14, .regular))
            Image(systemName: chevron)
                .font(.system(size: 11, weight: .regular))
        }
    }
}
