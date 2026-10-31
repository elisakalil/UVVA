import DesignSystem
import SwiftUI

/// Stands in for a tab that is not built yet.
struct TabPlaceholder: View {
    var name: String

    var body: some View {
        ZStack {
            UVVAColor.moss.ignoresSafeArea()
            Text(name).font(UVVAFont.sans(31, .ultraLight)).foregroundStyle(UVVAColor.cream)
        }
    }
}
