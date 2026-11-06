import Core
import DesignSystem
import SwiftUI

struct HomeCardView: View {
    var resources = HomeResourcesUIModel()
    var card: HomeCardModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    var onInvite: () -> Void = {}
    var onOpenLesson: (HomeLessonSuggestion) -> Void = { _ in }
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenGlossary: (GlossaryTerm) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }
    var onShowLess: (_ then: @escaping () -> Void) -> Void = { $0() }

    var body: some View {
        switch card {
        case .header: EmptyView() // drawn by HomeHeader, pinned above the scroll
        case let .dailySuggestion(wine):
            HeroCard(resources: resources, wine: wine, palateMap: palateMap, isInCellar: cellarWineKeys.contains(wine.id),
                                onShowLess: onShowLess)
        case let .friends(state):
            // HOME-R11: with no friends yet, the card opens the invite.
            FriendsCard(resources: resources, state: state)
                .contentShape(Rectangle())
                .onTapGesture { if state == .noFriends { onInvite() } }
        case let .continueLesson(course):
            ContinueLessonCard(resources: resources, course: course)
                .contentShape(Rectangle())
                .onTapGesture { onOpenCourse(course.id) }
        case let .changedMapCard(axis, delta): ChangedMapCard(resources: resources, axis: axis, delta: delta, palateMap: palateMap)
        case let .learnShortcuts(suggestions): LearnShortcutsCard(resources: resources, suggestions: suggestions, onOpen: onOpenLesson)
        case let .wordOfTheDay(term):
            Button { onOpenGlossary(term) } label: {
                WordOfTheDayCard(resources: resources, term: term)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Open glossary")
        case let .winesForPalate(wines): WinesForPalateCard(resources: resources, wines: wines)
        case .chooseYourWine: ChooseYourWineCard(resources: resources)
        }
    }
}
