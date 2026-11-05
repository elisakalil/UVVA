import DesignSystem
import SwiftUI

/// HOME-R30
struct TourIntro: View {
    var firstName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "Your map is ready", bundle: .module).uppercased())
                .font(UVVAFont.sans(9)).tracking(2.7).opacity(0.7)
            Text("Welcome in, \(firstName)", bundle: .module)
                .font(UVVAFont.sans(32, .ultraLight)).tracking(-0.5)
                .padding(.top, 18)
            Text("A short walk through where things live in UVVA.", bundle: .module)
                .font(UVVAFont.sans(13)).lineSpacing(6).opacity(0.82)
                .frame(maxWidth: 290, alignment: .leading)
                .padding(.top, 16)
        }
        .foregroundStyle(Color(hex: 0xF6EFE0))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
