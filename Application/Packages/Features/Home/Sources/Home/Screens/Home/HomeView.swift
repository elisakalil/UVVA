import Core
import DesignSystem
import SwiftUI

public struct HomeView: View {
    var state: HomeState

    /// The Home with sample data, until it reads the stores (M4).
    public init() { self.state = .full }

    init(state: HomeState) { self.state = state }

    // A random pick per render would change the word on every redraw, so the mock picks one per day.
    private let builder = HomeCardsBuilder(pickWordIndex: { count in
        (Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0) % count
    })

    @State private var scroll: CGFloat = 0

    private var cards: [HomeCard] { builder.build(from: state, now: Date()) }

    /// The lesson and the map change are half-width: side by side when both show, full width when alone.
    private var rows: [[HomeCard]] {
        var rows: [[HomeCard]] = []
        for card in cards {
            if card.isHalfWidth, let last = rows.last, last.count == 1, last[0].isHalfWidth {
                rows[rows.count - 1].append(card)
            } else {
                rows.append([card])
            }
        }
        return rows
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PageBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: UVVASpace.card) {
                    // Room for the header at full size; it floats above the cards.
                    Color.clear.frame(height: HomeHeader.fullHeight)
                    ForEach(rows, id: \.[0].kind) { row in
                        if row.count == 2 {
                            HStack(spacing: 14) {
                                ForEach(row, id: \.kind) { HomeCardView(card: $0, palateMap: state.palateMap) }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        } else {
                            HomeCardView(card: row[0], palateMap: state.palateMap)
                        }
                    }
                    Text("UVVA · 0.1 · Made in Portugal")
                        .font(UVVAFont.sans(8))
                        .tracking(1.8)
                        .foregroundStyle(UVVAColor.cream60)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
                .padding(.horizontal, UVVASpace.gutter)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
                scroll = max(0, offset)
            }

            if case let .header(greeting, hasUnread) = cards.first {
                HomeHeader(greeting: greeting, hasUnread: hasUnread, scroll: scroll)
            }
        }
        .foregroundStyle(UVVAColor.cream)
    }
}

#Preview {
    HomeView()
}
