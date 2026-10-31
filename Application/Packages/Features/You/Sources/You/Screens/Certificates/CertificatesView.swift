import DesignSystem
import SwiftUI

/// Certificates (YOU-R23, R24). None exist until Learn awards them, so the empty state shows.
struct CertificatesView: View {
    var onStartLearning: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PageBackground(photoOpacity: 0.5)
            VStack(spacing: 0) {
                FlowTopBar(caption: String(localized: "Certificates", bundle: .module)) { dismiss() }
                    .padding(.horizontal, 26)
                Spacer()
                UVVAIllustration.grape(3).resizable().scaledToFit().frame(width: 72, height: 100)
                Text(String(localized: "No certificates yet", bundle: .module).uppercased())
                    .font(UVVAFont.redGrapes(22)).tracking(0.9).padding(.top, 24)
                Text("Certificates for the lessons you complete live here. Finish one to see it, then come back whenever you like.", bundle: .module)
                    .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.84)
                    .multilineTextAlignment(.center).frame(maxWidth: 290).padding(.top, 12)
                ActionButton(String(localized: "Start learning", bundle: .module), action: onStartLearning)
                    .frame(width: 220).padding(.top, 30)
                Spacer()
            }
            .padding(.top, 8)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}
