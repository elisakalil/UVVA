import DesignSystem
import SwiftUI

/// YOU-R01
struct YouHeader: View {
    var model: YouHeaderUIModel

    var body: some View {
        HStack(spacing: 16) {
            Avatar(photo: model.photo)
            VStack(alignment: .leading, spacing: 6) {
                Text(model.name)
                    .font(UVVAFont.sans(24, .ultraLight))
                    .tracking(-0.36)
                Text(model.signature)
                    .font(UVVAFont.sans(9.5))
                    .tracking(1.9)
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
        }
    }
}
