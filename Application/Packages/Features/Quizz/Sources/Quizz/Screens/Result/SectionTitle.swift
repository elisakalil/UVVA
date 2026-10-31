import DesignSystem
import SwiftUI

/// "YOUR READINGS", "WHERE THE MAP POINTS".
struct SectionTitle: View {
    var text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .semibold))
            .tracking(3.2)
            .opacity(0.82)
    }
}
