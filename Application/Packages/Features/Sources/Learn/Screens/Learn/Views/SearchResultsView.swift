import DesignSystem
import SwiftUI

/// What "Search modules" found, in bands: Regions, Grapes, The path, Lessons.
struct SearchResultsView: View {
    var resources = LearnResourcesUIModel()
    var groups: [SearchGroupUIModel]
    var query: String
    var onOpen: (SearchResultUIModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if groups.isEmpty {
                Text(resources.noResults(query))
                    .font(UVVAFont.sans(13.5))
                    .lineSpacing(5)
                    .opacity(0.72)
                    .padding(.top, 28)
            }
            ForEach(groups) { group in
                Text(group.title.uppercased())
                    .font(UVVAFont.sans(9.5))
                    .tracking(2.6)
                    .opacity(0.72)
                    .padding(.top, 28)
                    .padding(.bottom, 2)
                    .accessibilityAddTraits(.isHeader)
                ForEach(group.results) { result in
                    row(result)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func row(_ result: SearchResultUIModel) -> some View {
        Button { onOpen(result) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title).font(UVVAFont.sans(15))
                    if !result.detail.isEmpty {
                        Text(result.detail.uppercased())
                            .font(UVVAFont.sans(9.5))
                            .tracking(1.6)
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: "›")
                    .font(UVVAFont.sans(18, .ultraLight))
                    .opacity(0.55)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
