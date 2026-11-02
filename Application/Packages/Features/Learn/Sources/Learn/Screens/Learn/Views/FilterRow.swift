import DesignSystem
import SwiftUI

/// A row of caps words that scrolls sideways: levels, colours and countries, or the countries of By region.
struct FilterRow: View {
    var filters: [FilterUIModel]
    var onSelect: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 22) {
                    ForEach(filters) { filter in
                        Button { onSelect(filter.id) } label: {
                            Text(filter.label.uppercased())
                                .font(UVVAFont.sans(9.5, filter.isSelected ? .regular : .light))
                                .tracking(2.6)
                                .opacity(filter.isSelected ? 1 : 0.52)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(filter.id)
                        .accessibilityAddTraits(filter.isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
            .onChange(of: filters.first(where: \.isSelected)?.id) { _, id in
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }
}
