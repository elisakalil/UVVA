import Core
import DesignSystem
import SwiftUI

/// The cards under the floating header.
struct HomeContent: View {
    var model: HomeContentUIModel
    var resources = HomeResourcesUIModel()
    /// The area the tour points at, if any: the scroll follows it.
    var tourTarget: String?
    var cellarWineKeys: Set<String> = []
    var onInvite: () -> Void
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }

    @State private var scroll = HeaderScroll()
    static let topID = "home.top"

    /// The lesson and the map change are half-width: side by side when both show, full width when alone.
    private var rows: [[HomeCardModel]] {
        var rows: [[HomeCardModel]] = []
        for card in model.cards {
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
            PageBackground()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: UVVASpace.card) {
                        // Room for the header at full size; it floats above the cards.
                        Color.clear.frame(height: HomeHeader.fullHeight + HomeHeader.cardsGap).id(Self.topID)
                        ForEach(rows, id: \.[0].kind) { row in
                            if row.count == 2 {
                                HStack(spacing: 14) {
                                    ForEach(row, id: \.kind) { card($0, proxy: proxy) }
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            } else {
                                card(row[0], proxy: proxy)
                            }
                        }
                        Text(resources.homeContentFooter)
                            .font(UVVAFont.sans(8))
                            .tracking(1.8)
                            .foregroundStyle(UVVAColor.cream60)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, UVVASpace.gutter)
                    .padding(.bottom, 40)
                    .glassPanes()
                }
                // One still copy of the glass photo for every card; only the cards' outline follows the scroll.
                .glassBackdrop()
                .scrollIndicators(.hidden)
                .scrollDisabled(tourTarget != nil)
                // Clamped to the header's range: once it has collapsed, scrolling further reports nothing.
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    min(HomeHeader.collapseDistance, max(0, geometry.contentOffset.y + geometry.contentInsets.top))
                } action: { _, offset in
                    scroll.offset = offset
                }
                // HOME-R31: on step 2 the Home scrolls down to "Choose your wine"; otherwise it stays at the top.
                .onChange(of: tourTarget) { _, target in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        if target == HomeSpotlightModel.chooseYourWine {
                            proxy.scrollTo(HomeCardModel.chooseYourWine.kind, anchor: .bottom)
                        } else {
                            proxy.scrollTo(Self.topID, anchor: .top)
                        }
                    }
                }
            }

            if case let .header(greeting, hasUnread) = model.cards.first {
                HomeHeader(resources: resources, greeting: greeting, hasUnread: hasUnread, scroll: scroll)
            }
        }
        .foregroundStyle(UVVAColor.cream)
    }

    @ViewBuilder private func card(_ card: HomeCardModel, proxy: ScrollViewProxy) -> some View {
        HomeCardView(resources: resources, card: card, palateMap: model.palateMap, cellarWineKeys: cellarWineKeys, onInvite: onInvite,
                     onOpenCourse: onOpenCourse, onOpenLearn: onOpenLearn,
                     onShowLess: { then in
                         withAnimation(.smooth) { proxy.scrollTo(Self.topID, anchor: .top) } completion: { then() }
                     })
            .id(card.kind)
            .modifier(SpotlightModifier(id: card.spotlightID))
    }
}

#Preview {
    HomeContent(model: HomeContentUIModel(cards: HomeCardsBuilder().build(from: .full, now: .now), palateMap: HomeState.full.palateMap),
                onInvite: {})
}
