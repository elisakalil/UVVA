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
    var onOpenLesson: (HomeLessonSuggestion) -> Void = { _ in }
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenGlossary: (GlossaryTerm) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }
    var onOpenWine: (WineSheetModel) -> Void = { _ in }
    var onSaveToCellar: (Wine) -> Void = { _ in }

    @State private var scroll = HeaderScrollModel()
    static let topID = "home.top"

    /// Pair adjacent small cards. A lesson keeps its half-width slot even when alone.
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
                            } else if case .continueLesson = row[0] {
                                card(row[0], proxy: proxy)
                                    .containerRelativeFrame(.horizontal) { width, _ in
                                        (width - 2 * UVVASpace.gutter - 14) / 2
                                    }
                            } else {
                                card(row[0], proxy: proxy)
                            }
                        }
                        footer
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
                        if target == HomeSpotlightID.chooseYourWine {
                            proxy.scrollTo(HomeSpotlightID.chooseYourWine, anchor: .bottom)
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

    private var footer: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(resources.homeHeaderBrand)
                    .font(UVVAFont.whiteGrape(20))
                    .tracking(0.4)
                    .foregroundStyle(UVVAColor.logoInk)
                if let version = resources.homeFooterVersion {
                    Text(version)
                        .font(UVVAFont.sans(8))
                        .tracking(1)
                }
            }
            Text(resources.homeFooterOrigin)
                .font(UVVAFont.sans(8))
                .tracking(1.8)
        }
        .foregroundStyle(UVVAColor.cream60)
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    @ViewBuilder private func card(_ card: HomeCardModel, proxy: ScrollViewProxy) -> some View {
        HomeCardView(resources: resources, card: card, palateMap: model.palateMap, cellarWineKeys: cellarWineKeys, onInvite: onInvite,
                     onOpenLesson: onOpenLesson, onOpenCourse: onOpenCourse, onOpenGlossary: onOpenGlossary, onOpenLearn: onOpenLearn,
                     onShowLess: { then in
                         withAnimation(.smooth) { proxy.scrollTo(Self.topID, anchor: .top) } completion: { then() }
                     },
                     onOpenWine: onOpenWine, onSaveToCellar: onSaveToCellar)
            .id(card.spotlightID ?? card.kind)
            .modifier(SpotlightModifier(id: card.spotlightID))
    }
}

#Preview {
    HomeContent(model: HomeContentUIModel(cards: HomeCardsBuilder().build(from: .full, now: .now), palateMap: HomeContentModel.full.palateMap),
                onInvite: {})
}
