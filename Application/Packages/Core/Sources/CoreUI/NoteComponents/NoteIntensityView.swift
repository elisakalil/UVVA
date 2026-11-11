#if os(iOS)
import Core
import DesignSystem
import Match
import SwiftUI

/// The wine's axes in pips, one line each, as on the wine sheet and in the Hero. With `onPick`, each line is set by a
/// tap or a slide along it (CELLAR-R18).
public struct NoteIntensityView: View {
    var profile: PalateMap
    var onPick: ((Double, PalateAxis) -> Void)?

    public init(profile: PalateMap, onPick: ((Double, PalateAxis) -> Void)? = nil) {
        self.profile = profile
        self.onPick = onPick
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PalateAxis.allCases, id: \.self) { axis in
                if let onPick {
                    // A pip is a step of the palate scale (0...9).
                    PalateReadingLine(name: axis.label, level: MapReading.level(profile[axis]), isStrong: true,
                                      isCompact: true) {
                        onPick(Double($0), axis)
                    }
                } else {
                    PalateReadingLine(name: axis.label, level: MapReading.level(profile[axis]), isStrong: true,
                                      isCompact: true)
                }
            }
        }
        .foregroundStyle(UVVAColor.mossDeep)
    }
}
#endif
