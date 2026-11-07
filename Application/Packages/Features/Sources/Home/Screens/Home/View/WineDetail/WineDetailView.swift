import Core
import DesignSystem
import SwiftUI

/// The body of the wine sheet (HOME-R28a), ink on parchment: the wine and the axis it stands for, how it sits with
/// the map, its facts, how to serve it and its two maps. The question at the foot is the sheet's own.
struct WineDetailView: View {
    var resources = HomeResourcesUIModel()
    var model: WineDetailUIModel
    /// "Show another ›", for a result of the form.
    var onShowAnother: () -> Void = {}
    /// "Find the wine": a search for it in the browser (HOME-R09a).
    var onFindWine: () -> Void = {}

    private let ink = UVVAColor.mossDeep

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            palate.padding(.top, 40)
            facts.padding(.top, 44)
            Button(action: onFindWine) {
                Text(resources.dailySuggestionCardFindWineTitle)
                    .font(UVVAFont.sans(12.5, .medium))
                    .frame(maxWidth: .infinity, minHeight: 45)
                    .overlay(Capsule().strokeBorder(ink.opacity(0.5), lineWidth: 0.5))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 32)
            if let pairings = model.pairings {
                section(resources.wineDetailPairingsTitle, top: 32, gap: 14) { paragraph(pairings) }
            }
            if let howToServe = model.howToServe {
                section(resources.wineDetailServeTitle, top: 44, gap: 14) { paragraph(howToServe) }
            }
            WineMapPager(resources: resources, wine: model.wine.profile, palate: model.palateMap,
                         tint: ink, showsOverlapLegend: true)
                .id(model.wine.id)
                .padding(.top, 48)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.title.uppercased())
                .font(UVVAFont.redGrapes(model.titleSize))
                .lineSpacing(-model.titleSize * 0.1)
                .accessibilityAddTraits(.isHeader)
            if !model.eyebrow.isEmpty {
                Text(model.eyebrow.uppercased())
                    .font(UVVAFont.sans(8.5, .medium))
                    .tracking(2.2)
                    .foregroundStyle(ink.opacity(0.6))
                    .padding(.top, 12)
            }

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

    private var palate: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(model.percentage)
                    .font(UVVAFont.sans(44, .ultraLight))
                    .tracking(-1.3)
                Text(model.percentageCaption)
                    .font(UVVAFont.sans(12.5, .regular))
                    .foregroundStyle(ink.opacity(0.78))
            }
            VStack(alignment: .leading, spacing: 8) {
                paragraph(model.sharedLine)
                paragraph(model.apartLine)
            }
            .padding(.top, 16)
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(rows, id: \.first?.id) { row in
                HStack(alignment: .top, spacing: 24) {
                    ForEach(row) { fact in
                        VStack(alignment: .leading, spacing: 6) {
                            label(fact.label)
                            Text(fact.value)
                                .font(UVVAFont.sans(12.5, .regular))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    /// Two columns where a fact sits beside the one before it (Origin | Vintage, Style | Grape & notes); the rest
    /// on a line of their own.
    private var rows: [[WineDetailUIModel.Fact]] {
        var rows: [[WineDetailUIModel.Fact]] = []
        for fact in model.facts {
            if fact.besidePrevious, let last = rows.last, last.count == 1 { rows[rows.count - 1].append(fact) } else { rows.append([fact]) }
        }
        return rows
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
