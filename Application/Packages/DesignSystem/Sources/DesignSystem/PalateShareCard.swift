import SwiftUI

/// The picture of a palate that is shared (QUIZ-R19, YOU-R12): a heading, the dominant phrase,
/// the map and a few tagged lines, over the vineyard.
public struct PalateShareCard: View {
    var heading: String
    var phrase: String
    var chartValues: [Double]
    var chartLabels: [String]
    var strong: Set<Int>
    var lines: [ShareCardLine]
    var format: ShareFormat

    public init(heading: String, phrase: String, chartValues: [Double], chartLabels: [String], strong: Set<Int>,
                lines: [ShareCardLine], format: ShareFormat) {
        self.heading = heading
        self.phrase = phrase
        self.chartValues = chartValues
        self.chartLabels = chartLabels
        self.strong = strong
        self.lines = lines
        self.format = format
    }

    private var isStory: Bool { format == .story }

    public var body: some View {
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
                Text(heading.uppercased())
                    .font(UVVAFont.sans(6.5))
                    .tracking(1.95)
                Text(phrase.keepingDotsAtLineEnd)
                    .font(UVVAFont.whiteGrape(isStory ? 30 : 24))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 10)

                // The map takes whatever room the lines leave.
                chart
                    .padding(.top, isStory ? 14 : 8)

                // Story: the lines kept small under the map. WhatsApp: no lines, the map has the card.
                if isStory {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        ShareLine(tag: line.tag, text: line.text, isFirst: index == 0, compact: true)
                    }
                    .padding(.top, 10)
                }
                Color.clear.frame(height: isStory ? 16 : 12)

                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: "uvva.app")
                        .font(UVVAFont.sans(9))
                        .tracking(1.6)
                        .opacity(0.62)
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(localized: "Map yours ·", bundle: .module).uppercased()).font(UVVAFont.sans(8))
                        Text("UVVA").font(UVVAFont.whiteGrape(10))
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

    /// The map scaled to fit the room it is given, centred in it.
    private var chart: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / PalateMapChart.size.width, proxy.size.height / PalateMapChart.size.height)
            PalateMapChart(values: chartValues, labels: chartLabels, strong: strong, labelSize: 9.5, labelOpacity: 1)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: PalateMapChart.size.width * scale, height: PalateMapChart.size.height * scale,
                       alignment: .topLeading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
