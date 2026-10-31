import DesignSystem
import SwiftUI

/// Outline while waiting for the tap, solid cream once done.
struct ContactButton: View {
    var state: ContactRowState
    var action: () -> Void

    private var title: String {
        switch state {
        case .add: String(localized: "Add", bundle: .module)
        case .requested: String(localized: "Requested", bundle: .module)
        case .invite: String(localized: "Invite", bundle: .module)
        case .invited: String(localized: "Invited", bundle: .module)
        }
    }

    private var isDone: Bool { state == .requested || state == .invited }

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9, .semibold))
                .tracking(2.2)
                .foregroundStyle(isDone ? UVVAColor.mossDeep : UVVAColor.creamFill)
                .padding(.horizontal, 12)
                .frame(minWidth: 70, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(UVVAColor.creamFill.opacity(isDone ? 1 : 0))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(UVVAColor.creamFill.opacity(isDone ? 0 : 0.45), lineWidth: 0.5))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: state)
    }
}
