import DesignSystem
import SwiftUI

/// The empty Cellar: a grape bunch and how to add the first bottle (CELLAR-R05).
struct CellarEmptyView: View {
    var resources: CellarResourcesUIModel

    var body: some View {
        VStack(spacing: 0) {
            UVVAIllustration.grape(1)
                .resizable()
                .scaledToFit()
                .frame(width: 64)
                .opacity(0.82)
                .accessibilityHidden(true)
            Text(resources.emptyTitleText.uppercased())
                .font(UVVAFont.redGrapes(22))
                .tracking(0.9)
                .multilineTextAlignment(.center)
                .padding(.top, 34)
            Text(resources.emptyBodyText)
                .font(UVVAFont.sans(13))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .opacity(0.8)
                .frame(maxWidth: 270)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.top, 150)
        .padding(.bottom, 24)
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
    }
}
