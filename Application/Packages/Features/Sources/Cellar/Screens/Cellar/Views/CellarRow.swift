import DesignSystem
import SwiftUI

/// A row of the list: the label, the name and vintage, where it comes from, and the tag (CELLAR-R06, R09).
struct CellarRow: View {
    var model: CellarItemUIModel

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(CellarPalette.coverGround)
                .overlay { CellarPhoto(data: model.photo) }
                .clipShape(Circle())
                .overlay { Circle().strokeBorder(UVVAColor.creamFill.opacity(0.25), lineWidth: 0.5) }
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(Text(model.name)) \(Text(model.vintage).font(UVVAFont.whiteGrape(13)).foregroundStyle(UVVAColor.creamFill.opacity(0.78)))")
                    .font(UVVAFont.sans(15))
                    .lineLimit(1)
                if !model.meta.isEmpty {
                    Text(model.meta)
                        .font(UVVAFont.sans(11.5))
                        .opacity(0.8)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.tag.uppercased())
                .font(UVVAFont.redGrapes(13))
                .tracking(0.5)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .ultraLight))
                .opacity(0.6)
        }
        .padding(.vertical, 18)
        .padding(.leading, 24)
        .padding(.trailing, 26)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }
}
