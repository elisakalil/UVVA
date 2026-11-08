import DesignSystem
import SwiftUI

/// The capsule buttons of the new note: filled for the way forward, outlined for the other way.
struct NewNotePill: View {
    enum Style { case filled, outlined }

    var title: String
    var style: Style
    /// The ink of the page: cream over the camera and messages, dark ink on paper.
    var ink: Color
    /// What a filled pill's title is written in.
    var ground: Color
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9.5, .semibold))
                .tracking(2.85)
                .foregroundStyle(style == .filled ? ground : ink.opacity(0.8))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background {
                    switch style {
                    case .filled: Capsule().fill(ink)
                    case .outlined: Capsule().strokeBorder(ink.opacity(0.35), lineWidth: 0.5)
                    }
                }
                .contentShape(Capsule())
                .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
