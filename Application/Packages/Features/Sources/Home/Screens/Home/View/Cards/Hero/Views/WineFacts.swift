import Core
import DesignSystem
import SwiftUI

/// After the match, in this order: producer and vintage side by side, grapes and notes side by side, then origin,
/// appellation and serving, each across the whole width.
struct WineFacts: View {
    var resources = HomeResourcesUIModel()
    var wine: Wine
    var now = Date()

    private var uiModel: WineFactsUIModel { WineFactsUIModel(wine: wine, now: now, resources: resources) }

    var body: some View {
        let facts = uiModel
        VStack(alignment: .leading, spacing: 22) {
            pair(facts.producer, facts.vintage)
            pair(facts.grapes, facts.notes)
            if let origin = facts.origin { cell(origin) }
            if let appellation = facts.appellation { cell(appellation) }
            if let serving = facts.serving { cell(serving) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Two facts in two equal columns; one alone keeps its column, so the rows line up.
    @ViewBuilder private func pair(_ first: WineFactsUIModel.Fact?, _ second: WineFactsUIModel.Fact?) -> some View {
        if first != nil || second != nil {
            HStack(alignment: .top, spacing: 16) {
                column(first)
                column(second)
            }
        }
    }

    @ViewBuilder private func column(_ fact: WineFactsUIModel.Fact?) -> some View {
        if let fact { cell(fact) } else { Color.clear.frame(maxWidth: .infinity, maxHeight: 0) }
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
