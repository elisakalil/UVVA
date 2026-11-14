#if os(iOS)
import Core
import DesignSystem
import SwiftUI

/// The parts of the wine on paper, the same in the new note and in a saved note of the Cellar. Each part reads
/// only; the new note adds its own controls through the optional actions.
public enum NotePaper {
    /// Between two sections of the paper.
    public static let sectionSpacing: CGFloat = 48
    public static let ink = UVVAColor.mossDeep
}

/// The name in drawn capitals, smaller the longer it is, and the producer under it.
public struct NotePaperTitle: View {
    var title: String
    var producer: String

    public init(title: String, producer: String) {
        self.title = title
        self.producer = producer
    }

    public var body: some View {
        let size: CGFloat = title.count >= 23 ? 24 : title.count >= 15 ? 29 : 36
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(UVVAFont.redGrapes(size))
                .lineSpacing(-size * 0.1)
                .accessibilityAddTraits(.isHeader)
            if !producer.isEmpty {
                Text(producer.uppercased())
                    .font(UVVAFont.sans(8.5, .medium))
                    .tracking(2.2)
                    .foregroundStyle(NotePaper.ink.opacity(0.6))
            }
        }
    }
}

/// "72% match with your map".
public struct NotePaperMatch: View {
    var match: Int?
    /// "High in body, like your map." and "More oak than you usually drink." (HOME-R10b), as on the wine sheet.
    var shared: String?
    var apart: String?
    var resources: NotePaperResources

    public init(match: Int?, shared: String? = nil, apart: String? = nil,
                resources: NotePaperResources = NotePaperResources()) {
        self.match = match
        self.shared = shared
        self.apart = apart
        self.resources = resources
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let match {
                    Text("\(match)%")
                        .font(UVVAFont.sans(44, .ultraLight))
                        .tracking(-1.3)
                }
                Text(match == nil ? resources.noMapText : resources.matchText)
                    .font(UVVAFont.sans(12.5))
                    .foregroundStyle(NotePaper.ink.opacity(0.78))
            }
            .accessibilityElement(children: .combine)
            if shared != nil || apart != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if let shared { line(shared) }
                    if let apart { line(apart) }
                }
                .padding(.top, 16)
            }
        }
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(UVVAFont.sans(13))
            .lineSpacing(4)
            .foregroundStyle(NotePaper.ink.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// The wine's certificate (CELLAR-R30). Closed, the seal and two lines: the "Top X%" or the appellation's level, and
/// what it rests on. "More" opens one section per criterion, each with its small-capitals title.
struct WineCertificateCard: View {
    @Environment(\.displayScale) private var displayScale
    @State private var isOpen = false
    var certificate: WineCertificateUIModel
    private let ink = Color(hex: 0x494038)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    UVVAIllustration.certificateSeal
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(certificate.headline).font(UVVAFont.sans(15, .medium))
                        if let subline = certificate.subline {
                            Text(subline).font(UVVAFont.sans(12)).opacity(0.7)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if !certificate.sections.isEmpty {
                        Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.6)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(certificate.sections.isEmpty)
            .accessibilityHint(Text(isOpen ? certificate.lessText : certificate.moreText))

            if isOpen {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(certificate.sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title.uppercased())
                                .font(UVVAFont.sans(8.5, .medium))
                                .tracking(2.2)
                                .opacity(0.6)
                                .accessibilityAddTraits(.isHeader)
                            if let value = section.value {
                                Text(value).font(UVVAFont.sans(13, .medium))
                            }
                            ForEach(section.lines, id: \.self) { line in
                                Text(line).font(UVVAFont.sans(12)).opacity(0.78)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.top, 18)
                .padding(.leading, 56)
                .transition(.opacity)
            }
        }
        .foregroundStyle(ink)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(ink, lineWidth: 1 / displayScale)
                .allowsHitTesting(false)
        }
    }
}

/// Origin, Producer, Style and Vintage in two columns, followed by How to serve.
public struct NotePaperFacts: View {
    var content: NotePaperContent
    var resources: NotePaperResources

