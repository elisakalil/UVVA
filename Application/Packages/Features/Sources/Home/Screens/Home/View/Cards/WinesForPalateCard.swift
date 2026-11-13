import Core
import DesignSystem
import SwiftUI

struct WinesForPalateCard: View {
    var resources = HomeResourcesUIModel()
    var suggestions: [PalateWineSuggestion]
    /// HOME-R10c: the list is being read again on a map that moved.
    var isLoading = false
    var onOpen: (PalateWineSuggestion) -> Void = { _ in }

    var body: some View {
        FrostedCard(radius: UVVARadius.hero, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(resources.winesForPalateCardTitle)
                    .font(UVVAFont.redGrapes(21))
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.leading, 26)
                    .padding(.trailing, 44)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                ForEach(Array(suggestions.enumerated()), id: \.element.axis) { index, suggestion in
                    if index > 0 {
                        Rectangle().fill(Color.white.opacity(0.14)).frame(height: 0.5).padding(.horizontal, 26)
                    }
                    Button { onOpen(suggestion) } label: {
                        WineRow(resources: resources, suggestion: suggestion)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .environment(\.cardIsLoading, isLoading)
    }
}
