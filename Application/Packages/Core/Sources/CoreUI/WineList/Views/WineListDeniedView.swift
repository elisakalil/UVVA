#if os(iOS)
import DesignSystem
import SwiftUI

/// The camera is off: the list cannot be read without it.
struct WineListDeniedView: View {
    var model: WineListUIModel

    var body: some View {
        ZStack {
            NotePalette.cameraGround.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text(model.resources.deniedTitleText).font(UVVAFont.sans(26, .ultraLight))
                Text(model.resources.deniedBodyText)
                    .font(UVVAFont.sans(13))
                    .foregroundStyle(UVVAColor.cream84)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(String(localized: "Open Settings", bundle: .module), destination: url)
                        .font(UVVAFont.sans(13, .medium))
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
    }
}
#endif
