import Core
import DesignSystem
import Match
import SwiftUI

/// How close the day's wine sits to the user's map: the match in percent and two lines on why.
struct PalateMatch: View {
    var wine: PalateMap
    var palate: PalateMap

    /// From this value up an axis counts as high, on wine and map alike.
    private static let high = 5.0
    /// Under this difference the wine counts as close to the map on an axis.
    private static let close = 1.8

    private var percent: Int { Int((Similarity.between(wine, palate) * 100).rounded()) }

    /// "High in acidity and fruit, like your map."
    private var shared: String {
        let both = PalateAxis.allCases
            .filter { wine[$0] >= Self.high && palate[$0] >= Self.high }
            .sorted { wine[$0] > wine[$1] }
            .prefix(2)
            .map { $0.label.lowercased() }
        return both.isEmpty
            ? "Different from the strongest axes on your map."
            : "High in \(both.joined(separator: " and ")), like your map."
    }

    /// "More oak than you usually drink."
    private var apart: String {
        guard let far = PalateAxis.allCases.max(by: { abs(wine[$0] - palate[$0]) < abs(wine[$1] - palate[$1]) }),
              abs(wine[far] - palate[far]) >= Self.close
        else { return "Close to your map on every axis." }
        return "\(wine[far] > palate[far] ? "More" : "Less") \(far.label.lowercased()) than you usually drink."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("With your palate".uppercased())
                .font(UVVAFont.sans(8.5, .medium))
                .tracking(2.2)
                .foregroundStyle(UVVAColor.cream)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(percent)%")
                    .font(UVVAFont.sans(40, .ultraLight))
                    .tracking(-1.2)
                Text("match with your map")
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
