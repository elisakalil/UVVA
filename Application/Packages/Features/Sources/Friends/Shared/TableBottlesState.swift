import DesignSystem
import SwiftUI

/// The bottles once they are there; until then, a line that says they are being read, or that none fits.
struct TableBottlesState<Content: View>: View {
    var resources: TableResourcesUIModel
    var bottles: [TableBottleUIModel]?
    @ViewBuilder var content: ([TableBottleUIModel]) -> Content

    var body: some View {
        if let bottles {
            if bottles.isEmpty {
                Text(resources.noBottlesText).font(UVVAFont.sans(12.5)).opacity(0.75).padding(.vertical, 16)
            } else {
                content(bottles)
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
