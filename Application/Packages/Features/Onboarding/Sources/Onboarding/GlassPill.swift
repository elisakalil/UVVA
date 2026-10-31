import DesignSystem
import SwiftUI

/// The faint glass of the canvas's small controls (country chip, Terms / Privacy).
struct GlassPill: View {
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [UVVAColor.creamFill.opacity(0.027), UVVAColor.creamFill.opacity(0.008),
                                          UVVAColor.creamFill.opacity(0.016)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .background(.ultraThinMaterial.opacity(0.35), in: Capsule())
            .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.108), lineWidth: 0.5))
            .shadow(color: Color(hex: 0x12180E).opacity(0.062), radius: 4, y: 3)
    }
}