    public init(content: NotePaperContent, resources: NotePaperResources = NotePaperResources()) {
        self.content = content
        self.resources = resources
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24, alignment: .topLeading), count: 2),
                      alignment: .leading, spacing: 18) {
                detail(resources.originText, value: content.origin)
                detail(resources.producerText, value: content.producer)
                ForEach(content.facts) { fact in
                    detail(fact.label, value: fact.value)
                }
            }
            detail(resources.serveText, value: content.serving)
        }
    }

    private func detail(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            NoteEyebrow(text: label)
            Text(value.isEmpty ? "—" : value)
                .font(UVVAFont.sans(13))
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Find the wine": a search for it in the browser, in a sheet (HOME-R09a).
public struct NotePaperFindWine: View {
    var title: String
    var url: URL?

    @State private var isFinding = false

    public init(title: String, url: URL?) {
        self.title = title
        self.url = url
    }

    public var body: some View {
        WineSheetButton(title: title, style: .outlined) { isFinding = true }
            .disabled(url == nil)
            .sheet(isPresented: $isFinding) {
                if let url { SafariSheet(url: url).ignoresSafeArea() }
            }
    }
}

/// A section of chips: grapes, tasting notes or pairings. With `onAdd`, a last chip adds to it.
public struct NotePaperChips: View {
    var label: String
    var chips: [String]
    var addLabel: String?
    var onAdd: (() -> Void)?

    public init(label: String, chips: [String], addLabel: String? = nil, onAdd: (() -> Void)? = nil) {
        self.label = label
        self.chips = chips
        self.addLabel = addLabel
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NoteEyebrow(text: label)
            if chips.isEmpty && onAdd == nil {
                Text("—").font(UVVAFont.sans(13))
            } else {
                FlowLayout {
                    ForEach(chips.indices, id: \.self) { index in
                        Chip(text: chips[index], surface: .paper)
                    }
                    if let onAdd {
                        Chip(text: addLabel ?? label, surface: .paper, icon: "plus", action: onAdd)
                    }
                }
            }
        }
    }
}

/// The intensity of each axis, one line each. With `onPick` the lines are set by a tap or a slide; with `onInfo`,
/// an ⓘ beside the title explains them.
public struct NotePaperIntensity: View {
    var title: String
    var profile: PalateMap
    var infoLabel: String?
    var onInfo: (() -> Void)?
    var onPick: ((Double, PalateAxis) -> Void)?

    public init(title: String, profile: PalateMap, infoLabel: String? = nil, onInfo: (() -> Void)? = nil,
                onPick: ((Double, PalateAxis) -> Void)? = nil) {
        self.title = title
        self.profile = profile
        self.infoLabel = infoLabel
        self.onInfo = onInfo
        self.onPick = onPick
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                NoteEyebrow(text: title)
                if let onInfo {
                    Button(action: onInfo) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(NotePaper.ink.opacity(0.62))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(infoLabel ?? title)
                }
            }
            .frame(minHeight: 16)
            .padding(.vertical, onInfo == nil ? 0 : -14)
            NoteIntensityView(profile: profile, onPick: onPick)
                .padding(.top, 8)
        }
    }
}

/// "Your note", as written.
public struct NotePaperNote: View {
    var label: String
    var text: String

    public init(label: String, text: String) {
        self.label = label
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            NoteEyebrow(text: label)
            Text(text)
                .font(UVVAFont.sans(15))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The map of the wine, then the wine against the user's map.
public struct NotePaperMaps: View {
    var profile: PalateMap
    var palate: PalateMap?
    var resources: NotePaperResources

    public init(profile: PalateMap, palate: PalateMap?, resources: NotePaperResources = NotePaperResources()) {
        self.profile = profile
        self.palate = palate
        self.resources = resources
    }

    public var body: some View {
        WineMapCarousel(copy: .init(wineTitle: resources.wineMapText, comparisonTitle: resources.comparisonText,
                                    wineLegend: resources.wineText, palateLegend: resources.palateText,
                                    overlapLegend: resources.overlapText),
                        labels: PalateAxis.allCases.map(\.label), wine: profile.chartValues,
                        palate: palate?.chartValues, tint: NotePaper.ink)
    }
}
#endif
