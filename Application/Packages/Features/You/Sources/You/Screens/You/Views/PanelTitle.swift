import DesignSystem
import SwiftUI

/// "YOUR PROGRESS", "THE MAP": 9 pt caps, wide tracking.
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
