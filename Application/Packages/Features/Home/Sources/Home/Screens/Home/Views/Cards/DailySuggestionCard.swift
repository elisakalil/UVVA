import Core
import DesignSystem
import SwiftUI

struct DailySuggestionCard: View {
    var wine: Wine
    var palateMap: PalateMap
    var isInCellar = false
    /// "Show less": the Home goes back to the top as the card closes.
    var onShowLess: () -> Void = {}
    @State private var open = false
    @State private var search: URL?

    /// The user's three strongest axes, read on this wine.
    private var axes: [PalateAxis] { Array(palateMap.ranked.prefix(3)) }

    /// Why it was picked: the user's top axes on which this wine is also high.
    private var reason: String? {
        let shared = axes.filter { wine.profile[$0] >= 5 }.prefix(2).map(\.rawValue)
        switch shared.count {
        case 2: return "Your map likes \(shared[0]) and \(shared[1]), and this wine is high on both."
        case 1: return "Your map likes \(shared[0]), and this wine is high on it."
        default: return nil
        }
    }

    var body: some View {
        FrostedCard(radius: UVVARadius.hero, padding: 26) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Picked for your palate")
                    .font(UVVAFont.sans(13, .regular))
                    .foregroundStyle(UVVAColor.cream84)

                (Text(wine.displayName)
                    + Text(wine.vintage.map { "  \($0)" } ?? "").font(UVVAFont.whiteGrape(20)).foregroundColor(UVVAColor.cream.opacity(0.78)))
                    .font(UVVAFont.sans(32))
                    .lineSpacing(-2)
                    .padding(.top, 18)
                Caption(text: wine.origin)
                    .padding(.top, 12)

                Text([reason, wine.note].compactMap { $0 }.joined(separator: " "))
                    .font(UVVAFont.sans(12, .regular))
                    .lineSpacing(6)
                    .lineLimit(open ? nil : 3)
                    .foregroundStyle(UVVAColor.cream84)
                    .padding(.top, 30)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(axes, id: \.self) { axis in
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
                .padding(.top, 26)

                // Built with the card and only folded away while closed, so opening it builds nothing (the pager
                // and the charts were made on the tap) and the card simply grows, its content staying in place.
                VStack(alignment: .leading, spacing: 0) {
                    divider
                    WineFacts(wine: wine).padding(.top, 20)
                    PalateMatch(wine: wine.profile, palate: palateMap).padding(.top, 30)
                    WineMapPager(wine: wine.profile, palate: palateMap).padding(.top, 30)
                    if let dish = wine.dish {
                        divider.padding(.top, 22)
                        PerfectTable(dish: dish, serving: wine.serving).padding(.top, 19)
                    }
                }
                .padding(.top, 26)
                .frame(height: open ? nil : 0, alignment: .top)
                .clipped()
                .opacity(open ? 1 : 0)
                .allowsHitTesting(open)
                .accessibilityHidden(!open)

                VStack(spacing: 10) {
                    PillButton(style: .outline, action: { search = WineSearch.url(for: wine) }) { Text("Find the wine") }
                    if open {
                        cellarButton.transition(.opacity)
                    }
                    toggleButton
                }
                .padding(.top, 26)
            }
        }
        .sheet(item: $search) { url in SafariSheet(url: url).ignoresSafeArea() }
    }

    /// Saving to the Cellar is not wired yet: the button shows but does nothing. A wine already saved says so.
    @ViewBuilder private var cellarButton: some View {
        if isInCellar {
            PillButton(style: .outline, action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .regular))
                    Text("In your cellar")
                }
            }
            .disabled(true)
        } else {
            PillButton(action: {}) { Text("Add to cellar") }
        }
    }

    /// One button open or closed, so it slides down with the card as it opens instead of a new one replacing it
    /// while the old one fades out over the new content. Open, it steps back to a plain line so the recipe ends the card.
    private var toggleButton: some View {
        Button {
            withAnimation(.smooth) { open.toggle() }
            if !open { onShowLess() }
        } label: {
            toggleLabel
                .font(UVVAFont.sans(14, .regular))
                .foregroundStyle(open ? UVVAColor.cream : UVVAColor.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background { Capsule().fill(UVVAColor.creamFill).opacity(open ? 0 : 1) }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle().fill(UVVAColor.cream.opacity(0.22)).frame(height: 0.5)
    }

    private var toggleLabel: some View {
        HStack(spacing: 10) {
            Text(open ? "Show less" : "See the wine & the dish")
                .font(UVVAFont.sans(14, .regular))
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .regular))
                .rotationEffect(.degrees(open ? 180 : 0))
        }
    }
}
