import Core
import DesignSystem
import SwiftUI

/// Origin and vintage at the top, then grapes and notes side by side.
struct WineFacts: View {
    var resources = HomeResourcesUIModel()
    var wine: Wine
    var now = Date()

    private var uiModel: WineFactsUIModel { WineFactsUIModel(wine: wine, now: now, resources: resources) }

    var body: some View {
        let origins = VStack(alignment: .leading, spacing: 22) {
            ForEach(uiModel.originFacts) { cell($0) }
        }
        VStack(alignment: .leading, spacing: 22) {
            if let vintage = wine.vintage {
                ThirdColumnLayout {
                    origins
                    cell(WineFactsUIModel.Fact(label: resources.wineFactsVintageTitle, value: uiModel.vintageLine(vintage)))
                }
            } else if !uiModel.originFacts.isEmpty {
                origins
            }
            if uiModel.grapes != nil || uiModel.notes != nil {
                HStack(alignment: .top, spacing: 16) {
                    if let grapes = uiModel.grapes { cell(grapes) }
                    if let notes = uiModel.notes { cell(notes) }
                }
            }
            if let serving = uiModel.serving { cell(serving) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cell(_ fact: WineFactsUIModel.Fact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fact.label.uppercased())
                .font(UVVAFont.sans(8, .medium))
                .tracking(1.9)
                .foregroundStyle(.white)
            Text(fact.value)
                .font(UVVAFont.sans(12.5, .regular))
                .lineSpacing(2)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let insight = fact.insight {
                Text(insight)
                    .font(UVVAFont.sans(11.5, .regular))
                    .lineSpacing(3)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Gives the origin two thirds of the width and the vintage the last third.
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
