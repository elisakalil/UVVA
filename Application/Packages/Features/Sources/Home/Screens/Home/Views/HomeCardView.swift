import Core
import DesignSystem
import SwiftUI

struct HomeCardView: View {
    var resources = HomeResourcesUIModel()
    var card: HomeCardModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    var onInvite: () -> Void = {}
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }
    var onShowLess: (_ then: @escaping () -> Void) -> Void = { $0() }

    var body: some View {
        switch card {
        case .header: EmptyView() // drawn by HomeHeader, pinned above the scroll
        case let .dailySuggestion(wine):
            DailySuggestionCard(resources: resources, wine: wine, palateMap: palateMap, isInCellar: cellarWineKeys.contains(wine.id),
                                onShowLess: onShowLess)
        case let .friends(variant):
            // HOME-R11: with no friends yet, the card opens the invite.
            FriendsCard(resources: resources, variant: variant)
                .contentShape(Rectangle())
                .onTapGesture { if variant == .invite { onInvite() } }
        case let .continueLesson(course):
            ContinueLessonCard(resources: resources, course: course)
                .contentShape(Rectangle())
                .onTapGesture { onOpenCourse(course.id) }
        case let .changedMapCard(axis, delta): ChangedMapCard(resources: resources, axis: axis, delta: delta, palateMap: palateMap)
        case .learnShortcuts: LearnShortcutsCard(resources: resources, onOpen: onOpenLearn)
        case let .wordOfTheDay(term): WordOfTheDayCard(resources: resources, term: term)
        case let .winesForPalate(wines): WinesForPalateCard(resources: resources, wines: wines)
        case .chooseYourWine: ChooseYourWineCard(resources: resources)
        }
    }
}
