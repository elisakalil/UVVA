import Core
import DesignSystem
import SwiftUI

/// The Intro's map, drifting slowly from shape to shape. Still when Reduce Motion is on.
struct AnimatedPalateMap: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let speeds: [Double] = [0.31, 0.43, 0.27, 0.37, 0.23, 0.41, 0.29, 0.35]
    private static let phases: [Double] = [0.0, 1.7, 3.1, 4.4, 2.2, 5.3, 0.9, 3.8]

    private func values(at time: Double) -> [Double] {
        Self.speeds.indices.map { i in
            0.5 + 0.32 * sin(time * Self.speeds[i] + Self.phases[i]) + 0.1 * sin(time * Self.speeds[i] * 2.3)
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            PalateMapChart(values: values(at: reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate),
                           labels: PalateAxis.allCases.map(\.label), labelOpacity: 0.55)
        }
        .scaleEffect(1.1)
        .frame(width: PalateMapChart.size.width, height: PalateMapChart.size.height * 1.1)
    }
}
