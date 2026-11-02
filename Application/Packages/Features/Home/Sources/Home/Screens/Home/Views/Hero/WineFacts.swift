import Core
import DesignSystem
import SwiftUI

/// The facts of the day's wine: origin, appellation (when it is notable), grapes, notes and serving down the left, each with its one-line
/// insight when the content has one, and the vintage alone on the right, under the card's third axis.
struct WineFacts: View {
    var wine: Wine
    var now = Date()

    private struct Fact: Identifiable {
        var label: String
        var value: String
        var insight: String?
        var id: String { label }
    }

    private var facts: [Fact] {
        var facts: [Fact] = []
        if !wine.originLine.isEmpty {
            // A wine known only by its country shows the country alone: a line on a whole country says little.
            let hasRegion = !(wine.region ?? "").isEmpty
            facts.append(Fact(label: "Origin", value: wine.originLine, insight: hasRegion ? wine.originInsight : nil))
        }
        // A plain origin label (a regional DOC, an IGT) says nothing the origin does not; only a notable one shows.
        if wine.hasNotableAppellation, !wine.classification.isEmpty {
            facts.append(Fact(label: "Appellation", value: wine.classification, insight: wine.appellationInsight))
        }
        if !wine.grapes.isEmpty { facts.append(Fact(label: "Grapes", value: wine.grapes.joined(separator: ", "))) }
        if let note = wine.note, !note.isEmpty { facts.append(Fact(label: "Notes", value: note)) }
        if let serving = wine.serving {
            facts.append(Fact(label: "Serve at", value: "\(serving.lowerBound)–\(serving.upperBound) °C",
                              insight: wine.howToServe))
        }
        return facts
    }

    /// "2023 · 3 years"
    private func vintageLine(_ vintage: Int) -> String {
        let age = Calendar.current.component(.year, from: now) - vintage
        switch age {
        case ..<1: return "\(vintage)"
        case 1: return "\(vintage) · 1 year"
        default: return "\(vintage) · \(age) years"
        }
    }

    var body: some View {
        let column = VStack(alignment: .leading, spacing: 22) {
            ForEach(facts) { cell($0) }
        }
        Group {
            if let vintage = wine.vintage {
                ThirdColumnLayout {
                    column
                    cell(Fact(label: "Vintage", value: vintageLine(vintage)))
                }
            } else {
                column
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cell(_ fact: Fact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fact.label.uppercased())
                .font(UVVAFont.sans(8, .medium))
                .tracking(1.9)
                .foregroundStyle(UVVAColor.cream.opacity(0.7))
            Text(fact.value)
                .font(UVVAFont.sans(12.5, .regular))
                .lineSpacing(2)
                .foregroundStyle(UVVAColor.cream)
                .fixedSize(horizontal: false, vertical: true)
            if let insight = fact.insight {
                Text(insight)
                    .font(UVVAFont.sans(11.5, .regular))
                    .lineSpacing(3)
                    .foregroundStyle(UVVAColor.cream84)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The first view across the first two thirds, the second in the last third: the card's axes sit in three equal
/// columns, so the vintage lines up under the third one.
private struct ThirdColumnLayout: Layout {
    var gutter: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let height = zip(subviews, frames(width: width)).map { $0.sizeThatFits(ProposedViewSize(width: $1.width, height: nil)).height }.max()
        return CGSize(width: width, height: height ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(width: bounds.width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY),
                          proposal: ProposedViewSize(width: frame.width, height: nil))
        }
    }

    private func frames(width: CGFloat) -> [(minX: CGFloat, width: CGFloat)] {
        let third = width / 3
        return [(0, 2 * third - gutter), (2 * third, third)]
    }
}
