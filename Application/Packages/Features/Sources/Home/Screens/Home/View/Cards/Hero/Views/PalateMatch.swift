import Core
import CoreUI
import DesignSystem
import Match
import SwiftUI

/// How close the day's wine sits to the user's map: the match in percent and two lines on why.
struct PalateMatch: View {
    var resources = HomeResourcesUIModel()
    var wine: PalateMap
    var palate: PalateMap

    private var uiModel: PalateMatchUIModel { PalateMatchUIModel(wine: wine, palate: palate) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(uiModel.percentage)
                    .font(UVVAFont.sans(40, .ultraLight))
                    .tracking(-1.2)
                Text(resources.palateMatchCaption)
                    .font(UVVAFont.sans(12.5, .regular))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(uiModel.shared)
                Text(uiModel.apart)
            }
            .font(UVVAFont.sans(13, .light))
            .lineSpacing(4)
            .foregroundStyle(.white)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
