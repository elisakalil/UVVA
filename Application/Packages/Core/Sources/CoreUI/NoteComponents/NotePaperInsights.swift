#if os(iOS)
import DesignSystem
import SwiftUI

/// "Hide" or "Expand" beside the match: the small caps pill of a friend's "Back", filled with the note's ink and the
/// word cut out of it, so the paper shows through.
public struct NotePaperExpandButton: View {
    @Binding var isExpanded: Bool
    var resources: NotePaperResources

    public init(isExpanded: Binding<Bool>, resources: NotePaperResources = NotePaperResources()) {
        _isExpanded = isExpanded
        self.resources = resources
    }

    private var text: String { isExpanded ? resources.hideInsightsText : resources.expandInsightsText }

    public var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) { isExpanded.toggle() }
        } label: {
            Text(text.uppercased())
                .font(UVVAFont.sans(7.5, .semibold))
                .tracking(1.65)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .foregroundStyle(.black)
                .blendMode(.destinationOut)
                .background(Capsule().fill(NotePaper.ink))
                .compositingGroup()
                // 44 points to tap, as the guidelines ask, without growing the pill.
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityValue(isExpanded ? resources.insightsShownText : resources.insightsHiddenText)
    }
}

/// The grape, the region and the palate lines. Each drawing sits in a thin circle that says how the line reads
/// before a word is read: filled for what the user likes, dashed for what is new to them. A fainter line joins
/// the circles.
public struct NotePaperInsights: View {
    @Environment(\.displayScale) private var displayScale
    var insights: [NoteInsightUIModel]

    @ScaledMetric(relativeTo: .footnote) private var textSize: CGFloat = 13
    @ScaledMetric(relativeTo: .caption2) private var detailSize: CGFloat = 11.5
    @ScaledMetric(relativeTo: .caption2) private var categorySize: CGFloat = 9

    private let circle: CGFloat = 40
    /// Between two lines (2026-11-22: wider, so each reads on its own).
    private let gap: CGFloat = 30

    public init(insights: [NoteInsightUIModel]) {
        self.insights = insights
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                let isLast = index == insights.count - 1
                HStack(alignment: .top, spacing: 16) {
                    badge(insight)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.category.uppercased())
                            .font(UVVAFont.sans(categorySize, .regular))
                            .tracking(2.4)
                            .foregroundStyle(NotePaper.ink.opacity(0.72))
                        Text(markdown(insight.text))
                            .font(UVVAFont.sans(textSize))
                            .lineSpacing(3)
                            .foregroundStyle(NotePaper.ink)
                        if let detail = insight.detail {
                            Text(detail)
                                .font(UVVAFont.sans(detailSize))
                                .lineSpacing(2)
                                .foregroundStyle(NotePaper.ink.opacity(0.72))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    // Beside the middle of the circle when it is short, from its top when it runs longer.
                    .frame(maxWidth: .infinity, minHeight: circle, alignment: .leading)
                }
                .padding(.bottom, isLast ? 0 : gap)
                // From under this circle down to the next one, fainter than the circles so they lead.
                .background(alignment: .topLeading) {
                    if !isLast {
                        Rectangle()
                            .fill(NotePaper.ink.opacity(0.3))
                            .frame(width: hairline)
                            .padding(.top, circle)
                            .padding(.leading, (circle - hairline) / 2)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hairline: CGFloat { max(1 / displayScale, 0.5) }

    private func markdown(_ text: String) -> AttributedString {
        var attributed = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        for run in attributed.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            attributed[run.range].font = UVVAFont.sans(textSize, .medium)
        }
        return attributed
    }

    /// The circle and its drawing, in ink on the paper, or cut out of an ink disc for what the user likes.
    @ViewBuilder
    private func badge(_ insight: NoteInsightUIModel) -> some View {
        let drawing = icon(insight.icon)
            .foregroundStyle(insight.tone == .liked ? UVVAColor.parchment : NotePaper.ink)
            .frame(width: circle, height: circle)
        switch insight.tone {
        case .liked:
            drawing.background(Circle().fill(NotePaper.ink))
        case .known:
            drawing.overlay(Circle().strokeBorder(NotePaper.ink.opacity(0.6), lineWidth: hairline))
        case .new:
            drawing.overlay(
                Circle().strokeBorder(NotePaper.ink.opacity(0.6),
                                      style: StrokeStyle(lineWidth: max(hairline, 0.75), dash: [2.5, 2.5]))
            )
        }
    }

    @ViewBuilder
    private func icon(_ icon: NoteInsightUIModel.Icon) -> some View {
        switch icon {
        case .grape:
            // The darkest of the engraved bunches.
            UVVAIllustration.grape(3).resizable().scaledToFit().frame(width: 20, height: 25)
        case .region:
            UVVAIllustration.pin.resizable().scaledToFit().frame(width: 17, height: 24)
        case .palate:
            UVVAIllustration.wineglass.resizable().scaledToFit().frame(width: 14, height: 25)
        }
    }
}
#endif
