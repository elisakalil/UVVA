import DesignSystem
import SwiftUI

/// The wines tasted from one place of the Progress map (YOU-R07a): the place, how many bottles, and each wine with its
/// producer and vintage. A wine opens its note in the Cellar.
struct ProgressPlaceSheet: View {
    let place: ProgressMapPin
    var onSelect: (ProgressMapWine) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: place.name)
                .accessibilityAddTraits(.isHeader)
            Text(bottlesText)
                .font(UVVAFont.sans(12))
                .opacity(0.7)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(place.wines) { wine in
                        Button { onSelect(wine) } label: { row(wine) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 14)
        }
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .foregroundStyle(UVVAColor.creamFill)
    }

    private var bottlesText: String {
        place.count == 1
            ? String(localized: "1 bottle", bundle: .module)
            : String(localized: "\(place.count) bottles", bundle: .module)
    }

    private func row(_ wine: ProgressMapWine) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(wine.name)
                    .font(UVVAFont.sans(17))
                if !wine.detail.isEmpty {
                    Text(wine.detail)
                        .font(UVVAFont.sans(12))
                        .opacity(0.8)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .opacity(0.8)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) { Rectangle().fill(UVVAColor.creamFill.opacity(0.18)).frame(height: 0.5) }
    }
}
