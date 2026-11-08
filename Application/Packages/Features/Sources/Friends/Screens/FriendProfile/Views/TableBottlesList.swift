import DesignSystem
import SwiftUI

/// The three bottles, or what stands in for them while they are worked out.
struct TableBottlesList: View {
    var resources: TableResourcesUIModel
    var bottles: [TableBottleUIModel]?
    var style: TableBottleRow.Style

    var body: some View {
        if let bottles {
            if bottles.isEmpty {
                Text(resources.noBottlesText).font(UVVAFont.sans(12.5)).opacity(0.75).padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(bottles) { bottle in
                        TableBottleRow(bottle: bottle, style: style)
                        if bottle.id != bottles.last?.id { FriendsRule() }
                    }
                }
            }
        } else {
            HStack(spacing: 10) {
                ProgressView().tint(UVVAColor.creamFill)
                Text(resources.buildingText).font(UVVAFont.sans(12.5)).opacity(0.75)
            }
            .padding(.vertical, 16)
        }
    }
}
