import DesignSystem
import SwiftUI

/// An axis of "Reading by reading" (FRI-R19).
struct AxisSpreadRow: View {
    var row: AxisSpreadRowUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name.uppercased()).font(UVVAFont.sans(11.5)).tracking(1.8)
                Spacer()
                Text(row.spreadText.uppercased()).font(UVVAFont.sans(9, .semibold)).tracking(1.8).opacity(0.8)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(row.phrase).font(UVVAFont.sans(12.5)).opacity(0.75)
                Spacer()
                Text(row.rangeText).font(UVVAFont.sans(12.5)).monospacedDigit().opacity(0.75)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
