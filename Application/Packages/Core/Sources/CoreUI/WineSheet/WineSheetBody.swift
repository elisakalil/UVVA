#if os(iOS)
import Core
import DesignSystem
import Match
import SwiftUI

/// The wine sheet's body, ink on parchment (HOME-R28a): the name and producer, how the wine sits with the map, its
/// facts, "Find the wine" (unless the sheet keeps it at its foot), pairings, how to serve it, its axes in dots and its two maps. The Home shows it over its
/// cards; a saved note of the Cellar shows it read only, with its photos and the user's note after the name.
public struct WineSheetBody<HeaderAccessory: View, AfterHeader: View>: View {
    var content: WineSheetContent
    var strings: WineSheetStrings
    /// "Find the wine" in the body; nil when the sheet shows it at its foot instead (the Home's wine sheet).
    var onFindWine: (() -> Void)?
    /// Under the producer: "2 of 5 red wines for your choices · Show another ›" on the Home.
    var headerAccessory: HeaderAccessory
    /// After the name: the photos and "Your note" of a saved note.
    var afterHeader: AfterHeader

    private let ink = UVVAColor.mossDeep

    public init(content: WineSheetContent, strings: WineSheetStrings, onFindWine: (() -> Void)?,
                @ViewBuilder headerAccessory: () -> HeaderAccessory,
                @ViewBuilder afterHeader: () -> AfterHeader) {
        self.content = content
        self.strings = strings
        self.onFindWine = onFindWine
        self.headerAccessory = headerAccessory()
        self.afterHeader = afterHeader()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            afterHeader
            if content.percentage != nil {
                palate.padding(.top, 40)
            }
            facts.padding(.top, 44)
            if let pairings = content.pairings {
                section(strings.pairings, top: 44, gap: 14) { paragraph(pairings) }
            }
            if content.showsServing {
                section(strings.serve, top: 44, gap: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let temperature = content.servingTemperature {
                            Text(temperature).font(UVVAFont.sans(12.5, .regular))
                        }
                        if let howToServe = content.howToServe { paragraph(howToServe) }
                    }
                }
            }
            WineAppellationCard(appellation: content.appellation).padding(.top, 32)
            if let onFindWine {
                WineSheetButton(title: strings.findWine, style: .outlined, action: onFindWine)
                    .padding(.top, 32)
            }
            // The axes in dots over the maps, as in the Hero.
            VStack(alignment: .leading, spacing: 0) {
                ForEach(PalateAxis.allCases, id: \.self) { axis in
                    PalateReadingLine(name: axis.label, level: MapReading.level(content.profile[axis]), isStrong: true)
                }
            }
            .padding(.top, 44)
            WineMapCarousel(copy: .init(wineTitle: strings.wineMap, comparisonTitle: strings.comparison,
                                        wineLegend: strings.wineLegend, palateLegend: strings.palateLegend,
                                        overlapLegend: strings.overlapLegend),
                            labels: PalateAxis.allCases.map(\.label), wine: content.profile.chartValues,
                            palate: content.palate?.chartValues, tint: ink)
                .padding(.top, 44)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content.title.uppercased())
                .font(UVVAFont.redGrapes(content.titleSize))
                .lineSpacing(-content.titleSize * 0.1)
                .accessibilityAddTraits(.isHeader)
            if !content.eyebrow.isEmpty {
                Text(content.eyebrow.uppercased())
                    .font(UVVAFont.sans(8.5, .medium))
                    .tracking(2.2)
                    .foregroundStyle(ink.opacity(0.6))
                    .padding(.top, 12)
            }
            headerAccessory
        }
    }

    private var palate: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let percentage = content.percentage {
                    Text(percentage)
                        .font(UVVAFont.sans(44, .ultraLight))
                        .tracking(-1.3)
                }
                Text(content.percentageCaption)
                    .font(UVVAFont.sans(12.5, .regular))
                    .foregroundStyle(ink.opacity(0.78))
            }
            VStack(alignment: .leading, spacing: 8) {
                if let shared = content.sharedLine { paragraph(shared) }
                if let apart = content.apartLine { paragraph(apart) }
            }
            .padding(.top, 16)
        }
    }

    private var facts: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24, alignment: .topLeading), count: 2),
                  alignment: .leading, spacing: 22) {
            ForEach(content.facts) { fact in
                VStack(alignment: .leading, spacing: 6) {
                    label(fact.label)
                    Text(fact.value.isEmpty ? "—" : fact.value)
                        .font(UVVAFont.sans(12.5, .regular))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func section<Content: View>(_ title: String, top: CGFloat, gap: CGFloat = 18,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: gap) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9, .medium))
                .tracking(3.1)
                .foregroundStyle(ink.opacity(0.62))
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, top)
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8, .medium))
            .tracking(1.9)
            .foregroundStyle(ink.opacity(0.6))
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(UVVAFont.sans(13))
            .lineSpacing(4)
            .foregroundStyle(ink.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
    }
}

public extension WineSheetBody where AfterHeader == EmptyView {
    init(content: WineSheetContent, strings: WineSheetStrings, onFindWine: (() -> Void)?,
         @ViewBuilder headerAccessory: () -> HeaderAccessory) {
        self.init(content: content, strings: strings, onFindWine: onFindWine, headerAccessory: headerAccessory,
                  afterHeader: { EmptyView() })
    }
}

public extension WineSheetBody where HeaderAccessory == EmptyView {
    init(content: WineSheetContent, strings: WineSheetStrings, onFindWine: (() -> Void)?,
         @ViewBuilder afterHeader: () -> AfterHeader) {
        self.init(content: content, strings: strings, onFindWine: onFindWine, headerAccessory: { EmptyView() },
                  afterHeader: afterHeader)
    }
}
#endif
