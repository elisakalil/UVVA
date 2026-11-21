import DesignSystem
import SwiftUI

/// An axis of "Reading by reading" (FRI-R19): its name and what the table does on it, the range at the table along
/// a line (the lowest and highest readings as ticks, the middle as a dot), and a line on what it means.
struct AxisSpreadRow: View {
    var row: AxisSpreadRowUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name.uppercased())
                    .font(UVVAFont.sans(11))
                    .tracking(2)
                    .opacity(row.isClose ? 1 : 0.72)
                Spacer()
                Text(row.spreadText.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(1.8)
                    .opacity(0.42)
            }
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Rectangle().fill(UVVAColor.creamFill.opacity(0.14)).frame(height: 1)
                    Rectangle().fill(UVVAColor.creamFill.opacity(0.5))
                        .frame(width: max(0, (row.high - row.low) * width), height: 1)
                        .offset(x: row.low * width)
                    tick.offset(x: row.low * width - 0.5)
                    tick.offset(x: row.high * width - 0.5)
                    Circle().fill(UVVAColor.creamFill)
                        .frame(width: 7, height: 7)
                        .offset(x: row.middle * width - 3.5)
                }
                .frame(height: 9)
            }
            .frame(height: 9)
            .padding(.top, 11)
            Text(row.phrase)
                .font(UVVAFont.sans(11.5))
                .opacity(0.5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)
        }
        .padding(.vertical, 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.name)
        .accessibilityValue("\(row.spreadText). \(row.rangeText). \(row.phrase)")
    }

    private var tick: some View {
        Rectangle().fill(UVVAColor.creamFill.opacity(0.45)).frame(width: 1, height: 7)
    }
}
