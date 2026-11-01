import Core
import DesignSystem
import SwiftUI

struct HomeCardView: View {
    var card: HomeCardModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    var onInvite: () -> Void = {}
    var onShowLess: () -> Void = {}

    var body: some View {
        switch card {
        case .header: EmptyView() // drawn by HomeHeader, pinned above the scroll
        case let .dailySuggestion(wine):
            DailySuggestionCard(wine: wine, palateMap: palateMap, isInCellar: cellarWineKeys.contains(wine.id),
                                onShowLess: onShowLess)
        case let .friends(variant):
            // HOME-R11: with no friends yet, the card opens the invite.
            FriendsCard(variant: variant)
                .contentShape(Rectangle())
                .onTapGesture { if variant == .invite { onInvite() } }
        case let .continueLesson(course): ContinueLessonCard(course: course)
        case let .changedMapCard(axis, delta): ChangedMapCard(axis: axis, delta: delta, palateMap: palateMap)
        case .learnShortcuts: LearnShortcutsCard()
        case let .wordOfTheDay(term): WordOfTheDayCard(term: term)
        case let .winesForPalate(wines): WinesForPalateCard(wines: wines)
        case .chooseYourWine: ChooseYourWineCard()
        }
    }
}
