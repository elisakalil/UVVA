import DesignSystem
import SwiftUI

/// The glass sheet that asks before signing out or deleting (YOU-R26, R27).
struct ConfirmSheet: View {
    var kind: ConfirmKind
    var isWorking: Bool
    var onConfirm: () async -> Void
    var onCancel: () -> Void

    private var eyebrow: String {
        kind == .signOut ? String(localized: "Sign out", bundle: .module) : String(localized: "Delete account", bundle: .module)
    }
    private var title: String {
        kind == .signOut ? String(localized: "Sign out of UVVA?", bundle: .module)
                         : String(localized: "Delete your account?", bundle: .module)
    }
    private var message: String {
        kind == .signOut
            ? String(localized: "Your palate map, cellar and certificates stay saved to your account.", bundle: .module)
            : String(localized: "This permanently removes your palate map, cellar, tables and certificates. It cannot be undone.", bundle: .module)
    }
    private var confirm: String {
        kind == .signOut ? String(localized: "Sign out", bundle: .module) : String(localized: "Delete my account", bundle: .module)
    }
    private var cancel: String {
        kind == .signOut ? String(localized: "Cancel", bundle: .module) : String(localized: "Keep my account", bundle: .module)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow.uppercased()).font(UVVAFont.sans(9, .semibold)).tracking(3.2).opacity(0.82)
                .padding(.top, 26)
            Text(title).font(UVVAFont.sans(28, .ultraLight)).tracking(-0.4).padding(.top, 12)
            Text(message).font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.86).padding(.top, 10)
            ActionButton(confirm, isEnabled: !isWorking) { Task { await onConfirm() } }
                .padding(.top, 30)
            TextAction(cancel, opacity: 0.72, action: onCancel)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(LinearGradient(colors: [Color(hex: 0x4E5A40).opacity(0.94), Color(hex: 0x38422E).opacity(0.96)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .ignoresSafeArea()
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}
