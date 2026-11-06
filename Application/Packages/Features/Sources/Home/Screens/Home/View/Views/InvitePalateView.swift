import Core
import DesignSystem
import Match
import SwiftUI

struct InvitePalateView: View {
    var name: String
    var map: PalateMap
    var onFinish: () -> Void

    private var message: String {
        String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together.", bundle: .module)
    }

    var body: some View {
        ShareScreen(title: String(localized: "Share your palate", bundle: .module),
                    message: message, showsMessage: true, dismissAfterAction: false) { format in
            InvitePalateCard(name: name, map: map, format: format)
        } onFinish: {
            onFinish()
        }

    }
}

private struct InvitePalateCard: View {
    var name: String
    var map: PalateMap
    var format: ShareFormat

    private let ink = Color(hex: 0x293022)

    var body: some View {
        VStack(spacing: 0) {
            Text("UVVA")
                .font(UVVAFont.whiteGrape(13))
                .tracking(3)
            Text(String(localized: "This is my wine palate", bundle: .module).uppercased())
                .font(UVVAFont.sans(6.5, .medium))
                .tracking(2)
                .opacity(0.6)
                .padding(.top, 16)
            Text(name)
                .font(UVVAFont.whiteGrape(28))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 10)
            Spacer(minLength: 8)
            PalateMapChart(values: map.chartValues, labels: PalateAxis.allCases.map(\.label),
                           labelSize: 9, labelOpacity: 1, ink: ink)
                .scaleEffect(format == .story ? 0.67 : 0.5)
                .frame(width: format == .story ? 221 : 165, height: format == .story ? 201 : 150)
            Spacer(minLength: 8)
            Text(MapReading(map: map).shortCaption)
                .font(UVVAFont.sans(10))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(ink.opacity(0.2))
                .frame(height: 0.5)
                .padding(.top, 13)
            Text(String(localized: "Map yours · uvva.app", bundle: .module).uppercased())
                .font(UVVAFont.sans(6))
                .tracking(1.8)
                .opacity(0.55)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, format == .story ? 24 : 16)
        .frame(width: format.cardSize.width, height: format.cardSize.height)
        .foregroundStyle(ink)
        .background(Color(hex: 0xF3EDDF))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    InvitePalateView(name: "Elisa", map: PalateMap([.acidity: 8, .fruit: 8, .sweetness: 2])) {}
}
