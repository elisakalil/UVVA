import DesignSystem
import SwiftUI

/// A friend's card of wines, "Picks for [name]" (FRI-R11) and "Open this together" (FRI-R12), as the Home's
/// "Wines for your palate": the title in the brush lettering, then each wine and its producer, and under it only the
/// reading and how strong. Each wine opens Friend Wine.
struct FriendWinesCard: View {
    var title: String
    /// Nil while the wines are worked out.
    var rows: [WineCardRowUIModel]?
    var loadingText = ""
    var emptyText = ""
    var onOpen: (String) -> Void

    var body: some View {
        FrostedCard(radius: UVVARadius.hero, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(UVVAFont.redGrapes(21))
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.leading, 26)
                    .padding(.trailing, 44)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                if let rows {
                    if rows.isEmpty {
                        note(Text(emptyText))
                    } else {
                        ForEach(rows) { row in
                            if row.id != rows.first?.id {
                                Rectangle().fill(Color.white.opacity(0.14)).frame(height: 0.5).padding(.horizontal, 26)
                            }
                            Button { onOpen(row.id) } label: { wine(row) }
                                .buttonStyle(.plain)
                        }
                    }
                } else {
                    note(HStack(spacing: 10) {
                        ProgressView().tint(UVVAColor.creamFill)
                        Text(loadingText)
                    })
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func wine(_ row: WineCardRowUIModel) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(row.title)
                    .font(UVVAFont.sans(14.5, .medium))
                    .fixedSize(horizontal: false, vertical: true)
                // Lighter than the Home's caption: the wine leads, the reading follows.
                Text(row.axisText.uppercased())
                    .font(UVVAFont.sans(8, .regular))
                    .tracking(2.6)
                    .opacity(0.8)
                    .padding(.top, 10)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .light))
                .accessibilityHidden(true)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func note(_ content: some View) -> some View {
        content
            .font(UVVAFont.sans(12.5))
            .opacity(0.75)
            .padding(.horizontal, 26)
            .padding(.vertical, 16)
    }
}
