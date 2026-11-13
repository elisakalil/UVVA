import Core
import Foundation
import Match

/// How a wine sits with the user's map, in two lines (HOME-R10b): on the Home's cards and sheet, and on a saved
/// note of the Cellar.
public struct PalateMatchUIModel {
    public let wine: PalateMap
    public let palate: PalateMap

    public init(wine: PalateMap, palate: PalateMap) {
        self.wine = wine
        self.palate = palate
    }

    private var fit: WineFit { WineFit(wine: wine, map: palate) }

    public var percentage: String { "\(percent)%" }

    public var percent: Int { Similarity.percent(wine, palate) }

    /// "High in acidity and fruit, like your map." (HOME-R10b)
    public var shared: String {
        let fit = fit
        let both = fit.shared.map { $0.label.lowercased() }
        switch both.count {
        case 2: return String(localized: "High in \(both[0]) and \(both[1]), like your map.", bundle: .module)
        case 1: return String(localized: "High in \(both[0]), like your map.", bundle: .module)
        default: break
        }
        switch fit.mapHighs.count {
        case 0:
            return fit.wineHasHigh
                ? String(localized: "Bolder than your map, which has no high axis.", bundle: .module)
                : String(localized: "Quiet on every axis, like your map.", bundle: .module)
        case 1:
            return String(localized: "Not high in \(fit.mapHighs[0].label.lowercased()), the strongest axis on your map.", bundle: .module)
        default:
            return String(localized: "Different from the strongest axes on your map.", bundle: .module)
        }
    }

    /// "More oak than you usually drink." (HOME-R10b)
    public var apart: String {
        guard let far = fit.apart else { return String(localized: "Close to your map on every axis.", bundle: .module) }
        let axis = far.label.lowercased()
        return wine[far] > palate[far]
            ? String(localized: "More \(axis) than you usually drink.", bundle: .module)
            : String(localized: "Less \(axis) than you usually drink.", bundle: .module)
    }

}
