import Core
import DesignSystem
import SwiftUI

/// The facts of the day's wine: origin, appellation (when it is notable), grapes, notes and serving down the left, each with its one-line
/// insight when the content has one, and the vintage alone on the right, under the card's third axis.
struct WineFacts: View {
    var resources = HomeResourcesUIModel()
    var wine: Wine
    var now = Date()

    private var uiModel: WineFactsUIModel { WineFactsUIModel(wine: wine, now: now, resources: resources) }

    var body: some View {
        let column = VStack(alignment: .leading, spacing: 22) {
            ForEach(uiModel.facts) { cell($0) }
        }
        Group {
            if let vintage = wine.vintage {
                ThirdColumnLayout {
                    column
                    cell(WineFactsUIModel.Fact(label: resources.wineFactsVintageTitle, value: uiModel.vintageLine(vintage)))
                }
            } else {
                column
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cell(_ fact: WineFactsUIModel.Fact) -> some View {
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
