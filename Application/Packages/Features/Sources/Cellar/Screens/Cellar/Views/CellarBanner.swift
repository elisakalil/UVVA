import DesignSystem
import SwiftUI

/// "Every wine you rate moves your map", on the first visits to a Cellar with wines.
struct CellarBanner: View {
    var resources: CellarResourcesUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(resources.bannerTitleText.uppercased())
                .font(UVVAFont.redGrapes(15))
                .tracking(0.6)
            Text(resources.bannerBodyText)
                .font(UVVAFont.sans(12))
                .lineSpacing(3)
        }
        .foregroundStyle(UVVAColor.mossDeep)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(UVVAColor.creamFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }
}
