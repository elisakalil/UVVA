import Core
import DesignSystem
import SwiftUI

struct HomeCardView: View {
    var resources = HomeResourcesUIModel()
    var card: HomeCardModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    var onInvite: () -> Void = {}
    var onOpenFriends: () -> Void = {}
    var onOpenLastTable: () -> Void = {}
    var onOpenLesson: (HomeLessonSuggestion) -> Void = { _ in }
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenGlossary: (GlossaryTerm) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }
    var onShowLess: (_ then: @escaping () -> Void) -> Void = { $0() }
    var onOpenWine: (WineSheetModel) -> Void = { _ in }
    var onSaveToCellar: (Wine) -> Void = { _ in }

    var body: some View {
        switch card {
        case .header: EmptyView() // drawn by HomeHeader, pinned above the scroll
        case let .dailySuggestion(wine):
            HeroCard(resources: resources, wine: wine, palateMap: palateMap, isInCellar: cellarWineKeys.contains(wine.id),
                    onShowLess: onShowLess, onSaveToCellar: { onSaveToCellar(wine) })
        case let .friends(state):
            // HOME-R11: no friend, the invite; one, the last table (FRI-R17); more, the Friends tab.
            FriendsCard(resources: resources, state: state)
                .contentShape(Rectangle())
                .onTapGesture {
                    switch state {
                    case .noFriends: onInvite()
                    case .hasMatch: onOpenLastTable()
                    case .hasFriends: onOpenFriends()
                    }
                }
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
        case let .winesForPalate(suggestions):
            WinesForPalateCard(resources: resources, suggestions: suggestions) { onOpenWine(.palate($0)) }
        case let .chooseYourWine(catalog):
            ChooseYourWineCard(resources: resources, palateMap: palateMap, catalog: catalog) { suggestions, direction in
                onOpenWine(.discovery(suggestions: suggestions, direction: direction))
            }
        }
    }
}
