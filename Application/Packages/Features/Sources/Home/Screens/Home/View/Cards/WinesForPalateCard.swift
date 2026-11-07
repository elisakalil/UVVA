import Core
import DesignSystem
import SwiftUI

struct WinesForPalateCard: View {
    var resources = HomeResourcesUIModel()
    var suggestions: [PalateWineSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: resources.winesForPalateCardSectionTitle)
            FrostedCard(radius: UVVARadius.hero, padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.axis) { index, suggestion in
                        if index > 0 {
                            Rectangle().fill(UVVAColor.cream14).frame(height: 0.5).padding(.horizontal, 26)
                        }
                        WineRow(resources: resources, suggestion: suggestion)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
