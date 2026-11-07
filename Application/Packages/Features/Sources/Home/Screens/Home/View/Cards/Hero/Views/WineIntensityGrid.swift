import Core
import DesignSystem
import SwiftUI

/// The eight axes of a wine, four to a row, each with its level in dots.
struct WineIntensityGrid: View {
    var profile: PalateMap

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 4),
            alignment: .leading,
            spacing: 22
        ) {
            ForEach(PalateAxis.allCases, id: \.self) { axis in
                VStack(alignment: .leading, spacing: 9) {
                    Text(axis.label.uppercased())
                        .font(UVVAFont.sans(8, .medium))
                        .tracking(1)
                        .foregroundStyle(UVVAColor.cream84)
                    IntensityDots(value: profile[axis])
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
