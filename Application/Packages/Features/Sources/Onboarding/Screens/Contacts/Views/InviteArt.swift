import Core
import DesignSystem
import Match
import SwiftUI
import UIKit

/// The picture sent with an invite (ONB-R37a): the user's palate card when there is a map (from the Friends tab);
/// during the Onboarding, before the Quiz, the vineyard with the grapes and "Map your taste in wine with me".
struct InviteArt: View {
    var name: String
    var map: PalateMap?

    var body: some View {
        if let map {
            let reading = MapReading(map: map)
            PalateShareCard(heading: String(localized: "This is my wine palate", bundle: .module),
                            phrase: name.isEmpty ? reading.dominantPhrase : name,
                            chartValues: map.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                            strong: Set(reading.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                            lines: [], format: .whatsApp)
        } else {
            welcome
        }
    }

    private var welcome: some View {
        let size = ShareFormat.whatsApp.cardSize
        return ZStack {
            UVVAPhoto.background
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
            LinearGradient(colors: [Color(hex: 0x1C2215).opacity(0.15), Color(hex: 0x1C2215).opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
            VStack(spacing: 0) {
                Text(verbatim: "UVVA")
                    .font(UVVAFont.whiteGrape(26))
                    .tracking(2.6)
                Spacer(minLength: 0)
                UVVAIllustration.grape(4)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 98)
                Text(String(localized: "Map your taste in wine with me", bundle: .module))
                    .font(UVVAFont.whiteGrape(22))
                    .multilineTextAlignment(.center)
                    .padding(.top, 18)
                Spacer(minLength: 0)
                Text(verbatim: "uvva.app")
                    .font(UVVAFont.sans(9))
                    .tracking(1.8)
                    .opacity(0.8)
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 24)
        }
        .frame(width: size.width, height: size.height)
        .foregroundStyle(UVVAColor.creamFill)
    }

    /// The picture as a JPEG, at the size of every shared image (1080 px wide).
    @MainActor
    func jpeg() -> Data? {
        let renderer = ImageRenderer(content: environment(\.colorScheme, .dark))
        renderer.scale = ShareFormat.renderScale
        return renderer.uiImage?.jpegData(compressionQuality: 0.85)
    }
}
