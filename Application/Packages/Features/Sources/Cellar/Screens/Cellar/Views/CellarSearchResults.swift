import DesignSystem
import SwiftUI

/// What "Search your cellar" found: "[n] notes" and the wines, or the empty search (CELLAR-R11, R12).
struct CellarSearchResults: View {
    var resources: CellarResourcesUIModel
    var count: String
    var results: [CellarSearchResultUIModel]
    var noResultsText: String
    var onOpen: (String) -> Void

    var body: some View {
        if results.isEmpty {
            VStack(spacing: 10) {
                Text(noResultsText)
                    .font(UVVAFont.sans(23, .ultraLight))
                Text(resources.searchHintText)
                    .font(UVVAFont.sans(12))
                    .opacity(0.78)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 30)
            .padding(.top, 130)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(count.uppercased())
                    .font(UVVAFont.sans(8.5, .regular))
                    .tracking(2.7)
                    .opacity(0.6)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 14)
                ForEach(results) { result in
                    Button { onOpen(result.id) } label: { row(result) }
                        .buttonStyle(.plain)
                }
                CellarPalette.rule.frame(height: 1)
            }
            .padding(.top, 16)
        }
    }

    private func row(_ result: CellarSearchResultUIModel) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(result.title).font(UVVAFont.sans(15))
                Text(result.meta).font(UVVAFont.sans(11)).opacity(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(result.tag.uppercased())
                .font(UVVAFont.redGrapes(18))
                .tracking(1)
                .foregroundStyle(UVVAColor.sky)
        }
        .padding(.vertical, 24)
        .padding(.leading, 30)
        .padding(.trailing, 26)
        .overlay(alignment: .top) { CellarPalette.rule.frame(height: 1) }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
