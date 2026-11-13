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
    var isRefreshingMatches = false
    var isReloading = false
    /// The reload follows a note from the Hero: the Home goes back to its top.
    var isReturningToTop = false
    var onInvite: () -> Void
    var onOpenLesson: (HomeLessonSuggestion) -> Void = { _ in }
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenGlossary: (GlossaryTerm) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }
    var onOpenWine: (WineSheetModel) -> Void = { _ in }
    var onSaveToCellar: (Wine) -> Void = { _ in }
    var onScan: () -> Void = {}
    var onOpenFriends: () -> Void = {}
    var onOpenLastTable: () -> Void = {}
    var onOpenMapHistory: () -> Void = {}

    @State private var scroll = HeaderScrollModel()
    /// The scroll back to the top, after a note from the Hero, has ended: the Hero may fold.
    @State private var reachedTop = false
    static let topID = "home.top"

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
                        Color.clear.frame(height: HomeHeader.fullHeight + HomeHeader.cardsGap).id(Self.topID)
                        ForEach(rows, id: \.[0].kind) { row in
                            if row[0].isHalfWidth {
                                HStack(spacing: 14) {
                                    ForEach(row, id: \.kind) {
                                        squareCard($0, proxy: proxy)
                                    }
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            } else {
                                card(row[0], proxy: proxy)
                            }
                        }
                        footer
                    }
                    .padding(.horizontal, UVVASpace.gutter)
                    .padding(.bottom, 40)
                    .glassPanes(rimOpacity: 0.5)
                }
                .glassBackdrop()
                .scrollIndicators(.hidden)
                .scrollDisabled(tourTarget != nil)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    min(HomeHeader.collapseDistance, max(0, geometry.contentOffset.y + geometry.contentInsets.top))
                } action: { _, offset in
                    scroll.offset = offset
                }
                // A note saved from the Hero: under the curtains, the Home goes back to its top and the Hero folds
                // there, where the new Hero comes in (HOME-R10c). Other notes leave the Home where it is.
                .onChange(of: isReturningToTop) { _, returning in
                    guard returning else { reachedTop = false; return }
                    withAnimation(.smooth(duration: 0.6)) { proxy.scrollTo(Self.topID, anchor: .top) } completion: {
                        reachedTop = true
                    }
                }
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
                HomeHeader(resources: resources, greeting: greeting, hasUnread: hasUnread, scroll: scroll,
                           onScan: onScan)
            }
        }
        .foregroundStyle(Color.white)
    }

    private func squareCard(_ model: HomeCardModel, proxy: ScrollViewProxy) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { card(model, proxy: proxy) }
            .containerRelativeFrame(.horizontal) { width, _ in
                (width - 2 * UVVASpace.gutter - 14) / 2
            }
    }

    private var footer: some View {
        let fontSize: CGFloat = 10
        return VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(resources.homeHeaderBrand)
                    .font(UVVAFont.whiteGrape(fontSize))
                    .tracking(0.4)
                if let version = resources.homeFooterVersion {
                    Text(version)
                        .font(UVVAFont.sans(fontSize))
                        .tracking(1)
                }
            }
            Text(resources.homeFooterOrigin)
                .font(UVVAFont.sans(fontSize))
                .tracking(1.8)
        }
        .foregroundStyle(Color.white.opacity(0.6))
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    @ViewBuilder private func card(_ card: HomeCardModel, proxy: ScrollViewProxy) -> some View {
        HomeCardView(resources: resources, card: card, palateMap: model.palateMap, cellarWineKeys: cellarWineKeys, isRefreshingMatches: isRefreshingMatches, isReloading: isReloading,
                     heroHoldsOpen: isReturningToTop && !reachedTop, onInvite: onInvite, onOpenFriends: onOpenFriends,
                     onOpenLastTable: onOpenLastTable, onOpenMapHistory: onOpenMapHistory,
                     onOpenLesson: onOpenLesson, onOpenCourse: onOpenCourse, onOpenGlossary: onOpenGlossary, onOpenLearn: onOpenLearn,
                     onShowLess: { then in
                         withAnimation(.smooth) { proxy.scrollTo(Self.topID, anchor: .top) } completion: { then() }
                     },
                     onOpenWine: onOpenWine, onSaveToCellar: onSaveToCellar)
            .foregroundStyle(.white)
            .id(card.spotlightID ?? card.kind)
            .modifier(SpotlightModifier(id: card.spotlightID))
    }
}

#Preview {
    HomeContent(model: HomeContentUIModel(cards: HomeCardsBuilder().build(from: .full, now: .now), palateMap: HomeContentModel.full.palateMap),
                onInvite: {})
}
