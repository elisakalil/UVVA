import DesignSystem
import SwiftUI

struct RegionPin: View {
    var body: some View {
        Circle().fill(Color.white).frame(width: 6, height: 6)
            .background(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 0.6).frame(width: 15, height: 15))
    }
}
