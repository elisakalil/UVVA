import Core
import Foundation
import Match

struct DailySuggestionUIModel {
    let wine: Wine
    let palateMap: PalateMap
    private var fit: WineFit { WineFit(wine: wine.profile, map: palateMap) }

    /// The user's three strongest axes, read on this wine (HOME-R10a).
    var axes: [PalateAxis] { fit.shown }

    /// Why it was picked: the user's high axes on which this wine is also high (HOME-R10a).
    var reason: String? {
        let fit = fit
        let shared = fit.shared.map { $0.label.lowercased() }
        switch shared.count {
        case 2: return String(localized: "Your map likes \(shared[0]) and \(shared[1]), and this wine is high on both.", bundle: .module)
        case 1: return String(localized: "Your map likes \(shared[0]), and this wine is high on it.", bundle: .module)
        default:
            return fit.mapHighs.isEmpty && !fit.wineHasHigh
                ? String(localized: "Nothing runs high on your map, and nothing runs high on this wine.", bundle: .module)
                : nil
        }
    }

}
