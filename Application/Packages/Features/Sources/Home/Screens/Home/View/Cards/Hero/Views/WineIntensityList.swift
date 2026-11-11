import Core
import DesignSystem
import Match
import SwiftUI

/// One row per axis, with the wine's intensity shown in dots.
struct WineIntensityList: View {
    var profile: PalateMap

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PalateAxis.allCases, id: \.self) { axis in
                PalateReadingLine(name: axis.label, level: MapReading.level(profile[axis]), isStrong: true)
            }
        }
    }
}
