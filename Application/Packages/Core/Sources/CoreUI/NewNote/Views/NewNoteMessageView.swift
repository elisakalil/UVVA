#if os(iOS)
import DesignSystem
import SwiftUI
import UIKit

/// "We couldn't read your label" (CELLAR-R21) and "The camera is off" (CELLAR-R22): what went wrong, and two ways on.
struct NewNoteMessageView: View {
    var model: NewNoteUIModel
    var onPrimary: () -> Void
    var onFillInByHand: () -> Void

    @Environment(\.openURL) private var openURL

    private var resources: NewNoteResourcesUIModel { model.resources }
    private var isError: Bool { model.step == .readFailed }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 44)
            VStack(spacing: 40) {
                VStack(spacing: 0) {
                    Text(verbatim: "!")
                        .font(UVVAFont.sans(28, .ultraLight))
                        .frame(width: 52, height: 52)
                        .overlay { Circle().strokeBorder(UVVAColor.creamFill, lineWidth: 1) }
                        .accessibilityHidden(true)
                    Text(isError ? resources.errorTitleText : resources.deniedTitleText)
                        .font(UVVAFont.sans(23, .ultraLight))
                        .tracking(-0.45)
                        .padding(.top, 18)
                        .accessibilityAddTraits(.isHeader)
                    Text(isError ? resources.errorBodyText : resources.deniedBodyText)
                        .font(UVVAFont.sans(12))
                        .lineSpacing(4)
                        .opacity(0.78)
                        .frame(maxWidth: 290)
                        .padding(.top, 8)
                }
                .multilineTextAlignment(.center)
                if isError {
                    VStack(alignment: .leading, spacing: 4) {
                        tip(1, resources.lightTitleText, resources.lightBodyText)
                        tip(2, resources.wholeLabelTitleText, resources.wholeLabelBodyText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 30)
            Spacer(minLength: 24)
            VStack(spacing: 10) {
                NewNotePill(title: isError ? resources.tryAgainText : resources.openSettingsText, style: .filled,
                            ink: UVVAColor.creamFill, ground: UVVAColor.ink, action: primary)
                NewNotePill(title: resources.fillInByHandText, style: .outlined, ink: UVVAColor.creamFill,
                            ground: UVVAColor.ink, action: onFillInByHand)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 20)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .background(PageBackground(blur: 2, veiled: true).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func primary() {
        if isError {
            onPrimary()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            // CELLAR-R22: "Open Settings" opens UVVA's page in the iOS Settings.
            openURL(url)
        }
    }

    private func tip(_ number: Int, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(UVVAFont.sans(9, .regular))
                .frame(width: 15, height: 15)
                .overlay { Circle().strokeBorder(UVVAColor.creamFill, lineWidth: 0.5) }
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(UVVAFont.sans(12.5))
                Text(text).font(UVVAFont.sans(11)).lineSpacing(3).opacity(0.72)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
#endif
