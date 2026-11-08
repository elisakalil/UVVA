import DesignSystem
import SwiftUI

struct LearnTracksSheet: View {
    var resources: LearnResourcesUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(resources.learningTracksText.uppercased())
                .font(UVVAFont.redGrapes(16))
                .tracking(0.64)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    track(resources.byRegionText, detail: resources.regionTrackDetail)
                    track(resources.byGrapeText, detail: resources.grapeTrackDetail)
                    track(resources.thePathText, detail: resources.pathTrackDetail)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .foregroundStyle(UVVAColor.creamFill)
    }

    private func track(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(UVVAFont.sans(17))
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(UVVAFont.sans(12))
                .opacity(0.84)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
