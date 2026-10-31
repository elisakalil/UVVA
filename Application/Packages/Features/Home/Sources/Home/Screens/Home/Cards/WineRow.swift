import Core
import DesignSystem
import SwiftUI

struct WineRow: View {
    var wine: Wine

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(wine.name).font(UVVAFont.sans(14.5, .medium))
                if let note = wine.note {
                    Text(note)
                        .font(UVVAFont.sans(12, .regular))
                        .lineSpacing(4)
                        .foregroundStyle(UVVAColor.cream84)
                        .padding(.top, 6)
                }
                if let axis = wine.profile.ranked.first {
                    HStack(spacing: 8) {
                        Text("✷").font(UVVAFont.sans(9))
                        Caption(text: axis.label)
                    }
                    .foregroundStyle(UVVAColor.cream60)
                    .padding(.top, 10)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(UVVAColor.cream60)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}
