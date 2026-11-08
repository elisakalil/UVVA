import DesignSystem
import SwiftUI

struct ProgressDetailSheet: View {
    let stat: ProgressStat

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(text: stat.label)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 40) {
                    ForEach(stat.groups) { group in
                        VStack(alignment: .leading, spacing: 16) {
                            PanelTitle(text: group.title)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(group.items) { item in
                                row(item)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .foregroundStyle(UVVAColor.creamFill)
    }

    private func row(_ item: ProgressStatItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(UVVAFont.sans(17))
            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(UVVAFont.sans(12))
                    .opacity(0.84)
            }
            if !item.chips.isEmpty {
                FlowLayout {
                    ForEach(Array(item.chips.enumerated()), id: \.offset) { _, chip in
                        Text(chip)
                            .font(UVVAFont.sans(11))
                            .foregroundStyle(UVVAColor.cream84)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.04), in: Capsule())
                            .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.75))
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
