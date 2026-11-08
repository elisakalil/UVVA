import DesignSystem
import SwiftUI

/// Wines in the Cellar, none with these filters.
struct CellarNoMatchesView: View {
    var resources: CellarResourcesUIModel
    var onClear: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text(resources.noMatchesText)
                .font(UVVAFont.sans(14))
                .multilineTextAlignment(.center)
                .opacity(0.8)
            Button(action: onClear) {
                Text(resources.clearFiltersText.uppercased())
                    .font(UVVAFont.sans(9.5, .regular))
                    .tracking(2.6)
                    .padding(.bottom, 9)
                    .overlay(alignment: .bottom) { UVVAColor.creamFill.opacity(0.5).frame(height: 0.5) }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.vertical, 56)
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
    }
}
