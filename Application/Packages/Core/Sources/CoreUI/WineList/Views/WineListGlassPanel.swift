#if os(iOS)
import DesignSystem
import SwiftUI

/// Frosted glass over the camera (WINELIST-R03): the live picture blurred behind it, a light rim and a soft edge.
struct WineListGlassPanel<Content: View>: View {
    var radius: CGFloat = UVVARadius.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.06), .white.opacity(0.12)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(UVVAColor.glassEdge, lineWidth: 0.5) }
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 12)
            }
            .environment(\.colorScheme, .dark)
    }
}
#endif
