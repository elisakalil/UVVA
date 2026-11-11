import Core
import DesignSystem
import SwiftUI

/// Half-width card: the palate map with the axis that moved, and one line on what changed.
struct ChangedMapCard: View {
    var resources = HomeResourcesUIModel()
    var axis: PalateAxis
    var delta: Double
    var palateMap: PalateMap

    var body: some View {
        FrostedCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                PalateRadar(map: palateMap, highlight: axis)
                    .frame(width: 70, height: 70)
                    .padding(.top, 6)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 6)
                Text(resources.mapChange(axis: axis, delta: delta))
                    .font(UVVAFont.sans(12, .regular))
                    .lineSpacing(3)
                    .lineLimit(3)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
