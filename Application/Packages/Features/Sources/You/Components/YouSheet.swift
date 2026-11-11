import DesignSystem
import SwiftUI

/// The sheet the account rows open (YOU-R14): it rises over the You tab, with the same hills behind it, a title in
/// Red Grapes and a line under it. No back or close button: it leaves with a drag down or a tap outside it.
struct YouSheet<Content: View>: View {
    var title: String
    var message: String?
    var height: CGFloat
    var content: Content

    init(title: String, message: String? = nil, height: CGFloat, @ViewBuilder content: () -> Content) {
        self.title = title
        self.message = message
        self.height = height
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(UVVAFont.redGrapes(22)).tracking(0.9)
                .accessibilityAddTraits(.isHeader)
            if let message {
                Text(message)
                    .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.86).frame(maxWidth: 300, alignment: .leading)
                    .padding(.top, 10)
            }
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 30)
        .padding(.top, 36)
        .padding(.bottom, 20)
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground { PageBackground(photo: UVVAPhoto.hills, veiled: true) }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
