import DesignSystem
import SwiftUI

/// The picture that is shared: the name, the map and two lines on the palate (QUIZ-R19).
struct MapShareCard: View {
    var model: QuizShareUIModel
    var format: ShareFormat

    private var isStory: Bool { format == .story }
    private var chartScale: CGFloat { isStory ? 0.62 : 0.42 }

    var body: some View {
        let size = format.cardSize
        ZStack(alignment: .topLeading) {
            UVVAPhoto.background
                .resizable()
                .scaledToFill()
                .frame(width: 390, height: 854)
                .offset(x: -60, y: -30)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .clipped()
            LinearGradient(stops: [.init(color: Color(hex: 0xE9E1CF).opacity(0), location: 0.34),
                                   .init(color: Color(hex: 0x293022).opacity(0.5), location: 0.62),
                                   .init(color: Color(hex: 0x1C2215).opacity(0.94), location: 1)],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                Text(model.heading.uppercased())
                    .font(UVVAFont.sans(6.5))
                    .tracking(1.95)
                Text(model.dominantPhrase.keepingDotsAtLineEnd)
                    .font(UVVAFont.whiteGrape(isStory ? 30 : 24))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 10)

                PalateMapChart(map: model.map, strong: Array(model.top3.prefix(2)), labelSize: 9.5, labelOpacity: 1)
                    .scaleEffect(chartScale, anchor: .topLeading)
                    .frame(width: PalateMapChart.size.width * chartScale,
                           height: PalateMapChart.size.height * chartScale, alignment: .topLeading)
                    .frame(maxWidth: .infinity)
                    .padding(.top, isStory ? 14 : 8)

                Spacer(minLength: 0)
                ShareLine(tag: String(localized: "Loves", bundle: .module), text: model.loves, isFirst: true)
                ShareLine(tag: String(localized: "Never", bundle: .module), text: model.never, isFirst: false)
                    .padding(.bottom, isStory ? 22 : 12)

                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: "uvva.app")
                        .font(UVVAFont.sans(9))
                        .tracking(1.6)
                        .opacity(0.62)
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(localized: "Map yours ·", bundle: .module).uppercased()).font(UVVAFont.sans(8))
                        Text("UVVA").font(UVVAFont.whiteGrape(10))
                        Text("APP").font(UVVAFont.sans(8))
                    }
                    .tracking(1.9)
                    .opacity(0.5)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, isStory ? 40 : 26)
            .padding(.bottom, isStory ? 22 : 18)
        }
        .frame(width: size.width, height: size.height)
        .foregroundStyle(Color(hex: 0xF9F4E8))
        .background(UVVAColor.night)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
