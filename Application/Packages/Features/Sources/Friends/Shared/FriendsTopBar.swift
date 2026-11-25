import DesignSystem
import SwiftUI

/// The top of a friend and of a table. On a table, `‹`, the small wordmark, a hairline and the caption
/// ("UVVA | THE TABLE"); on a friend, "BACK" alone, in the outlined pill of the table's "Expand".
/// Whatever the screen adds sits on the right.
struct FriendsTopBar<Trailing: View>: View {
    /// Nil: "BACK" in a pill, without "UVVA | …".
    var caption: String?
    var backText: String
    var onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                if caption == nil {
                    PillLabel(text: backText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                } else {
                    Text(verbatim: "‹")
                        .font(UVVAFont.sans(26, .ultraLight))
                        .opacity(0.6)
                        .frame(width: 16, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(backText)
            if let caption {
                HStack(spacing: 9) {
                    Text(verbatim: "UVVA")
                        .font(UVVAFont.whiteGrape(15))
                        .tracking(1.5)
                        .opacity(0.55)
                    Rectangle().fill(UVVAColor.creamFill.opacity(0.5)).frame(width: 1, height: 11)
                    Text(caption.uppercased())
                        .font(UVVAFont.sans(9))
                        .tracking(2.7)
                        .opacity(0.45)
                }
                .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            trailing
        }
        .padding(.leading, -2)
    }
}

/// The hairline across the whole width, under a friend's tabs and under the table's heading.
struct FriendsHairline: View {
    var body: some View {
        Rectangle().fill(UVVAColor.creamFill.opacity(0.14)).frame(height: 1)
    }
}

/// A short line and its words, under a chart: solid, or drawn with the chart's own dash.
struct ChartLegendItem: View {
    var text: String
    var dash: [CGFloat] = []
    var lineOpacity = 0.6
    var textOpacity = 0.4
    var weight: Font.Weight = .ultraLight

    var body: some View {
        HStack(spacing: 8) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: 14, y: 0.5))
            }
            .stroke(UVVAColor.creamFill.opacity(lineOpacity), style: StrokeStyle(lineWidth: 1, dash: dash))
            .frame(width: 14, height: 1)
            Text(text.uppercased())
                .font(UVVAFont.sans(8, weight))
                .tracking(1.1)
                .opacity(textOpacity)
        }
    }
}
