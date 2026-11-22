#if os(iOS)
import Core
import DesignSystem
import Match
import SwiftUI

/// The user's own part of a wine sheet: the match as a number and the grape, region and palate lines. With it,
/// the sheet reads in the order of a note (CELLAR-R26): the certificate, then the wine and you, its axes under the
/// maps, then the facts.
public struct WineSheetPersonal: Equatable {
    public var match: Int?
    public var insights: [NoteInsightUIModel]

    public init(match: Int?, insights: [NoteInsightUIModel]) {
        self.match = match
        self.insights = insights
    }
}

/// The wine sheet's body, ink on parchment (HOME-R28a): the name and producer, how the wine sits with the map, its
/// certificate, its facts, "Find the wine" (unless the sheet keeps it at its foot), pairings, how to serve it, its axes in dots and its two maps. The Home shows it over its
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
    private let sectionSpacing: CGFloat?
    private let standaloneFactLabels: [String]
    /// The Home's sheet: the note's order and its Hide block. Nil keeps the order of a friend's wine, whose match
    /// is with another map.
    private let personal: WineSheetPersonal?

    private let ink = UVVAColor.mossDeep

    public init(content: WineSheetContent, strings: WineSheetStrings, onFindWine: (() -> Void)?,
                sectionSpacing: CGFloat? = nil, standaloneFactLabels: [String] = [],
                personal: WineSheetPersonal? = nil,
                @ViewBuilder headerAccessory: () -> HeaderAccessory,
                @ViewBuilder afterHeader: () -> AfterHeader) {
        self.content = content
        self.strings = strings
        self.onFindWine = onFindWine
        self.headerAccessory = headerAccessory()
        self.afterHeader = afterHeader()
        self.sectionSpacing = sectionSpacing
        self.standaloneFactLabels = standaloneFactLabels
        self.personal = personal
    }

    public var body: some View {
        if let personal { noteOrder(personal) } else { sheetOrder }
    }

    /// As a note: the name, the certificate, the match with the user's lines and the maps under Hide, the axes
    /// under the maps, the facts and "Find the wine".
    private func noteOrder(_ personal: WineSheetPersonal) -> some View {
        VStack(alignment: .leading, spacing: sectionSpacing ?? NotePaper.sectionSpacing) {
            VStack(alignment: .leading, spacing: 0) {
                header
                afterHeader
            }
            if let certificate = content.certificate {
                WineCertificateCard(certificate: certificate)
            }
            NotePaperPersonal(match: personal.match, insights: personal.insights, profile: content.profile,
                              palate: content.palate, shared: content.sharedLine, apart: content.apartLine,
                              remembersChoice: false)
            axes
            VStack(alignment: .leading, spacing: 32) {
                WineSheetFacts(content: content, strings: strings, spacing: sectionSpacing ?? 44,
                               standaloneFactLabels: standaloneFactLabels)
                if let onFindWine {
                    WineSheetButton(title: strings.findWine, style: .outlined, action: onFindWine)
                }
            }
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The axes in dots, as in the Hero.
    private var axes: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PalateAxis.allCases, id: \.self) { axis in
                let level = MapReading.level(content.profile, axis)
                PalateReadingLine(name: axis.label, level: level, word: MapReading.levelWord(level, on: axis),
                                  isStrong: true)
            }
        }
    }

    private var sheetOrder: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            afterHeader
            if content.percentage != nil {
                palate.padding(.top, sectionSpacing ?? 40)
            }
            // After the match and before the facts, as in the new note (CELLAR-R30).
            if let certificate = content.certificate {
                WineCertificateCard(certificate: certificate).padding(.top, sectionSpacing ?? 40)
            }
            WineSheetFacts(content: content, strings: strings, spacing: sectionSpacing ?? 44,
                           standaloneFactLabels: standaloneFactLabels)
                .padding(.top, sectionSpacing ?? 44)
            if let onFindWine {
                WineSheetButton(title: strings.findWine, style: .outlined, action: onFindWine)
                    .padding(.top, 32)
            }
            // The axes in dots over the maps, as in the Hero.
            axes.padding(.top, sectionSpacing ?? 44)
            WineMapCarousel(copy: .init(wineTitle: strings.wineMap, comparisonTitle: strings.comparison,
                                        wineLegend: strings.wineLegend, palateLegend: strings.palateLegend,
                                        overlapLegend: strings.overlapLegend),
                            labels: PalateAxis.allCases.map(\.label), wine: content.profile.chartValues,
                            palate: content.palate?.chartValues, tint: ink)
                .padding(.top, sectionSpacing ?? 44)
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

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(UVVAFont.sans(13))
            .lineSpacing(4)
            .foregroundStyle(ink.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// The wine's facts (HOME-R28a): Origin, Producer, Style and Vintage in two columns, the facts shown on their own
/// (a note's Grapes and Notes), Pairings and How to serve, `spacing` apart.
public struct WineSheetFacts: View {
    var content: WineSheetContent
    var strings: WineSheetStrings
    var spacing: CGFloat
    var standaloneFactLabels: [String]

    private let ink = UVVAColor.mossDeep

    public init(content: WineSheetContent, strings: WineSheetStrings, spacing: CGFloat,
                standaloneFactLabels: [String] = []) {
        self.content = content
        self.strings = strings
        self.spacing = spacing
        self.standaloneFactLabels = standaloneFactLabels
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24, alignment: .topLeading), count: 2),
                      alignment: .leading, spacing: 22) {
                ForEach(content.facts.filter { !standaloneFactLabels.contains($0.label) }) { fact in
                    VStack(alignment: .leading, spacing: 6) {
                        label(fact.label)
                        Text(fact.value.isEmpty ? "—" : fact.value)
                            .font(UVVAFont.sans(12.5, .regular))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            ForEach(content.facts.filter { standaloneFactLabels.contains($0.label) }) { fact in
                section(fact.label) { paragraph(fact.value.isEmpty ? "—" : fact.value) }
            }
            if let pairings = content.pairings {
                section(strings.pairings) { paragraph(pairings) }
            }
            if content.showsServing {
                section(strings.serve) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let temperature = content.servingTemperature {
                            Text(temperature).font(UVVAFont.sans(12.5, .regular))
                        }
                        if let howToServe = content.howToServe { paragraph(howToServe) }
                    }
                }
            }
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9, .medium))
                .tracking(3.1)
                .foregroundStyle(ink.opacity(0.62))
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
         personal: WineSheetPersonal? = nil, @ViewBuilder headerAccessory: () -> HeaderAccessory) {
        self.init(content: content, strings: strings, onFindWine: onFindWine, personal: personal,
                  headerAccessory: headerAccessory, afterHeader: { EmptyView() })
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
