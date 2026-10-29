import SwiftUI

struct HomeView: View {
    var state: HomeState = .full

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

    var body: some View {
        ZStack(alignment: .top) {
            HomeBackground()

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

/// The vineyard photo (bg1) behind full pages, with moss while it loads.
private struct HomeBackground: View {
    var body: some View {
        UVVAColor.moss
            .overlay {
                Image("Background")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .ignoresSafeArea()
    }
}

private extension HomeCard {
    var isHalfWidth: Bool {
        switch self {
        case .continueLesson, .changedMapCard: true
        default: false
        }
    }
}

struct HomeCardView: View {
    var card: HomeCard
    var palateMap: PalateMap

    var body: some View {
        switch card {
        case .header: EmptyView() // drawn by HomeHeader, pinned above the scroll
        case let .dailySuggestion(wine): DailySuggestionCard(wine: wine, palateMap: palateMap)
        case let .friends(variant): FriendsCard(variant: variant)
        case let .continueLesson(course): ContinueLessonCard(course: course)
        case let .changedMapCard(axis, delta): ChangedMapCard(axis: axis, delta: delta, palateMap: palateMap)
        case .learnShortcuts: LearnShortcutsCard()
        case let .wordOfTheDay(term): WordOfTheDayCard(term: term)
        case let .winesForPalate(wines): WinesForPalateCard(wines: wines)
        case .chooseYourWine: ChooseYourWineCard()
        }
    }
}

#Preview {
    HomeView()
}
