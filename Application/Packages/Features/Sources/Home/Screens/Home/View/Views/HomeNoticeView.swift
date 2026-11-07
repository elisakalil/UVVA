import DesignSystem
import SwiftUI

/// A short line that drops in at the top of the screen after an action, such as "Map updated · Acidity ↑"
/// (HOME-R24) or "Saved to Cellar · [wine]" (HOME-R28). The view model clears it after a few seconds.
struct HomeNoticeView: View {
    var text: String?

    var body: some View {
        ZStack {
            if let text {
                Text(text)
                    .font(UVVAFont.sans(12.5, .medium))
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(UVVAColor.mossDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(UVVAColor.creamFill))
                    .shadow(color: Color(red: 12 / 255, green: 16 / 255, blue: 9 / 255).opacity(0.4), radius: 17, y: 14)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: text)
        .allowsHitTesting(false)
        .onChange(of: text) { _, text in
            if let text { AccessibilityNotification.Announcement(text).post() }
        }
    }
}
