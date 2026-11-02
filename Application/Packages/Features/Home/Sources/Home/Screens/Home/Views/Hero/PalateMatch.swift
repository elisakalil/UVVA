import Core
import DesignSystem
import Match
import SwiftUI

/// How close the day's wine sits to the user's map: the match in percent and two lines on why.
struct PalateMatch: View {
    var wine: PalateMap
    var palate: PalateMap

    private var fit: WineFit { WineFit(wine: wine, map: palate) }

    private var percent: Int { Int((Similarity.between(wine, palate) * 100).rounded()) }

    /// "High in acidity and fruit, like your map." (HOME-R10b)
    private var shared: String {
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
    private var apart: String {
        guard let far = fit.apart else { return String(localized: "Close to your map on every axis.", bundle: .module) }
        let axis = far.label.lowercased()
        return wine[far] > palate[far]
            ? String(localized: "More \(axis) than you usually drink.", bundle: .module)
            : String(localized: "Less \(axis) than you usually drink.", bundle: .module)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "With your palate", bundle: .module).uppercased())
                .font(UVVAFont.sans(8.5, .medium))
                .tracking(2.2)
                .foregroundStyle(UVVAColor.cream)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(percent)%")
                    .font(UVVAFont.sans(40, .ultraLight))
                    .tracking(-1.2)
                Text(String(localized: "match with your map", bundle: .module))
                    .font(UVVAFont.sans(12.5, .regular))
                    .foregroundStyle(UVVAColor.cream84)
            }
            .padding(.top, 16)
            VStack(alignment: .leading, spacing: 6) {
                Text(shared)
                Text(apart)
            }
            .font(UVVAFont.sans(13, .light))
            .lineSpacing(4)
            .foregroundStyle(UVVAColor.cream.opacity(0.9))
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
