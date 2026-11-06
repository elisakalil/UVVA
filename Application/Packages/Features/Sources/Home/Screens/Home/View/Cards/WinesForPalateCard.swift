import Core
import DesignSystem
import SwiftUI

struct WinesForPalateCard: View {
    var resources = HomeResourcesUIModel()
    var wines: [Wine]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: resources.winesForPalateCardSectionTitle)
            FrostedCard(radius: UVVARadius.hero, padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(wines.enumerated()), id: \.element.id) { index, wine in
                        if index > 0 {
                            Rectangle().fill(UVVAColor.cream14).frame(height: 0.5).padding(.horizontal, 26)
                        }
                        WineRow(resources: resources, wine: wine)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
