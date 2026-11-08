import Core
import DesignSystem
import SwiftUI

/// The map drawn at the width of the page; with `comparison`, a second map faintly under it (FRI-R12).
struct FriendChart: View {
    var values: [Double]
    var strong: Set<Int> = []
    var comparison: [Double]?

    private static let scale: CGFloat = 0.84

    var body: some View {
        PalateMapChart(values: values, labels: PalateAxis.allCases.map(\.label), strong: strong, comparison: comparison)
            .scaleEffect(Self.scale)
            // The scaled size, so the chart's own 330 pt never widens the page.
            .frame(width: PalateMapChart.size.width * Self.scale, height: PalateMapChart.size.height * Self.scale)
            .frame(maxWidth: .infinity)
    }
}
