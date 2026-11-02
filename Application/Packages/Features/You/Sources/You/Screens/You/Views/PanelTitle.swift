import DesignSystem
import SwiftUI

/// "READ 1 NOV": 9 pt caps, wide tracking.
struct PanelTitle: View {
    var text: String
    var opacity: Double = 1

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .regular))
            .tracking(2.7)
            .opacity(opacity)
    }
}

/// "SPECIALIST IN", "YOUR READINGS": a section inside a panel, in Red Grapes caps.
struct SectionTitle: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.redGrapes(16))
            .tracking(0.64)
    }
}
