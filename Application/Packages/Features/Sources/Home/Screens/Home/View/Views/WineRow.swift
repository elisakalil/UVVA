import Core
import DesignSystem
import SwiftUI

struct WineRow: View {
    var resources = HomeResourcesUIModel()
    var suggestion: PalateWineSuggestion

    var body: some View {
        let wine = suggestion.wine
        let axis = suggestion.axis
        let label = resources.wineRowAxisLabel(axis, level: suggestion.level)

        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(wine.displayName).font(UVVAFont.sans(14.5, .medium))
                Caption(text: label, color: .white)
                    .padding(.top, 10)
            }
            Spacer(minLength: 0)
            Image(systemName: resources.wineRowChevronIcon)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}
