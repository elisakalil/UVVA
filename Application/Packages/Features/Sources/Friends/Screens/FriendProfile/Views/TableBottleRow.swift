import DesignSystem
import SwiftUI

/// A bottle (FRI-R12, R15). In "Open this together" it leads with the axis and why; on the menu, with the course
/// and the dish.
struct TableBottleRow: View {
    enum Style { case axis, course }

    var bottle: TableBottleUIModel
    var style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: style == .axis ? bottle.axisText : bottle.courseText)
            Text(bottle.wineName).font(UVVAFont.sans(17, .light))
            if !bottle.producer.isEmpty {
                Text(bottle.producer.uppercased()).font(UVVAFont.sans(9, .medium)).tracking(2).opacity(0.62)
            }
            Text(style == .axis ? bottle.why : bottle.dishTitle)
                .font(UVVAFont.sans(12.5)).lineSpacing(3).opacity(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
    }
}
