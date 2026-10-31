import DesignSystem
import SwiftUI

/// "Continue with Google": the outline pill under the Apple one. Not wired yet.
struct GoogleButton: View {
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(verbatim: "G").font(.system(size: 16, weight: .medium))
                Text(String(localized: "Continue with Google", bundle: .module).uppercased())
                    .font(UVVAFont.sans(9.5, .semibold))
                    .tracking(2.85)
            }
            .foregroundStyle(UVVAColor.creamFill)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.75))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
