import Core
import DesignSystem
import SwiftUI

struct WinesForPalateCard: View {
    var resources = HomeResourcesUIModel()
    var suggestions: [PalateWineSuggestion]
    var onOpen: (PalateWineSuggestion) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: resources.winesForPalateCardSectionTitle)
            FrostedCard(radius: UVVARadius.hero, padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.axis) { index, suggestion in
                        if index > 0 {
                            Rectangle().fill(UVVAColor.cream14).frame(height: 0.5).padding(.horizontal, 26)
                        }
                        Button { onOpen(suggestion) } label: {
                            WineRow(resources: resources, suggestion: suggestion)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
