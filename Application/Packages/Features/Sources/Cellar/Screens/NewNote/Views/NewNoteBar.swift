import DesignSystem
import SwiftUI

/// `×` (or `‹`), then "UVVA | NEW NOTE", over the camera, a message or the paper.
struct NewNoteBar: View {
    var label: String
    var icon: String
    var iconLabel: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(iconLabel)
            .padding(.leading, -12)
            HStack(spacing: 9) {
                Text(verbatim: "UVVA")
                    .font(UVVAFont.whiteGrape(15))
                    .tracking(1.5)
                    .opacity(0.7)
                Rectangle().fill(.foreground.opacity(0.5)).frame(width: 1, height: 11)
                Text(label.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(2.7)
                    .opacity(0.8)
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding(.horizontal, 26)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}
