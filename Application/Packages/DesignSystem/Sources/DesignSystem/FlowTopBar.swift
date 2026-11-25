import SwiftUI

/// The top of a flow screen: "Back" in a pill on the left (as at the top of a friend), and on the right the small wordmark, a hairline and a caption
/// ("UVVA | 3 OF 8", "UVVA | PALATE MAP").
public struct FlowTopBar: View {
    var caption: String
    var onBack: (() -> Void)?

    public init(caption: String, onBack: (() -> Void)? = nil) {
        self.caption = caption
        self.onBack = onBack
    }

    public var body: some View {
        HStack(spacing: 14) {
            if let onBack {
                BackPillButton(action: onBack)
                    .foregroundStyle(UVVAColor.creamFill)
            }
            Spacer(minLength: 0)
            HStack(spacing: 9) {
                Text("UVVA")
                    .font(UVVAFont.whiteGrape(15))
                    .tracking(1.5)
                    .foregroundStyle(UVVAColor.creamFill.opacity(0.55))
                Rectangle().fill(UVVAColor.creamFill.opacity(0.22)).frame(width: 0.5, height: 11)
                Text(caption.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(2.7)
                    .foregroundStyle(UVVAColor.creamFill.opacity(0.6))
            }
        }
        .frame(height: 30)
    }
}
