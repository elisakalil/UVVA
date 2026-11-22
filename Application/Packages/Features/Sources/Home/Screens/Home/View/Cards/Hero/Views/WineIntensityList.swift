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
                let level = MapReading.level(profile, axis)
                PalateReadingLine(name: axis.localizedLabel, level: level, word: MapReading.levelWord(level, on: axis),
                                  isStrong: true)
            }
        }
    }
}
